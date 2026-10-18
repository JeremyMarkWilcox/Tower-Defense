class_name RunEndScreen
extends "res://core/ui/end_screen.gd"
## One end screen for both outcomes. Call set_result() before opening it.

@export var win_heading := "You Win!"
@export_multiline var win_subtitle := "The signal falls silent."
@export var win_stinger: AudioStream
@export var win_music: AudioStream
@export var lose_heading := "Game Over"
@export_multiline var lose_subtitle := "The signal consumed the Stronghold."
@export var lose_stinger: AudioStream
@export var lose_music: AudioStream
@export var win_color := Color("F28C28")
@export var lose_color := Color("B3262E")
## The flavor line under the heading. Empty = no subtitle.
@export var subtitle_label: Label
## Shown only on a win. Opens the Credits menu from the game scene.
@export var credits_button: Button
@export var credits_menu: BaseMenu


func _ready() -> void:
	super()
	if credits_button and credits_menu:
		credits_button.pressed.connect(func() -> void: MenuManager.open_menu(credits_menu))


func set_result(won: bool) -> void:
	heading_label.text = win_heading if won else lose_heading
	heading_label.add_theme_color_override("font_color", win_color if won else lose_color)
	if subtitle_label:
		subtitle_label.text = win_subtitle if won else lose_subtitle
	if credits_button:
		credits_button.visible = won
	stinger = win_stinger if won else lose_stinger
	music = win_music if won else lose_music
