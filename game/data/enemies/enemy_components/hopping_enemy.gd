class_name HoppingEnemy
extends BaseEnemy
## Moves only while airborne, synced to its hop animation. At the Stronghold it sits still,
## then attacks with one big leap that deals damage when it lands.

@export_group("Hop")
## Fraction of the hop animation (0-1) where the feet leave the ground and land again.
@export_range(0.0, 1.0, 0.01) var takeoff := 0.30
@export_range(0.0, 1.0, 0.01) var landing := 0.78
## Optional: dust or thump spawned every time it lands while travelling.
@export var landing_effect: PackedScene

@export_group("Slam Attack")
## The model node, lifted higher during a slam (e.g. FrogMesh).
@export var model: Node3D
## Extra height added on top of the animation's own hop during a slam.
@export var slam_extra_height := 2.5
## Spawned where the slam lands.
@export var slam_effect: PackedScene

var _last_phase := 0.0
var _slamming := false
var _model_rest_y := 0.0


func _ready() -> void:
	super()
	if model:
		_model_rest_y = model.position.y


func _physics_process(delta: float) -> void:
	super(delta)  # BaseEnemy runs _move/_attack and status effects
	if _is_dead or data == null:
		return
	_update_hop()


## Replaces BaseEnemy's movement: travel only while airborne.
func _move(delta: float) -> void:
	var to_target := _target - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	if distance <= _stop_distance:
		if not _is_airborne():
			_arrive()  # wait for the feet to touch down before stopping
		return
	var direction := to_target / distance
	_face(direction)
	if _is_airborne():
		# Move faster while in the air so the average speed still matches move_speed.
		var air_fraction := maxf(landing - takeoff, 0.05)
		global_position += direction * data.move_speed * speed_multiplier / air_fraction * delta


## Replaces BaseEnemy's attack: sit, then leap. Damage happens on landing (in _update_hop).
func _attack(delta: float) -> void:
	if data.stronghold_damage <= 0 or _slamming:
		return
		_attack_cooldown -= delta * speed_multiplier
	if _attack_cooldown <= 0.0:
		_attack_cooldown = data.attack_interval
		_slamming = true
		if anim_player:
			anim_player.seek(0.0, true)
			anim_player.play()


func _arrive() -> void:
	state = State.ATTACKING
	_hold_ground_pose()
	arrived.emit(self)


func _update_hop() -> void:
	var phase := _hop_phase()
	var landed := _crossed(_last_phase, phase, landing)
	_last_phase = phase

	# Extra lift during a slam, peaking mid-air.
	if model:
		var lift := 0.0
		if _slamming and _is_airborne():
			var air_t := (phase - takeoff) / maxf(landing - takeoff, 0.05)
			lift = sin(air_t * PI) * slam_extra_height
		model.position.y = _model_rest_y + lift

	if not landed:
		return
	if state == State.MOVING:
		_spawn(landing_effect)
	elif _slamming:
		_slamming = false
		attacked.emit(self, roundi(data.stronghold_damage * damage_multiplier))
		_spawn(slam_effect)
		_hold_ground_pose()


## 0-1 through the current hop loop.
func _hop_phase() -> float:
	if anim_player == null or anim_player.current_animation_length <= 0.0:
		return 0.0
	return fposmod(anim_player.current_animation_position / anim_player.current_animation_length, 1.0)


func _is_airborne() -> bool:
	var phase := _hop_phase()
	return phase > takeoff and phase < landing


## Freezes the animation at its first frame (crouched, on the ground) between slams.
func _hold_ground_pose() -> void:
	if anim_player:
		anim_player.seek(0.0, true)
		anim_player.pause()
	_last_phase = 0.0


## True if `mark` was passed going from `before` to `now`, including a wrap past 1 -> 0.
func _crossed(before: float, now: float, mark: float) -> bool:
	if now >= before:
		return before < mark and mark <= now
	return before < mark or mark <= now


func _spawn(scene: PackedScene) -> void:
	if scene == null:
		return
	var effect := scene.instantiate() as Node3D
	get_tree().current_scene.add_child(effect)
	effect.global_position = global_position
