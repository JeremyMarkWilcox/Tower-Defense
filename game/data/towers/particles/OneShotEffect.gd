class_name OneShotEffect
extends Node3D
## Put on the root of any particle effect scene. Fires every CPUParticles3D child once,
## then frees the whole effect when they're done. No need to set One Shot by hand.


func _ready() -> void:
	var longest := 0.0
	for child in get_children():
		var particles := child as CPUParticles3D
		if particles == null:
			continue
		particles.one_shot = true
		particles.restart()  # starts emitting from the beginning
		longest = maxf(longest, particles.lifetime / maxf(particles.speed_scale, 0.01))
	# Emission lasts one lifetime and the last particle lives one more.
	await get_tree().create_timer(longest * 2.0 + 0.1, false).timeout
	queue_free()
