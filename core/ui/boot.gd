extends Control
## First screen. On web, waits for a click or key so the browser allows audio.
## Then shows the jam cards (made for / wildcards) while the title loads.

@export_file("*.tscn") var next_scene: String
@export var prompt_label: Label
## Show the prompt on desktop too, for testing in the editor.
@export var always_show := false

@export_group("Jam Cards")
## Hidden once the cards start (the "Click to Start" row with the pumpkins).
@export var prompt_row: CanvasItem
@export var made_for: Control
@export var wildcards: Control
@export var card_fade := 0.4
@export var card_hold := 2.2

var _started := false
var _loaded_scene: PackedScene  # keeps the preloaded title alive until we switch
var _card_tween: Tween


func _ready() -> void:
	made_for.modulate.a = 0.0
	wildcards.modulate.a = 0.0
	ResourceLoader.load_threaded_request(next_scene)  # load the title while the prompt shows
	if not OS.has_feature("web") and not always_show:
		_start.call_deferred()  # desktop: skip straight to the cards
		return
	_pulse_prompt()


func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if not (event is InputEventMouseButton or event is InputEventKey \
			or event is InputEventJoypadButton or event is InputEventScreenTouch):
		return
	get_viewport().set_input_as_handled()
	if not _started:
		_start()
	elif _card_tween and _card_tween.is_running():
		_card_tween.custom_step(1000.0)  # any press skips the cards


func _start() -> void:
	_started = true
	if prompt_row:
		prompt_row.hide()
	await _play_jam_cards()
	# Usually done already; if not, show that we're working on it.
	if ResourceLoader.load_threaded_get_status(next_scene) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		if prompt_row:
			prompt_row.show()
		prompt_label.text = "Loading..."
		while ResourceLoader.load_threaded_get_status(next_scene) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
	_loaded_scene = ResourceLoader.load_threaded_get(next_scene)
	SceneManager.change_scene(next_scene)


## Made-for card, then the wildcards card: fade in, hold, fade out.
func _play_jam_cards() -> void:
	_card_tween = create_tween()
	for card: Control in [made_for, wildcards]:
		_card_tween.tween_property(card, "modulate:a", 1.0, card_fade)
		_card_tween.tween_interval(card_hold)
		_card_tween.tween_property(card, "modulate:a", 0.0, card_fade)
	await _card_tween.finished


func _pulse_prompt() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(prompt_label, "modulate:a", 0.3, 0.8)
	tween.tween_property(prompt_label, "modulate:a", 1.0, 0.8)
