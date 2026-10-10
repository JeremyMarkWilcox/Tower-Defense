extends Node3D
## Test bench for Signal Threads. Not part of the game. R restarts the lull.

@export var thread_manager: ThreadManager
@export var lull: LullDefinition


func _ready() -> void:
	thread_manager.lull_started.connect(func(duration: float) -> void:
		print("Lull started: %.1fs" % duration))
	thread_manager.thread_released.connect(func(data: SignalThreadData, at: Vector3) -> void:
		print("Released %d x %s at %s" % [data.count, data.enemy.display_name, at]))
	thread_manager.cut_refused.connect(func(thread: SignalThread, reason: StringName) -> void:
		print("Refused %s: %s" % [thread.data.enemy.display_name, reason]))
	thread_manager.swarm_started.connect(func() -> void: print("SWARM"))
	thread_manager.lull_ended.connect(func() -> void: print("Lull ended"))
	thread_manager.start_lull(lull)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_R:
		thread_manager.start_lull(lull)
