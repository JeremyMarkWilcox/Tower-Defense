class_name FloatBob
extends Node3D
## Cosmetic only: makes a model hover and drift slightly. Put it on the model child,
## never the enemy root, so the hitbox and movement stay exactly where they are.

## How far it rises and falls.
@export var bob_height := 0.15
## Bobs per second.
@export var bob_speed := 1.2
## How far it drifts side to side. Keep it small so the model stays on its hitbox.
@export var drift := 0.06
@export var drift_speed := 0.5

var _rest := Vector3.ZERO
var _phase := 0.0


func _ready() -> void:
	_rest = position
	_phase = randf() * TAU  # so a group doesn't bob in sync


func _process(delta: float) -> void:
	_phase += delta
	position = _rest + Vector3(
		sin(_phase * drift_speed * TAU) * drift,
		sin(_phase * bob_speed * TAU) * bob_height,
		0.0)
