class_name RunEndScreen
extends "res://core/ui/end_screen.gd"
## One end screen for both outcomes. Call set_result() before opening it.

@export var win_heading := "You Win!"
@export var win_stinger: AudioStream
@export var win_music: AudioStream
@export var lose_heading := "Game Over"
@export var lose_stinger: AudioStream
@export var lose_music: AudioStream
@export var win_color := Color("F28C28")
@export var lose_color := Color("B3262E")


func set_result(won: bool) -> void:
	heading_label.text = win_heading if won else lose_heading
	heading_label.add_theme_color_override("font_color", win_color if won else lose_color)
	stinger = win_stinger if won else lose_stinger
	music = win_music if won else lose_music
