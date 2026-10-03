class_name GameManager
extends Node
## Owns the run: setup, active play, victory and defeat.
## Connects the other systems once. Restart is handled by SceneManager
## reloading the scene, so no manual cleanup.

enum RunState { SETUP, ACTIVE, VICTORY, DEFEAT }

@export var music: AudioStream
@export var pause_menu: BaseMenu
@export var wave_manager: WaveManager
@export var end_screen: RunEndScreen

var state: RunState = RunState.SETUP

var _last_window_size := Vector2i.ZERO


func _ready() -> void:
	Audio.play_music(music)
	Debug.win_requested.connect(_win)
	Debug.lose_requested.connect(_lose)
	if OS.has_feature("web"):
		_last_window_size = get_window().size
		get_window().size_changed.connect(_on_window_size_changed)
	_connect_systems()
	_start_run()


func _connect_systems() -> void:
	wave_manager.boss_defeated.connect(_win)
	# Temporary prints until the Stronghold (Step 4) and GoldManager (Step 5) exist.
	wave_manager.enemy_reached_stronghold.connect(func(damage: int) -> void:
		print("Stronghold hit for %d" % damage))
	wave_manager.enemy_killed.connect(func(bounty: int) -> void:
		print("Enemy killed, bounty %d" % bounty))
	wave_manager.early_call_rewarded.connect(func(bonus: int) -> void:
		print("Early-call bonus %d" % bonus))
	wave_manager.wave_started.connect(func(number: int, total: int) -> void:
		print("Wave %d / %d" % [number, total]))


func _start_run() -> void:
	state = RunState.ACTIVE
	wave_manager.start()


func _win() -> void:
	if state != RunState.ACTIVE:
		return  # the outcome is decided once
	state = RunState.VICTORY
	wave_manager.stop()
	MenuManager.close_all()
	end_screen.set_result(true)
	MenuManager.open_menu(end_screen)


func _lose() -> void:
	if state != RunState.ACTIVE:
		return
	state = RunState.DEFEAT
	wave_manager.stop()
	MenuManager.close_all()
	end_screen.set_result(false)
	MenuManager.open_menu(end_screen)


func _unhandled_input(event: InputEvent) -> void:
	if state != RunState.ACTIVE:
		return
	if event.is_action_pressed("pause") and not MenuManager.is_menu_open():
		MenuManager.open_menu(pause_menu)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("call_next_wave"):
		wave_manager.call_next_wave()
		get_viewport().set_input_as_handled()


func _on_window_size_changed() -> void:
	var new_size := get_window().size
	# Leaving fullscreen (Esc in a browser) shrinks the window: pause.
	if new_size.x * new_size.y < _last_window_size.x * _last_window_size.y \
			and state == RunState.ACTIVE and not MenuManager.is_menu_open():
		MenuManager.open_menu(pause_menu)
	_last_window_size = new_size
