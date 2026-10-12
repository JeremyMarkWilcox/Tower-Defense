class_name WalkWobble
extends Node3D

@export_group("Walk")
@export var steps_per_unit := 0.7
@export var max_steps_per_second := 1.5
@export var step_height := 0.12
@export var sway_degrees := 15.0
@export var lean_degrees := 8.0
@export var settle_speed := 6.0
@export var stop_delay := 0.15

@export_group("Strike")
@export var strike_enabled := true
@export var strike_duration := 0.45
@export var windup_degrees := 20.0
@export var strike_degrees := 35.0
@export var lunge_distance := 0.15

var _rest_position: Vector3
var _rest_rotation: Vector3
var _phase := 0.0
var _walk_amount := 0.0
var _still_time := 0.0
var _last_parent_position: Vector3
var _strike_time := -1.0


func _ready() -> void:
	_rest_position = position
	_rest_rotation = rotation
	_phase = randf() * TAU
	_last_parent_position = get_parent_node_3d().global_position

	var enemy: BaseEnemy = get_parent() as BaseEnemy
	if enemy != null and strike_enabled:
		enemy.attacked.connect(_on_attacked)


func _process(delta: float) -> void:
	var parent_position: Vector3 = get_parent_node_3d().global_position
	var moved: float = parent_position.distance_to(_last_parent_position)
	_last_parent_position = parent_position

	if moved > 1.0:
		moved = 0.0

	if moved > 0.0001:
		_still_time = 0.0
		var step: float = moved * steps_per_unit * PI
		var max_step: float = max_steps_per_second * PI * delta
		_phase += minf(step, max_step)
	else:
		_still_time += delta

	var target: float = 1.0 if _still_time < stop_delay else 0.0
	_walk_amount = move_toward(_walk_amount, target, settle_speed * delta)

	var bounce: float = absf(sin(_phase)) * step_height * _walk_amount
	var sway: float = sin(_phase) * deg_to_rad(sway_degrees) * _walk_amount
	var lean: float = deg_to_rad(lean_degrees) * _walk_amount

	var strike_pitch: float = 0.0
	var lunge: float = 0.0
	if _strike_time >= 0.0:
		_strike_time += delta
		var t: float = _strike_time / strike_duration
		if t >= 1.0:
			_strike_time = -1.0
		else:
			strike_pitch = _strike_curve(t)
			lunge = maxf(strike_pitch, 0.0) / strike_degrees * lunge_distance

	position = _rest_position + Vector3(0.0, bounce, lunge)
	rotation = _rest_rotation + Vector3(lean + deg_to_rad(strike_pitch), 0.0, sway)


func _strike_curve(t: float) -> float:
	if t < 0.45:
		return -windup_degrees * sin(t / 0.45 * PI * 0.5)
	if t < 0.6:
		return lerpf(-windup_degrees, strike_degrees, (t - 0.45) / 0.15)
	return lerpf(strike_degrees, 0.0, smoothstep(0.6, 1.0, t))


func _on_attacked(_enemy: BaseEnemy, _damage: Variant) -> void:
	_strike_time = 0.0
