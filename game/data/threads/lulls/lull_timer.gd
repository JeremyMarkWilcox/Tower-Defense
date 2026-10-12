class_name LullTimer
extends Control
## The shared lull countdown at the top of the screen.
## Reads the time each frame, since a countdown changes every frame anyway.

@export var thread_manager: ThreadManager
@export var label: Label
@export var calm_color := Color(0.9, 0.85, 1.0)
@export var urgent_color := Color(1.0, 0.25, 0.2)
## The number shifts toward the urgent color over the last few seconds.
@export var urgent_seconds := 5.0
@export var caption: Label


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE  # never block clicks on threads
	hide()
	thread_manager.lull_started.connect(func(_duration: float) -> void: show())
	thread_manager.lull_ended.connect(hide)


func _process(_delta: float) -> void:
	if not visible:
		return
	var time_left := thread_manager.get_time_left()
	label.text = "%d" % ceili(time_left)
	var t := clampf(1.0 - time_left / urgent_seconds, 0.0, 1.0)
	label.modulate = calm_color.lerp(urgent_color, t)
	if caption:
		caption.modulate = label.modulate
