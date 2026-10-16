extends Node3D
## Expanding frost ring that shows Ice 2's slow radius, then frees itself.

@export var ring: MeshInstance3D
@export var shards: CPUParticles3D
@export var duration := 0.45


func play(radius: float) -> void:
	if ring == null:
		queue_free()
		return
	if shards:
		shards.emission_ring_radius = radius
		shards.emission_ring_inner_radius = radius * 0.8
		shards.emitting = true
		shards.restart()

	ring.scale = Vector3(radius * 0.2, 1.0, radius * 0.2)
	ring.transparency = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(ring, "scale", Vector3(radius, 1.0, radius), duration * 0.6) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "transparency", 1.0, duration).set_delay(duration * 0.3)
	# Wait for the shards to land before freeing.
	var wait := maxf(duration, shards.lifetime if shards else 0.0)
	tween.chain().tween_interval(wait - duration + 0.1)
	tween.chain().tween_callback(queue_free)
