class_name UIAnim
## Shared open/close animations for panels and menus.

const OPEN_TIME := 0.25
const CLOSE_TIME := 0.25


## Shows the control with a quick scale-up and fade-in.
static func pop_in(control: Control) -> void:
	var tween := _start(control)
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2(0.92, 0.92)
	control.modulate.a = 0.0
	control.show()
	tween.set_parallel()
	tween.tween_property(control, "scale", Vector2.ONE, OPEN_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate:a", 1.0, OPEN_TIME)


## Shrinks and fades the control, then hides it and resets it for next time.
static func pop_out(control: Control) -> void:
	if not control.visible:
		return
	var tween := _start(control)
	control.pivot_offset = control.size * 0.5
	tween.set_parallel()
	tween.tween_property(control, "scale", Vector2(0.95, 0.95), CLOSE_TIME)
	tween.tween_property(control, "modulate:a", 0.0, CLOSE_TIME)
	tween.chain().tween_callback(func() -> void:
		control.hide()
		control.scale = Vector2.ONE
		control.modulate.a = 1.0)


## Stops any running open/close on this control so the two never fight.
static func _start(control: Control) -> Tween:
	if control.has_meta(&"ui_anim"):
		var old: Tween = control.get_meta(&"ui_anim")
		if old and old.is_valid():
			old.kill()
	var tween := control.create_tween()
	control.set_meta(&"ui_anim", tween)
	return tween
