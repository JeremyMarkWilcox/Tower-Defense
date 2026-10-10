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
## Color the thread flashes when a cut is refused.
@export var refusal_color := Color(1.0, 0.15, 0.1)

var data: SignalThreadData
var direction := Vector3.FORWARD
var length := 0.0

var _color := Color.WHITE
var _material: StandardMaterial3D
var _is_highlighted := false
var _urgency := 0.0
var _pulse_time := 0.0
var _flash := 0.0
var _shake_tween: Tween


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
	line.position = _rest_position()
	pick_shape.position = line.position
	(pick_shape.shape as BoxShape3D).size = Vector3(pick_width, 1.0, length)
	_apply_look()


func set_highlighted(value: bool) -> void:
	_is_highlighted = value
	_apply_look()


## 0 at the start of the lull, 1 when the timer hits zero. Drives the pulse.
func set_urgency(value: float) -> void:
	_urgency = clampf(value, 0.0, 1.0)


## Snap-back wiggle and red flash. Strong for the boss, light for the cooldown.
func play_refusal(strong: bool) -> void:
	if _shake_tween:
		_shake_tween.kill()
	var rest := _rest_position()
	var amount := 0.4 if strong else 0.12
	_shake_tween = create_tween()
	_shake_tween.tween_method(_set_flash, 1.0 if strong else 0.5, 1.0 if strong else 0.5, 0.0)
	for i in (6 if strong else 3):
		var side := amount if i % 2 == 0 else -amount
		_shake_tween.tween_property(line, "position", rest + Vector3(side, 0.0, 0.0), 0.04)
		amount *= 0.7
	_shake_tween.tween_property(line, "position", rest, 0.05)
	_shake_tween.tween_method(_set_flash, _flash, 0.0, 0.25)


## Where the thread leaves the map; its group spawns here.
func get_end_position() -> Vector3:
	return global_position + direction * length


func _process(delta: float) -> void:
	# Pulses slowly at the start of a lull and fast near the end.
	_pulse_time += delta * lerpf(0.6, 4.0, _urgency)
	_apply_look()


func _rest_position() -> Vector3:
	return Vector3(0.0, height, -length * 0.5)


func _set_flash(value: float) -> void:
	_flash = value


func _apply_look() -> void:
	var pulse := 0.5 + 0.5 * sin(_pulse_time * TAU)
	var width := highlight_width if _is_highlighted else 1.0
	width *= 1.0 + 0.5 * _urgency * pulse
	line.scale = Vector3(width, width, length)
	var color := _color.lerp(Color.WHITE, 0.35) if _is_highlighted else _color
	color = color.lerp(Color.WHITE, 0.3 * _urgency * pulse)
	_material.albedo_color = color.lerp(refusal_color, _flash)


func _on_pick_input_event(_camera: Node, event: InputEvent, _position: Vector3,
		_normal: Vector3, _shape_index: int) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)
