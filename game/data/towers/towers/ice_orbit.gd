class_name IceOrbit
extends Node3D
## Spins its child shards around the tower and bobs them up and down.

@export var spin_speed: float = 60.0  # degrees per second
@export var bob_height: float = 0.15
@export var bob_speed: float = 2.0

var _angle: float = 0.0
var _time: float = 0.0
var _shards: Array[Node3D] = []
var _base_y: Array[float] = []


func _ready() -> void:
	for child in get_children():
		if child is Node3D:
			_shards.append(child)
			_base_y.append(child.position.y)


func _process(delta: float) -> void:
	_angle += deg_to_rad(spin_speed) * delta
	_time += delta
	# Set the global rotation so the orbit ignores the tower turning to aim
	global_rotation = Vector3(0.0, _angle, 0.0)
	var count := _shards.size()
	for i in count:
		var phase := float(i) / count * TAU
		_shards[i].position.y = _base_y[i] + sin(_time * bob_speed + phase) * bob_height
