extends Node
## Gives every Button a small bounce: grows on hover/keyboard focus, squashes on press.
## Add metadata "no_juice" (any value) to a button to leave it alone.

const HOVER_SCALE := Vector2(1.1, 1.1)
const PRESS_SCALE := Vector2(0.95, 0.95)
const TIME := 0.08

const CURSOR := preload("res://assets/2d_art/cursor.png")
const CURSOR_PRESSED := preload("res://assets/2d_art/cursor_pressed.png")
const CURSOR_HOTSPOT := Vector2(2, 2)

var _cursor_down := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	_hook_existing(get_tree().root)
	
	
func _process(_delta: float) -> void:
	var down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if down == _cursor_down:
		return
	_cursor_down = down
	Input.set_custom_mouse_cursor(CURSOR_PRESSED if down else CURSOR, Input.CURSOR_ARROW, CURSOR_HOTSPOT)


func _hook_existing(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_hook_existing(child)


func _on_node_added(node: Node) -> void:
	# Toggles (CheckBox/CheckButton) look odd bouncing, so only plain buttons.
	if not node is Button or node is CheckBox or node is CheckButton:
		return
	if node.has_meta("no_juice") or node.has_meta("_juiced"):
		return
	node.set_meta("_juiced", true)
	var button := node as Button
	button.mouse_entered.connect(_to.bind(button, HOVER_SCALE))
	button.mouse_exited.connect(_settle.bind(button))
	button.focus_entered.connect(_on_focus.bind(button))
	button.focus_exited.connect(_settle.bind(button))
	button.button_down.connect(_to.bind(button, PRESS_SCALE))
	button.button_up.connect(_settle.bind(button))


## Keyboard/gamepad focus grows the button; a menu grabbing focus on open does not.
func _on_focus(button: Button) -> void:
	for action in Audio.NAV_ACTIONS:
		if Input.is_action_just_pressed(action):
			_to(button, HOVER_SCALE)
			return


## Back to hover size if the mouse is still on it, otherwise normal size.
func _settle(button: Button) -> void:
	_to(button, HOVER_SCALE if button.is_hovered() else Vector2.ONE)


func _to(button: Button, target: Vector2) -> void:
	if button.disabled:
		target = Vector2.ONE  # disabled buttons stay still (and recover if just disabled)
	if button.has_meta(&"juice_tween"):
		var old: Tween = button.get_meta(&"juice_tween")
		if old and old.is_valid():
			old.kill()
	button.pivot_offset = button.size * 0.5
	var tween := button.create_tween()
	button.set_meta(&"juice_tween", tween)
	tween.tween_property(button, "scale", target, TIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
