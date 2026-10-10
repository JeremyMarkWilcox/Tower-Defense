extends Node3D
## Test bench for Signal Threads. Not part of the game.

@export var thread_scene: PackedScene
@export var lull: LullDefinition
@export var thread_length := 18.0
@export var test_colors: Array[Color] = [Color(0.6, 0.2, 0.9), Color(0.85, 0.65, 0.1)]


func _ready() -> void:
	get_viewport().physics_object_picking = true
	var count := lull.threads.size()
	for i in count:
		var thread := thread_scene.instantiate() as SignalThread
		add_child(thread)
		var angle := i * TAU / count
		thread.setup(lull.threads[i], Vector3(cos(angle), 0.0, sin(angle)),
				thread_length, test_colors[i % test_colors.size()])
		thread.hovered.connect(func(t: SignalThread) -> void: t.set_highlighted(true))
		thread.unhovered.connect(func(t: SignalThread) -> void: t.set_highlighted(false))
		thread.clicked.connect(func(t: SignalThread) -> void:
			print("Clicked %s, ends at %s" % [t.data.enemy.display_name, t.get_end_position()]))
