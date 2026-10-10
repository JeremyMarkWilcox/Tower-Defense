class_name SignalThread
extends Node3D
## One glowing thread running from the Stronghold out to the map edge.
## It shows itself and reports the mouse; ThreadManager decides what a click means.
## Add it to the tree before calling setup().

signal hovered(thread: SignalThread)
signal unhovered(thread: SignalThread)
signal clicked(thread: SignalThread)

@export var line: MeshInstance3D
@export var pick_area: Area3D
@export var pick_shape: CollisionShape3D
## How far above the ground the thread floats.
@export var height := 0.3
## Width of the clickable area. Much wider than the line so it's easy to hit.
@export var pick_width := 1.2
## Line thickness multiplier while highlighted.
@export var highlight_width := 2.5

var data: SignalThreadData
var direction := Vector3.FORWARD
var length := 0.0

var _color := Color.WHITE
var _material: StandardMaterial3D
var _is_highlighted := false


func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line.material_override = _material
	pick_area.input_ray_pickable = true
	pick_area.mouse_entered.connect(func() -> void: hovered.emit(self))
	pick_area.mouse_exited.connect(func() -> void: unhovered.emit(self))
	pick_area.input_event.connect(_on_pick_input_event)


func setup(thread_data: SignalThreadData, thread_direction: Vector3, thread_length: float, color: Color) -> void:
	data = thread_data
	direction = Vector3(thread_direction.x, 0.0, thread_direction.z).normalized()
	length = thread_length
	_color = color
	# Local -Z points along the thread, so the line runs from 0 to -length.
	basis = Basis.looking_at(direction, Vector3.UP)
	line.position = Vector3(0.0, height, -length * 0.5)
	pick_shape.position = line.position
	(pick_shape.shape as BoxShape3D).size = Vector3(pick_width, 1.0, length)
	_apply_look()


func set_highlighted(value: bool) -> void:
	_is_highlighted = value
	_apply_look()


## Where the thread leaves the map; its group spawns here.
func get_end_position() -> Vector3:
	return global_position + direction * length


func _apply_look() -> void:
	var width := highlight_width if _is_highlighted else 1.0
	line.scale = Vector3(width, width, length)
	_material.albedo_color = _color.lerp(Color.WHITE, 0.35) if _is_highlighted else _color


func _on_pick_input_event(_camera: Node, event: InputEvent, _position: Vector3,
		_normal: Vector3, _shape_index: int) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)
