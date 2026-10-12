extends CanvasLayer
## Debug-only shortcuts. Inactive in release exports.
## F3 = FPS counter, F4 = invincible Stronghold, Page Up = win, Page Down = lose

signal win_requested
signal lose_requested

var _fps_label: Label
## Debug only: the Stronghold ignores all damage while this is on.
var stronghold_invincible := false

var _invincible_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.is_debug_build():
		set_process(false)
		set_process_input(false)
		return
	layer = 128  # draws above everything, including the fade
	_fps_label = Label.new()
	_fps_label.position = Vector2(8, 8)
	_fps_label.visible = false
	add_child(_fps_label)
	_invincible_label = Label.new()
	_invincible_label.text = "STRONGHOLD INVINCIBLE (F4)"
	_invincible_label.position = Vector2(8, 32)
	_invincible_label.modulate = Color.YELLOW
	_invincible_label.visible = false
	add_child(_invincible_label)


func _process(_delta: float) -> void:
	if _fps_label.visible:
		_fps_label.text = "FPS: %d" % Engine.get_frames_per_second()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	match (event as InputEventKey).keycode:
		KEY_F3:
			_fps_label.visible = not _fps_label.visible
		KEY_F4:
			stronghold_invincible = not stronghold_invincible
			_invincible_label.visible = stronghold_invincible
		KEY_PAGEUP:
			win_requested.emit()
		KEY_PAGEDOWN:
			lose_requested.emit()
			
