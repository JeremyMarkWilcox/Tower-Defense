extends Button

@export_group("Skull Appearance")
@export_range(0.0, 1.0) var hover_opacity: float = 0.20
@export_range(0.0, 1.0) var click_opacity: float = 0.75

@export_group("Skull Timing")
@export_range(0.1, 10.0) var flip_min_seconds: float = 2.0
@export_range(0.1, 10.0) var flip_max_seconds: float = 5.0
@export_range(0.05, 1.0) var click_duration: float = 0.20

@onready var skulls: Array[TextureRect] = [
	$SkullLeft,
	$SkullRight,
]
@onready var caption: Label = $Caption

var _active: bool = false
var _next_flip_at: float = 0.0
var _click_until: float = 0.0


func _ready() -> void:
	# Decorations must not intercept the button's input.
	for skull in skulls:
		skull.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_ALL

	button_down.connect(_on_button_down)
	visibility_changed.connect(_on_visibility_changed)

	_reset_skull()


func _process(_delta: float) -> void:
	if disabled or not is_visible_in_tree():
		_reset_skull()
		return

	var now: float = _now()
	var highlighted: bool = is_hovered() or has_focus()

	if not highlighted:
		_reset_skull()
		return

	if not _active:
		_active = true
		_schedule_flip(now)

	# Flip both skulls together, except during the click reaction.
	if now >= _click_until and now >= _next_flip_at:
		for skull in skulls:
			skull.flip_h = not skull.flip_h
		_schedule_flip(now)

	_update_skull(now)


func _on_button_down() -> void:
	if disabled:
		return

	var now: float = _now()
	_active = true
	_click_until = now + click_duration
	_schedule_flip(_click_until)
	_update_skull(now)


func _update_skull(now: float) -> void:
	var reacting: bool = now < _click_until

	for skull in skulls:
		skull.visible = true
		skull.flip_v = reacting
		skull.self_modulate.a = (
			click_opacity if reacting else hover_opacity
		)


func _reset_skull() -> void:
	_active = false
	_click_until = 0.0

	for skull in skulls:
		skull.visible = false
		skull.flip_h = false
		skull.flip_v = false
		skull.self_modulate.a = hover_opacity


func _schedule_flip(now: float) -> void:
	var minimum: float = minf(flip_min_seconds, flip_max_seconds)
	var maximum: float = maxf(flip_min_seconds, flip_max_seconds)
	_next_flip_at = now + randf_range(minimum, maximum)


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		_reset_skull()


func _now() -> float:
	# Real time: changing gameplay speed won't speed up the skull.
	return Time.get_ticks_msec() / 1000.0
