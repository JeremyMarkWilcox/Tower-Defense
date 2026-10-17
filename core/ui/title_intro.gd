class_name TitleIntro
extends Node3D
## Title backdrop: a signal pulses out of the Stronghold, threads light up one by one,
## enemies rise at their ends, then the camera orbits slowly behind the menu.
## Any key or click skips to the orbit. play_transition() swoops toward the gameplay view.

signal finished

enum Phase { INTRO, IDLE, LEAVING }

@export var camera: Camera3D
@export var stronghold: Node3D
@export var thread_scene: PackedScene
## One thread per entry, revealed in this order. Put the boss last.
@export var thread_enemies: Array[EnemyData] = []
## Flat ring with radius 1. It expands out from the Stronghold.
@export var pulse_ring: MeshInstance3D

@export_group("Camera Shots")
@export var shot_start: Marker3D
@export var shot_reveal: Marker3D
@export var shot_gameplay: Marker3D

@export_group("Tuning")
@export var thread_length := 16.0
## How far from the Stronghold's center the threads begin.
@export var start_offset := 2.0
@export var pulse_time := 2.0
@export var rise_time := 0.6
## Radians per second.
@export var orbit_speed := 0.06
@export var swoop_time := 1.2
@export var fade: ColorRect

@export_group("Sounds")
@export var pulse_sound: AudioStream
@export var pulse_volume_db := 0.0
@export var thread_sound: AudioStream
@export var thread_volume_db := -4.0
## Each thread plays this much higher than the one before (0.08 = 8% higher).
@export var thread_pitch_step := 0.08

var phase := Phase.INTRO

var _intro: Tween
var _threads: Array[SignalThread] = []
var _risers: Array[Node3D] = []
var _rise_targets: Array[Vector3] = []
var _orbit_angle := 0.0


func _ready() -> void:
	camera.current = true
	camera.global_transform = shot_start.global_transform
	pulse_ring.scale = Vector3(0.01, 1.0, 0.01)  # drawn but too small to see, so its shader compiles now
	_build_threads()
	_play_intro()


func _process(delta: float) -> void:
	if phase != Phase.IDLE:
		return
	_orbit_angle += orbit_speed * delta
	camera.global_transform = _orbit_transform(_orbit_angle)


func _input(event: InputEvent) -> void:
	if phase != Phase.INTRO or not _is_skip(event):
		return
	get_viewport().set_input_as_handled()
	if _intro and _intro.is_running():
		_intro.custom_step(1000.0)  # jumps to the final frame; runs the remaining callbacks


## Called by the title when Play is pressed. Await it, then change scenes.
func play_transition() -> void:
	phase = Phase.LEAVING
	var from := camera.global_transform
	var tween := create_tween().set_parallel(true)
	for thread in _threads:
		tween.tween_property(thread, "scale:z", 0.001, 0.4)
	tween.tween_method(_move_camera.bind(from, shot_gameplay.global_transform), 0.0, 1.0, swoop_time) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func _build_threads() -> void:
	var center := stronghold.global_position
	var count := thread_enemies.size()
	var offset := randf() * TAU
	for i in count:
		var angle := offset + i * TAU / count
		var direction := Vector3(sin(angle), 0.0, cos(angle))
		var enemy_data := thread_enemies[i]

		var thread := thread_scene.instantiate() as SignalThread
		add_child(thread)
		thread.global_position = center + direction * start_offset
		thread.setup(null, direction, thread_length, enemy_data.thread_color)
		thread.set_urgency(0.25)  # a faint idle pulse
		var end := thread.get_end_position()  # read before collapsing it
		thread.scale = Vector3.ONE * 0.001  # drawn (shader compiles) but invisible)
		_threads.append(thread)

		# The enemy waits underground at the thread's end.
		var enemy := enemy_data.scene.instantiate() as Node3D
		add_child(enemy)
		enemy.global_position = end + Vector3.DOWN * 6
		enemy.look_at(Vector3(center.x, enemy.global_position.y, center.z), Vector3.UP, true)
		_risers.append(enemy)
		_rise_targets.append(end)


func _play_intro() -> void:
	var ring_size := thread_length + start_offset
	_intro = create_tween()
	# Beat 1: a moment of darkness, then the pulse.
	_intro.tween_interval(1.2)
	_intro.tween_callback(pulse_ring.show)
	_intro.tween_callback(Audio.play_sfx.bind(pulse_sound, 0.0, pulse_volume_db))
	# Beat 2: the camera rises while the pulse spreads.
	_intro.set_parallel(true)
	if fade:
		_intro.tween_property(fade, "modulate:a", 0.0, pulse_time * 1.2).from(1.0)
	_intro.tween_method(_move_camera.bind(shot_start.global_transform, shot_reveal.global_transform),
			0.0, 1.0, pulse_time + 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_intro.tween_property(pulse_ring, "scale", Vector3(ring_size, 1.0, ring_size), pulse_time) \
			.from(Vector3(0.01, 1.0, 0.01))
	_intro.tween_property((pulse_ring.mesh as PrimitiveMesh).material, "albedo_color:a", 0.0, pulse_time).from(1.0)
	# Threads light up one by one as the pulse passes (Beat 2); enemies rise at their ends (Beat 3).
	for i in _threads.size():
		var delay := pulse_time * 0.6 + i * 0.25
		_intro.tween_callback(_threads[i].show).set_delay(delay)
		_intro.tween_callback(Audio.play_sfx.bind(thread_sound, 0.0, thread_volume_db, 1.0 + i * thread_pitch_step)).set_delay(delay)
		_intro.tween_property(_threads[i], "scale", Vector3.ONE, 0.35).set_delay(delay)
		_intro.tween_property(_risers[i], "global_position", _rise_targets[i], rise_time) \
				.set_delay(delay + 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_intro.chain().tween_callback(_finish_intro)


func _finish_intro() -> void:
	pulse_ring.hide()
	_orbit_angle = 0.0
	phase = Phase.IDLE
	finished.emit()


func _move_camera(t: float, from: Transform3D, to: Transform3D) -> void:
	camera.global_transform = from.interpolate_with(to, t)


## ShotReveal turned around the vertical axis through the Stronghold, so the orbit starts with no jump.
func _orbit_transform(angle: float) -> Transform3D:
	var center := stronghold.global_position
	var pivot := Transform3D(Basis(Vector3.UP, angle), center) * Transform3D(Basis.IDENTITY, -center)
	return pivot * shot_reveal.global_transform


func _is_skip(event: InputEvent) -> bool:
	var is_button := event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton
	return is_button and event.is_pressed() and not event.is_echo()
