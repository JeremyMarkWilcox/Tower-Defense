extends Control
## First screen. On web, waits for a click or key so the browser allows audio.

@export_file("*.tscn") var next_scene: String
@export var prompt_label: Label
## Show the prompt on desktop too, for testing in the editor.
@export var always_show := false

var _started := false
var _loaded_scene: PackedScene  # keeps the preloaded title alive until we switch


func _ready() -> void:
	ResourceLoader.load_threaded_request(next_scene)  # load the title while the prompt shows
	if not OS.has_feature("web") and not always_show:
		_start.call_deferred()  # desktop: skip straight to the title
		return
	_pulse_prompt()


func _input(event: InputEvent) -> void:
	if _started or not event.is_pressed():
		return
	if event is InputEventMouseButton or event is InputEventKey \
			or event is InputEventJoypadButton or event is InputEventScreenTouch:
		get_viewport().set_input_as_handled()
		_start()


func _start() -> void:
	_started = true
	# Usually done already; if not, show that we're working on it.
	if ResourceLoader.load_threaded_get_status(next_scene) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		prompt_label.text = "Loading..."
		while ResourceLoader.load_threaded_get_status(next_scene) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
	_loaded_scene = ResourceLoader.load_threaded_get(next_scene)
	SceneManager.change_scene(next_scene)


func _pulse_prompt() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(prompt_label, "modulate:a", 0.3, 0.8)
	tween.tween_property(prompt_label, "modulate:a", 1.0, 0.8)
