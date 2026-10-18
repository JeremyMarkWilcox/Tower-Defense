extends Control

@export_file("*.tscn") var game_scene: String
@export var music: AudioStream
@export var play_button: Button
@export var settings_button: Button
@export var credits_button: Button
@export var quit_button: Button
@export var settings_menu: BaseMenu
@export var credits_menu: BaseMenu
@export var version_label: Label
@export var intro: TitleIntro
## Hidden until the intro finishes: the title art panel and the button column.
@export var menu_items: Array[CanvasItem] = []

var _loaded_game: PackedScene


func _ready() -> void:
	version_label.text = "v" + str(ProjectSettings.get_setting("application/config/version"))
	Audio.play_music(music)
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(func() -> void: MenuManager.open_menu(settings_menu))
	credits_button.pressed.connect(func() -> void: MenuManager.open_menu(credits_menu))
	quit_button.pressed.connect(SceneManager.quit)
	quit_button.visible = not OS.has_feature("web")  # browsers can't close the tab
	MenuManager.menu_closed.connect(_on_menu_closed)
	if intro:
		for item in menu_items:
			item.visible = false
		intro.finished.connect(_show_menu)
	else:
		play_button.grab_focus()


func _on_menu_closed(_menu: BaseMenu) -> void:
	if not MenuManager.is_menu_open():
		play_button.grab_focus()
		

func _on_play_pressed() -> void:
	if intro:
		play_button.disabled = true
		var tween := create_tween().set_parallel(true)
		for item in menu_items:
			tween.tween_property(item, "modulate:a", 0.0, 0.3)
		await intro.play_transition()
	_loaded_game = ResourceLoader.load_threaded_get(game_scene)  # waits only if it isn't done yet
	SceneManager.change_scene(game_scene)


func _show_menu() -> void:
	ResourceLoader.load_threaded_request(game_scene)  # after the intro, so it doesn't stutter
	var tween := create_tween().set_parallel(true)
	for item in menu_items:
		item.visible = true
		item.modulate.a = 0.0
		tween.tween_property(item, "modulate:a", 1.0, 0.8)  # the title "burns in"
	play_button.grab_focus()
