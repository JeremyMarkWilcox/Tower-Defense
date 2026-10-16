class_name BaseEnemy
extends Node3D
## Walks straight toward the Stronghold, stops within attack range and attacks
## on a timer until killed. Reports its death once, then frees itself.
## Needs a direct child Area3D hitbox on the enemies physics layer.

signal died(enemy: BaseEnemy)
signal attacked(enemy: BaseEnemy, damage: int)
## Emitted once, when the enemy stops at its attack range.
signal arrived(enemy: BaseEnemy)

enum State { MOVING, ATTACKING }

## Optional: shown while a ward protects this enemy (e.g. a faint purple shell).
@export var ward_effect: Node3D
## Optional: the model's AnimationPlayer. Its playback speed follows speed_multiplier.
@export var anim_player: AnimationPlayer
## Base playback speed for this enemy's animation. 1 = as authored.
@export_range(0.1, 5.0, 0.05) var anim_speed := 1.0
## Optional: animation to play once this enemy reaches the Stronghold. Leave empty to keep walking.
@export var attack_animation: StringName
## Spawned where the enemy dies. Set once in base_enemy.tscn; override per enemy if needed.
@export var death_effect: PackedScene
## Lifts the effect off the ground to roughly the middle of the body.
@export var death_effect_height := 0.8
## Tint over the whole model while slowed.
@export var frost_tint := Color(0.45, 0.75, 1.0, 0.45)
## Brief flash on each burn tick.
@export var burn_flash := Color(1.0, 0.3, 0.1, 0.6)

var data: EnemyData
var health := 0
var state := State.MOVING
## Changed by buffs and status effects. 1 = normal.
var speed_multiplier := 1.0
var damage_multiplier := 1.0
## Incoming damage is multiplied by this. Wards lower it; they don't stack.
var damage_taken_multiplier := 1.0

var _target := Vector3.ZERO
var _stop_distance := 0.0
var _attack_cooldown := 0.0
var _is_dead := false
var _ward_sources: Array[Node] = []

var burnTimer : float
var burnTick : float
var burnDamage : float
var freezeTimer : float

var _meshes: Array[MeshInstance3D] = []
var _frost_overlay: StandardMaterial3D
var _flash_overlay: StandardMaterial3D
var _current_overlay: Material
var _flash_time := 0.0


func _ready() -> void:
	add_to_group(&"enemies")  # so Ice 2 can find nearby enemies
	if ward_effect:
		ward_effect.visible = false
		for node in find_children("*", "MeshInstance3D", true, false):
			if node == ward_effect or _is_in_ward_aura(node):
				continue  # ward visuals keep their own look
			_meshes.append(node)
	_frost_overlay = _make_overlay(frost_tint)
	_flash_overlay = _make_overlay(burn_flash)


func _is_in_ward_aura(node: Node) -> bool:
	var parent := node.get_parent()
	while parent and parent != self:
		if parent is WardAura:
			return true
		parent = parent.get_parent()
	return false
	

## Called by WaveManager right after spawning.
func setup(enemy_data: EnemyData, target: Vector3, stronghold_radius: float) -> void:
	data = enemy_data
	health = data.max_health
	_target = target
	# A little jitter so a group from one thread doesn't stop in a single stack.
	_stop_distance = stronghold_radius + data.attack_range + randf_range(0.0, 0.6)
	_attack_cooldown = data.attack_interval
	_face(_target - global_position)


func _physics_process(delta: float) -> void:
	if _is_dead or data == null:
		return
	if anim_player:
		anim_player.speed_scale = anim_speed * speed_multiplier
	match state:
		State.MOVING:
			_move(delta)
		State.ATTACKING:
			_attack(delta)
	#status effects
	freezeTimer -= delta
	if freezeTimer < 0.0:
		speed_multiplier = 1.0
	if burnTimer > 0.0:
		burnTimer -= delta
		burnTick -= delta
		if burnTick <= 0.0:
			burnTick += 0.5
			_flash_time = 0.12
			take_damage(roundi(burnDamage))
	_update_status_look(delta)

func take_damage(amount: int) -> void:
	if _is_dead or amount <= 0:
		return
	health -= maxi(1, roundi(amount * damage_taken_multiplier))
	if health <= 0:
		_is_dead = true
		_spawn_death_effect()
		died.emit(self)
		queue_free()
		

## Slows don't stack: the strongest active slow wins, and a new hit refreshes the duration.
func slow(time: float, percent: float) -> void:
	freezeTimer = maxf(freezeTimer, time)
	speed_multiplier = minf(speed_multiplier, 1.0 - clampf(percent, 0.0, 0.9))
	#apply freeze particles
	
## Burns don't stack: a new hit refreshes the duration and keeps the higher damage.
func burn(time: float, damage: float) -> void:
	if data and data.burn_immune:
		return  # demons can't be burned
	if burnTimer <= 0.0:
		burnTick = 0.5  # first tick half a second after catching fire
		burnDamage = damage
	else:
		burnDamage = maxf(burnDamage, damage)
	burnTimer = maxf(burnTimer, time)


func _spawn_death_effect() -> void:
	if death_effect == null:
		return
	var effect := death_effect.instantiate() as Node3D
	get_tree().current_scene.add_child(effect)  # outlives the enemy, cleaned up on restart
	effect.global_position = global_position + Vector3.UP * death_effect_height


func is_warded() -> bool:
	return not _ward_sources.is_empty()


## Called by a WardAura when this enemy enters its range.
func add_ward(source: Node, damage_taken: float) -> void:
	if _is_dead or source in _ward_sources:
		return
	_ward_sources.append(source)
	damage_taken_multiplier = damage_taken
	_update_ward_look()


## Called by a WardAura when this enemy leaves its range or the ward ends.
func remove_ward(source: Node) -> void:
	_ward_sources.erase(source)
	if _ward_sources.is_empty():
		damage_taken_multiplier = 1.0
	_update_ward_look()


func _move(delta: float) -> void:
	var to_target := _target - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	if distance <= _stop_distance:
		state = State.ATTACKING
		_play_attack_animation()
		arrived.emit(self)
		return
	var direction := to_target / distance
	global_position += direction * data.move_speed * speed_multiplier * delta
	_face(direction)


func _attack(delta: float) -> void:
	if data.stronghold_damage <= 0:
		return  # e.g. cultists: they hold position and channel instead
	_attack_cooldown -= delta * speed_multiplier
	if _attack_cooldown <= 0.0:
		_attack_cooldown += data.attack_interval
		attacked.emit(self, roundi(data.stronghold_damage * damage_multiplier))


func _play_attack_animation() -> void:
	if anim_player and attack_animation != &"" and anim_player.has_animation(attack_animation):
		anim_player.play(attack_animation, 0.15)  # 0.15s blend so the arms raise instead of snapping


func _update_ward_look() -> void:
	if ward_effect:
		ward_effect.visible = is_warded()


func _face(direction: Vector3) -> void:
	direction.y = 0.0
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP, true)
		

## Red flash wins briefly, otherwise blue while slowed, otherwise no overlay.
func _update_status_look(delta: float) -> void:
	_flash_time = maxf(_flash_time - delta, 0.0)
	var overlay: Material = null
	if _flash_time > 0.0:
		overlay = _flash_overlay
	elif freezeTimer > 0.0:
		overlay = _frost_overlay
	if overlay == _current_overlay:
		return  # only touch the meshes when the look actually changes
	_current_overlay = overlay
	for mesh in _meshes:
		mesh.material_overlay = overlay


func _make_overlay(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	return mat
