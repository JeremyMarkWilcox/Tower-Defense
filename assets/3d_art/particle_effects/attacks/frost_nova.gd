extends Node3D
## Expanding frost ring that shows Ice 2's slow radius, then frees itself.

@export var ring: MeshInstance3D
@export var shards: CPUParticles3D
@export var duration := 0.45
## How see-through the ring is at its strongest. 0 = invisible, 1 = solid.
@export_range(0.0, 1.0, 0.05) var ring_alpha := 0.35

@export var sound: AudioStream
@export var sound_volume_db := -4.0


func play(radius: float) -> void:
	Audio.play_sfx(sound, 0.05, sound_volume_db)
	if ring == null:
		queue_free()
		return
	if shards:
		shards.emission_ring_radius = radius
		shards.emission_ring_inner_radius = radius * 0.8
		shards.emitting = true
		shards.restart()

	# Own copy of the material, so fading this nova doesn't fade the others.
	var mat := ring.get_active_material(0).duplicate() as StandardMaterial3D
	mat.albedo_color.a = ring_alpha
	ring.set_surface_override_material(0, mat)

	ring.scale = Vector3(radius * 0.2, 1.0, radius * 0.2)
	var tween := create_tween().set_parallel()
	tween.tween_property(ring, "scale", Vector3(radius, 1.0, radius), duration * 0.6) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color:a", 0.0, duration).set_delay(duration * 0.3)
	# Wait for the shards to land before freeing.
	var wait := maxf(duration, shards.lifetime if shards else 0.0)
	tween.chain().tween_interval(wait - duration + 0.1)
	tween.chain().tween_callback(queue_free)
