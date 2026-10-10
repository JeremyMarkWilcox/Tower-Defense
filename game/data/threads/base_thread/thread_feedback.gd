class_name ThreadFeedback
extends Node
## Presentation only: answers ThreadManager's refusals with a thread snap-back,
## sound, a screen pulse and a small camera shake. It decides nothing.

@export var thread_manager: ThreadManager
@export var camera: Camera3D
## Full-screen ColorRect used for the red pulse.
@export var pulse_rect: ColorRect
## The boss growl.
@export var refusal_sound: AudioStream
## A lighter "not yet" sound for the cooldown.
@export var cooldown_sound: AudioStream
@export var pulse_color := Color(0.6, 0.0, 0.05, 0.35)
@export var shake_strength := 0.25

var _pulse_tween: Tween
var _camera_tween: Tween


func _ready() -> void:
	pulse_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # never block clicks
	pulse_rect.color = Color(pulse_color, 0.0)
	thread_manager.cut_refused.connect(_on_cut_refused)


func _on_cut_refused(thread: SignalThread, reason: StringName) -> void:
	var strong := reason == ThreadManager.REFUSED_UNCUTTABLE
	thread.play_refusal(strong)
	var sound := refusal_sound if strong else cooldown_sound
	if sound:
		Audio.play_sfx(sound, 0.1)
	if strong:
		_pulse_screen()
		_shake_camera()


func _pulse_screen() -> void:
	if not Settings.flashing:
		return
	if _pulse_tween:
		_pulse_tween.kill()
	pulse_rect.color = pulse_color
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(pulse_rect, "color:a", 0.0, 0.4)


func _shake_camera() -> void:
	if not Settings.screen_shake:
		return
	if _camera_tween:
		_camera_tween.kill()
	_camera_tween = create_tween()
	var strength := shake_strength
	for i in 6:
		_camera_tween.tween_property(camera, "h_offset", randf_range(-strength, strength), 0.03)
		_camera_tween.parallel().tween_property(camera, "v_offset", randf_range(-strength, strength), 0.03)
		strength *= 0.7
	_camera_tween.tween_property(camera, "h_offset", 0.0, 0.04)
	_camera_tween.parallel().tween_property(camera, "v_offset", 0.0, 0.04)
