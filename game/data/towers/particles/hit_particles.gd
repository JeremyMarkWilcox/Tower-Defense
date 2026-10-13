extends CPUParticles3D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _ready() -> void:
	finished.connect(queue_free)
