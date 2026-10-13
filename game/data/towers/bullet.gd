extends Area3D

@export var damage := 1000.0
@export var bulletSpeed := 1.0
@export var targetEnemy : Node3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#homes in on enemies since I couldn't get proper aim direction
	if (targetEnemy):
		look_at(targetEnemy.global_position)
	position += -transform.basis.z * bulletSpeed * delta
	
func _on_area_entered(area: Area3D) -> void:
	if (area.collision_layer == 2):
		var enemy := area.get_parent()
		enemy.take_damage(damage)
		queue_free()
