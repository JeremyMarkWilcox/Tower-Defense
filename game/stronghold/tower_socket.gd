class_name TowerSocket
extends Node3D
## One build spot on the Stronghold. Reports clicks; the Stronghold and shop decide what happens.

signal clicked(socket: TowerSocket)

@export var build_point: Marker3D
@export var click_area: Area3D
## Optional: shown while the mouse is over this socket (e.g. a glowing ring).
@export var hover_visual: Node3D

var tower: Node3D  # the tower built here, or null
var tower_type := -1
var tower_level := -1


func _ready() -> void:
	click_area.input_ray_pickable = true
	click_area.mouse_entered.connect(_set_hover.bind(true))
	click_area.mouse_exited.connect(_set_hover.bind(false))
	click_area.input_event.connect(_on_input_event)
	_set_hover(false)


func is_empty() -> bool:
	return tower == null


func _set_hover(value: bool) -> void:
	if hover_visual:
		hover_visual.visible = value


func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3,
		_normal: Vector3, _shape_idx: int) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)
