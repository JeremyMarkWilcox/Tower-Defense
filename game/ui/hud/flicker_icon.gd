class_name FlickerIcon
extends TextureRect
## Shows frames from a horizontal sprite strip at uneven, candle-like timing.

@export var sheet: Texture2D
@export var frame_count: int = 3
@export var min_time: float = 0.08
@export var max_time: float = 0.35

var _atlas := AtlasTexture.new()
var _frame: int = 0
var _timer: float = 0.0


func _ready() -> void:
	_atlas.atlas = sheet
	texture = _atlas
	_show_frame(0)


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = randf_range(min_time, max_time)
	var next := randi() % frame_count
	if next == _frame:
		next = (next + 1) % frame_count  # always change, so it never looks stuck
	_show_frame(next)


func _show_frame(index: int) -> void:
	_frame = index
	var width := sheet.get_width() / frame_count
	_atlas.region = Rect2(index * width, 0, width, sheet.get_height())
