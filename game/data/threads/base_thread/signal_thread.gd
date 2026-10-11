class_name SignalThread
extends Node3D
## One swaying rope running from the Stronghold out to the screen edge.
## It shows itself and reports the mouse; ThreadManager decides what a click means.
## Add it to the tree before calling setup().

signal hovered(thread: SignalThread)
signal unhovered(thread: SignalThread)
signal clicked(thread: SignalThread)

@export var line: MeshInstance3D
@export var pick_area: Area3D
@export var pick_shape: CollisionShape3D
@export var rope_shader: Shader
## How far above the ground the rope floats.
@export var height := 0.3
## Width of the clickable area. Much wider than the rope so it's easy to hit.
@export var pick_width := 1.2
@export var thickness := 0.06
@export var highlight_thickness := 0.14
## Color the rope flashes when a cut is refused.
@export var refusal_color := Color(1.0, 0.15, 0.1)

@export_group("Rope Shape")
## How far the rope wanders sideways at its widest. Keep it under half of Pick Width.
@export var wander := 0.5
## How far it sways while alive.
@export var sway := 0.12
@export var segments := 64
@export var radial_sides := 6

var data: SignalThreadData
var direction := Vector3.FORWARD
var length := 0.0

var _color := Color.WHITE
var _material: ShaderMaterial
var _is_highlighted := false
var _urgency := 0.0
var _pulse_time := 0.0
var _sway_phase := 0.0
var _flash := 0.0
var _shake_tween: Tween


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = rope_shader
	line.material_override = _material
	line.extra_cull_margin = 2.0  # the shader moves vertices, so don't cull too early
	pick_area.input_ray_pickable = true
	pick_area.mouse_entered.connect(func() -> void: hovered.emit(self))
	pick_area.mouse_exited.connect(func() -> void: unhovered.emit(self))
	pick_area.input_event.connect(_on_pick_input_event)


func setup(thread_data: SignalThreadData, thread_direction: Vector3, thread_length: float, color: Color) -> void:
	data = thread_data
	direction = Vector3(thread_direction.x, 0.0, thread_direction.z).normalized()
	length = thread_length
	_color = color
	# Local -Z points along the thread, so the rope runs from 0 to -length.
	basis = Basis.looking_at(direction, Vector3.UP)
	line.mesh = _build_rope_mesh()
	line.position = _rest_position()
	line.scale = Vector3.ONE
	pick_shape.position = Vector3(0.0, height, -length * 0.5)
	(pick_shape.shape as BoxShape3D).size = Vector3(pick_width, 1.0, length)
	_material.set_shader_parameter("seed", randf() * 100.0)
	_apply_look()


func set_highlighted(value: bool) -> void:
	_is_highlighted = value
	_apply_look()


## 0 at the start of the lull, 1 when the timer hits zero. Drives the pulse and sway.
func set_urgency(value: float) -> void:
	_urgency = clampf(value, 0.0, 1.0)


## Snap-back wiggle and red flash. Strong for the boss, light for the cooldown.
func play_refusal(strong: bool) -> void:
	if _shake_tween:
		_shake_tween.kill()
	var rest := _rest_position()
	var amount := 0.4 if strong else 0.12
	_flash = 1.0 if strong else 0.5
	_shake_tween = create_tween()
	for i in (6 if strong else 3):
		var side := amount if i % 2 == 0 else -amount
		_shake_tween.tween_property(line, "position", rest + Vector3(side, 0.0, 0.0), 0.04)
		amount *= 0.7
	_shake_tween.tween_property(line, "position", rest, 0.05)
	_shake_tween.tween_method(_set_flash, _flash, 0.0, 0.25)


## Where the thread meets the screen edge; its group spawns here.
func get_end_position() -> Vector3:
	return global_position + direction * length


func _process(delta: float) -> void:
	# Breathes slowly at the start of a lull and gets twitchy near the end.
	_pulse_time += delta * lerpf(0.6, 4.0, _urgency)
	_sway_phase += delta * lerpf(1.0, 6.0, _urgency)
	_material.set_shader_parameter("phase", _sway_phase)
	_material.set_shader_parameter("sway", sway * lerpf(1.0, 1.8, _urgency))
	_apply_look()


func _rest_position() -> Vector3:
	return Vector3(0.0, height, 0.0)


func _set_flash(value: float) -> void:
	_flash = value


func _apply_look() -> void:
	var pulse := 0.5 + 0.5 * sin(_pulse_time * TAU)
	var width := highlight_thickness if _is_highlighted else thickness
	width *= 1.0 + 0.5 * _urgency * pulse
	var color := _color.lerp(Color.WHITE, 0.35) if _is_highlighted else _color
	color = color.lerp(Color.WHITE, 0.3 * _urgency * pulse)
	_material.set_shader_parameter("thickness", width)
	_material.set_shader_parameter("color", color.lerp(refusal_color, _flash))


## A thin tube along a lazily wandering path. Vertices sit on the centerline and
## the shader pushes them out along NORMAL, so thickness can change without rebuilding.
func _build_rope_mesh() -> ArrayMesh:
	var phase_a := randf() * TAU
	var phase_b := randf() * TAU
	var phase_c := randf() * TAU
	var curves := maxf(length / 6.0, 1.0)  # longer ropes get more bends
	var points: Array[Vector3] = []
	for i in segments + 1:
		var t := float(i) / segments
		var pinned := sin(PI * t)  # both ends stay exactly in place
		var x := (sin(t * curves * PI + phase_a) * 0.7 + sin(t * curves * 3.4 + phase_b) * 0.3) * wander * pinned
		var y := sin(t * curves * 1.8 + phase_c) * wander * 0.25 * pinned
		points.append(Vector3(x, y, -length * t))

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring := radial_sides + 1
	for i in points.size():
		var tangent := (points[mini(i + 1, segments)] - points[maxi(i - 1, 0)]).normalized()
		var side := tangent.cross(Vector3.UP).normalized()
		var up := side.cross(tangent).normalized()
		for s in ring:
			var angle := TAU * s / radial_sides
			st.set_normal(side * cos(angle) + up * sin(angle))
			st.set_uv(Vector2(float(i) / segments, float(s) / radial_sides))
			st.add_vertex(points[i])
	for i in segments:
		for s in radial_sides:
			var a := i * ring + s
			var b := a + 1
			var c := a + ring
			var d := c + 1
			st.add_index(a)
			st.add_index(c)
			st.add_index(b)
			st.add_index(b)
			st.add_index(c)
			st.add_index(d)
	return st.commit()


func _on_pick_input_event(_camera: Node, event: InputEvent, _position: Vector3,
		_normal: Vector3, _shape_index: int) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)
