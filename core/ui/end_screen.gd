extends BaseMenu
## Reusable end-of-game screen. Instance it once for Win and once for Game Over.

@export var heading_text := "Game Over"
@export var stinger: AudioStream
@export var heading_label: Label
@export var retry_button: Button
@export var title_button: Button
@export var music: AudioStream

var _sounds_played := false  # coming back from Credits shouldn't replay the stinger


func _ready() -> void:
	super()
	heading_label.text = heading_text
	retry_button.pressed.connect(SceneManager.restart)
	title_button.pressed.connect(SceneManager.return_to_title)


func open() -> void:
	super()
	if _sounds_played:
		return
	_sounds_played = true
	Audio.play_sfx(stinger)  # a short win or lose sound; empty = silent
	if music:
		Audio.play_music(music)  # empty = keep the game's music playing
