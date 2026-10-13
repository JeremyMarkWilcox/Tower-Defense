extends Area3D

@export var direction : Vector3
@export var damage := 1000.0
@export var bulletSpeed := 1.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.x += direction.x * bulletSpeed * delta
	position.y += direction.y * bulletSpeed * delta
	position.z += direction.z * bulletSpeed * delta
	
	
func _on_area_entered(area: Area3D) -> void:
	if (area.collision_layer == 2):
		var enemy := area.get_parent()
		enemy.take_damage(damage)
		queue_free()
