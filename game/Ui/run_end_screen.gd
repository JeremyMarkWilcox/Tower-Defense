class_name RunEndScreen
extends "res://core/ui/end_screen.gd"
## One end screen for both outcomes. Call set_result() before opening it.

@export var win_heading := "You Win!"
@export var win_stinger: AudioStream
@export var win_music: AudioStream
@export var lose_heading := "Game Over"
@export var lose_stinger: AudioStream
@export var lose_music: AudioStream


func set_result(won: bool) -> void:
	heading_label.text = win_heading if won else lose_heading
	stinger = win_stinger if won else lose_stinger
	music = win_music if won else lose_music
