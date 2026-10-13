extends Node3D
## Tapers the trail over the flight: each new puff comes out smaller and fainter.

@export var trail: CPUParticles3D
@export var fade_time := 0.6  # seconds until the trail is at its weakest
@export var end_scale := 0.3  # puff size at the end, relative to the start


func _ready() -> void:
	if trail == null:
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property(trail, "scale_amount_min", trail.scale_amount_min * end_scale, fade_time)
	tween.tween_property(trail, "scale_amount_max", trail.scale_amount_max * end_scale, fade_time)
	tween.tween_property(trail, "color:a", 0.3, fade_time)
