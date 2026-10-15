class_name GoldPopups
extends Node3D
## Floats a "+N" in pumpkin orange where an enemy died, then fades it out.

@export var wave_manager: WaveManager
@export var font: Font

@export_group("Look")
@export var color := Color("F28C28")
@export var outline_color := Color("2A1408")
@export var font_size := 64
@export var pixel_size := 0.01  ## world size of one font pixel; raise if too small
@export var start_height := 1.5  ## above the enemy's feet
@export var rise := 1.2
@export var duration := 0.9


func _ready() -> void:
	wave_manager.bounty_dropped.connect(_spawn)


func _spawn(amount: int, at: Vector3) -> void:
	if amount <= 0:
		return
	var label := Label3D.new()
	label.text = "+%d" % amount
	label.font = font
	label.font_size = font_size
	label.outline_size = 12
	label.modulate = color
	label.outline_modulate = outline_color
	label.pixel_size = pixel_size
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true  # always drawn on top of enemies and effects
	label.render_priority = 10
	add_child(label)

	var start := at + Vector3(randf_range(-0.3, 0.3), start_height, 0.0)  # slight offset so stacked kills don't overlap
	label.global_position = start
	label.scale = Vector3.ONE * 0.6

	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "scale", Vector3.ONE, 0.15) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "global_position", start + Vector3.UP * rise, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "transparency", 1.0, duration * 0.5).set_delay(duration * 0.5)
	tween.chain().tween_callback(label.queue_free)
