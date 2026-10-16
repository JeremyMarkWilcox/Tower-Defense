class_name HUD
extends Control
## The in-game HUD. Only listens to signals and shows values; it never changes game state.

@export var gold_manager: GoldManager
@export var stronghold: Stronghold
@export var wave_manager: WaveManager

@export_group("Nodes")
## Shaken when the Stronghold is hit. Must not be inside a container.
@export var health_panel: Control
@export var health_bar: ProgressBar
@export var health_label: Label
@export var gold_label: Label
@export var wave_label: Label
@export var wave_banner: Label
@export var banner_color := Color(0.6, 0.85, 1.0)
@export var final_banner_color := Color(0.85, 0.1, 0.1)
@export var low_health_vignette: ColorRect

@export_group("Look")
## Below this share of health, the bar pulses.
@export_range(0.0, 1.0, 0.05) var vignette_peak := 0.15
@export_range(0.0, 1.0, 0.05) var vignette_low := 0.09

@export_range(0.0, 1.0, 0.05) var low_health_ratio := 0.25
@export var hit_color := Color(1.0, 0.35, 0.35)
@export var shake_strength := 6.0

var _bar_tween: Tween
var _hit_tween: Tween
var _shake_tween: Tween
var _gold_tween: Tween
var _banner_tween: Tween
var _low_tween: Tween
var _panel_rest := Vector2.ZERO
var _vignette_tween: Tween
var _vignette_on := false


func _ready() -> void:
	if low_health_vignette:
		low_health_vignette.material.set_shader_parameter("strength", 0.0)
	_ignore_mouse(self)  # never block clicks on threads or sockets
	wave_banner.modulate.a = 0.0
	# Systems may have started before the HUD connected, so read current values first.
	_show_health(stronghold.health, stronghold.max_health, false)
	_show_gold(gold_manager.gold, false)
	stronghold.health_changed.connect(func(current: int, maximum: int) -> void:
		_show_health(current, maximum, true))
	gold_manager.gold_changed.connect(func(current: int) -> void: _show_gold(current, true))
	wave_manager.wave_started.connect(_on_wave_started)
	if wave_manager.current_wave >= 0:
		_on_wave_started(wave_manager.current_wave + 1, wave_manager.waves.size())


func _show_health(current: int, maximum: int, animate: bool) -> void:
	health_bar.max_value = maximum
	health_label.text = "%d / %d" % [current, maximum]
	if _bar_tween:
		_bar_tween.kill()
	if animate:
		_bar_tween = create_tween()
		_bar_tween.tween_property(health_bar, "value", float(current), 0.25)
		_flash_hit()
	else:
		health_bar.value = current
	var is_low := current > 0 and float(current) / maximum <= low_health_ratio
	_set_low_health(is_low)
	_set_vignette(is_low)
	
	
func _set_vignette(on: bool) -> void:
	if on == _vignette_on or low_health_vignette == null:
		return
	_vignette_on = on
	if _vignette_tween:
		_vignette_tween.kill()
	var param := "material:shader_parameter/strength"
	_vignette_tween = create_tween()
	if on and Settings.flashing:
		_vignette_tween.set_loops()
		_vignette_tween.tween_property(low_health_vignette, param, vignette_peak, 0.6)
		_vignette_tween.tween_property(low_health_vignette, param, vignette_low, 0.8)
	else:
		_vignette_tween.tween_property(low_health_vignette, param, vignette_peak if on else 0.0, 0.5)

func _flash_hit() -> void:
	if _hit_tween:
		_hit_tween.kill()
	health_panel.modulate = hit_color
	_hit_tween = create_tween()
	_hit_tween.tween_property(health_panel, "modulate", Color.WHITE, 0.3)
	if not Settings.screen_shake:
		return
	if _shake_tween and _shake_tween.is_running():
		_shake_tween.kill()
	else:
		_panel_rest = health_panel.position
	_shake_tween = create_tween()
	var strength := shake_strength
	for i in 5:
		var offset := Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		_shake_tween.tween_property(health_panel, "position", _panel_rest + offset, 0.03)
		strength *= 0.6
	_shake_tween.tween_property(health_panel, "position", _panel_rest, 0.04)


func _set_low_health(is_low: bool) -> void:
	if is_low == (_low_tween != null):
		return
	if _low_tween:
		_low_tween.kill()
		_low_tween = null
		health_bar.modulate = Color.WHITE
	if is_low and Settings.flashing:
		_low_tween = create_tween().set_loops()
		_low_tween.tween_property(health_bar, "modulate", Color(1.0, 0.5, 0.5), 0.4)
		_low_tween.tween_property(health_bar, "modulate", Color.WHITE, 0.4)


func _show_gold(current: int, animate: bool) -> void:
	gold_label.text = str(current)
	if not animate:
		return
	if _gold_tween:
		_gold_tween.kill()
	gold_label.pivot_offset = gold_label.size * 0.5
	gold_label.scale = Vector2(1.25, 1.25)
	_gold_tween = create_tween()
	_gold_tween.tween_property(gold_label, "scale", Vector2.ONE, 0.2)


func _on_wave_started(number: int, total: int) -> void:
	wave_label.text = "Wave %d / %d" % [number, total]
	wave_banner.text = "Final Wave" if number == total else "Wave %d" % number
	var is_final := number == total
	wave_banner.add_theme_color_override("font_color", final_banner_color if is_final else banner_color)
	if _banner_tween:
		_banner_tween.kill()
	wave_banner.modulate.a = 0.0
	_banner_tween = create_tween()
	_banner_tween.tween_property(wave_banner, "modulate:a", 1.0, 0.3)
	_banner_tween.tween_interval(1.2)
	_banner_tween.tween_property(wave_banner, "modulate:a", 0.0, 0.6)


func _ignore_mouse(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)
