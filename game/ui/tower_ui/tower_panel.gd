class_name TowerPanel
extends Control
## Shared base for the tower panels: holds the socket, refreshes when gold changes,
## and closes on Esc or the Close button. Doesn't pause the game.

@export var stronghold: Stronghold
@export var gold_manager: GoldManager
@export var close_button: Button

var socket: TowerSocket


func _ready() -> void:
	hide()
	gold_manager.gold_changed.connect(func(_gold: int) -> void:
		if visible:
			_refresh())
	if close_button:
		close_button.pressed.connect(close)


func open_for(target: TowerSocket) -> void:
	socket = target
	show()
	_refresh()


func close() -> void:
	socket = null
	hide()


func _input(event: InputEvent) -> void:
	# _input runs before the pause handler, so Esc closes the panel instead of pausing.
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## Each panel fills in its own labels and buttons.
func _refresh() -> void:
	pass
