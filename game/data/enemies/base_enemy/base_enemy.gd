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


func _ready() -> void:
	add_to_group("enemies")
	if ward_effect:
		ward_effect.visible = false


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
	match state:
		State.MOVING:
			_move(delta)
		State.ATTACKING:
			_attack(delta)


func take_damage(amount: int) -> void:
	if _is_dead or amount <= 0:
		return
	health -= maxi(1, roundi(amount * damage_taken_multiplier))
	if health <= 0:
		_is_dead = true
		died.emit(self)
		queue_free()


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
		arrived.emit(self)
		return
	var direction := to_target / distance
	global_position += direction * data.move_speed * speed_multiplier * delta
	_face(direction)


func _attack(delta: float) -> void:
	if data.stronghold_damage <= 0:
		return  # e.g. cultists: they hold position and channel instead
	_attack_cooldown -= delta
	if _attack_cooldown <= 0.0:
		_attack_cooldown += data.attack_interval
		attacked.emit(self, roundi(data.stronghold_damage * damage_multiplier))


func _update_ward_look() -> void:
	if ward_effect:
		ward_effect.visible = is_warded()


func _face(direction: Vector3) -> void:
	direction.y = 0.0
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP, true)
