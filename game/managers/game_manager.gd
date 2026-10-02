class_name GameManager
extends Node
## Owns the run: setup, active play, victory and defeat.
## Restart is handled by SceneManager reloading the scene, so no manual cleanup.

enum RunState { SETUP, ACTIVE, VICTORY, DEFEAT }

@export var music: AudioStream
@export var pause_menu: BaseMenu
@export var win_screen: BaseMenu
@export var game_over_screen: BaseMenu

var state: RunState = RunState.SETUP

var _last_window_size := Vector2i.ZERO


func _ready() -> void:
	Audio.play_music(music)
	Debug.win_requested.connect(_win)
	Debug.lose_requested.connect(_lose)
	if OS.has_feature("web"):
		_last_window_size = get_window().size
		get_window().size_changed.connect(_on_window_size_changed)
	_start_run()


func _start_run() -> void:
	# Later steps: reset gold, start the wave schedule.
	state = RunState.ACTIVE


func _win() -> void:
	if state != RunState.ACTIVE:
		return  # the outcome is decided once
	state = RunState.VICTORY
	MenuManager.close_all()
	MenuManager.open_menu(win_screen)


func _lose() -> void:
	if state != RunState.ACTIVE:
		return
	state = RunState.DEFEAT
	MenuManager.close_all()
	MenuManager.open_menu(game_over_screen)


func _unhandled_input(event: InputEvent) -> void:
	if state != RunState.ACTIVE:
		return
	if event.is_action_pressed("pause") and not MenuManager.is_menu_open():
		MenuManager.open_menu(pause_menu)
		get_viewport().set_input_as_handled()


func _on_window_size_changed() -> void:
	var new_size := get_window().size
	# Leaving fullscreen (Esc in a browser) shrinks the window: pause.
	if new_size.x * new_size.y < _last_window_size.x * _last_window_size.y \
			and state == RunState.ACTIVE and not MenuManager.is_menu_open():
		MenuManager.open_menu(pause_menu)
	_last_window_size = new_size
