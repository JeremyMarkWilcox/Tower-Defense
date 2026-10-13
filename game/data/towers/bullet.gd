extends Area3D

@export var damage := 1000.0
@export var bulletSpeed := 1.0
@export var targetEnemy : Node3D
@export var hitParticle : PackedScene
var time := 0.0

func _ready() -> void:
	#prevents bullet from clipping through turret, may not be necessary if shot particle can cover it up
	visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta * bulletSpeed
	if time > 1.5:
		visible = true
	#homes in on enemies since I couldn't get proper aim direction
	if (targetEnemy):
		look_at(targetEnemy.global_position)
	position += -transform.basis.z * bulletSpeed * delta
	
func _on_area_entered(area: Area3D) -> void:
	if (area.collision_layer == 2):
		var enemy := area.get_parent()
		enemy.take_damage(damage)
		
		var newParticle := hitParticle.instantiate()
		get_tree().root.add_child(newParticle)
		newParticle.position = position
		var particleNodes := newParticle.get_children()
		for i in particleNodes:
			i.emitting = true
		
		queue_free()
