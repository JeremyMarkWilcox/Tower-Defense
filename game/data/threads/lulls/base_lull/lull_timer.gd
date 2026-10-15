class_name LullTimer
extends Control
## The shared lull countdown at the top of the screen.
## Shifts from calm to urgent, and the last few numbers punch in.

@export var thread_manager: ThreadManager
@export var label: Label
@export var caption: Label

@export_group("Look")
@export var calm_color := Color("F28C28")
@export var urgent_color := Color("FF3B30")
## The colors shift toward urgent over the last few seconds.
@export var urgent_seconds := 5.0
## In the last few seconds, each new number punches in.
@export var punch_seconds := 3
@export var punch_scale := 1.4
@export var tick_sound: AudioStream

var _last_shown := -1
var _punch_tween: Tween


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE  # never block clicks on threads
	hide()
	thread_manager.lull_started.connect(func(_duration: float) -> void:
		_last_shown = -1
		show()
		_refresh())
	thread_manager.lull_ended.connect(hide)


func _process(_delta: float) -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	var time_left := thread_manager.get_time_left()
	var t := clampf(1.0 - time_left / urgent_seconds, 0.0, 1.0)
	var color := calm_color.lerp(urgent_color, t)
	label.add_theme_color_override("font_color", color)
	if caption:
		caption.add_theme_color_override("font_color", color)

	var shown := ceili(time_left)
	if shown == _last_shown:
		return  # only touch the text when the number actually changes
	_last_shown = shown
	label.text = str(shown)
	if shown > 0 and shown <= punch_seconds:
		_punch()


func _punch() -> void:
	if _punch_tween:
		_punch_tween.kill()
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2.ONE * punch_scale
	_punch_tween = create_tween()
	_punch_tween.tween_property(label, "scale", Vector2.ONE, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if tick_sound:
		Audio.play_sfx(tick_sound)
