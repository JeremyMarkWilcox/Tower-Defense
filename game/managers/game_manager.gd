class_name GameManager
extends Node
## Owns the run: setup, active play, victory and defeat.
## Connects the other systems once. Restart is handled by SceneManager
## reloading the scene, so no manual cleanup.

enum RunState { SETUP, ACTIVE, VICTORY, DEFEAT }

@export var music: AudioStream
@export var pause_menu: BaseMenu
@export var end_screen: RunEndScreen
@export var wave_manager: WaveManager
@export var stronghold: Stronghold
@export var gold_manager: GoldManager
@export var thread_manager: ThreadManager

## Seconds between the Stronghold falling and the Game Over screen.
@export var defeat_delay := 1.8

## Plays when the final wave starts.
@export var final_wave_music: AudioStream
## Plays when the boss's thread releases it.
@export var boss_music: AudioStream
## Short crossfade so the boss arrival hits hard.
@export var boss_music_fade := 0.4
## Seconds between the boss dying and the victory screen.
@export var victory_delay := 2.0

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
	wave_manager.stronghold_attacked.connect(stronghold.take_damage)
	wave_manager.enemy_killed.connect(gold_manager.add_gold)
	wave_manager.lull_requested.connect(thread_manager.start_lull)
	thread_manager.lull_ended.connect(wave_manager.on_lull_ended)
	thread_manager.thread_released.connect(_on_thread_released)
	stronghold.destroyed.connect(_lose)
	MenuManager.menu_opened.connect(_on_menu_opened)
	MenuManager.menu_closed.connect(_on_menu_closed)
	wave_manager.wave_started.connect(_on_wave_started)


func _on_wave_started(number: int, total: int) -> void:
	if number == total and final_wave_music:
		Audio.play_music(final_wave_music)	
		

func _on_thread_released(data: SignalThreadData, at: Vector3) -> void:
	wave_manager.spawn_group(data.enemy, data.count, data.spawn_interval, at)
	if data.enemy and data.enemy.is_boss and boss_music:
		Audio.play_music(boss_music, boss_music_fade)

	
## Only the pause menu stops the music; hint cards keep it playing.
func _on_menu_opened(menu: BaseMenu) -> void:
	if menu == pause_menu:
		Audio.set_music_paused(true)


func _on_menu_closed(_menu: BaseMenu) -> void:
	# Pause -> Settings -> Back still has the pause menu open underneath,
	# so only resume once every menu is closed.
	if not MenuManager.is_menu_open():
		Audio.set_music_paused(false)


func _start_run() -> void:
	state = RunState.ACTIVE
	gold_manager.reset()
	wave_manager.start()


func _win() -> void:
	if state != RunState.ACTIVE:
		return
	state = RunState.VICTORY
	_end_run()
	stronghold.lock()  # leftover enemies can't take it down after you've won
	await get_tree().create_timer(victory_delay).timeout  # let the boss death play out
	end_screen.set_result(true)
	MenuManager.open_menu(end_screen)


func _lose() -> void:
	if state != RunState.ACTIVE:
		return
	state = RunState.DEFEAT
	_end_run()  # stops spawning and threads right away
	await get_tree().create_timer(defeat_delay).timeout  # let the fall play out
	end_screen.set_result(false)
	MenuManager.open_menu(end_screen)


func _end_run() -> void:
	wave_manager.stop()
	thread_manager.stop()
	MenuManager.close_all()


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
