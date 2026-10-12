extends Node3D

const bulletScene = preload("res://game/data/towers/bullet.tscn")

@export var range_one: Area3D
@export var range_two: Area3D
@export var range_three: Area3D
@export var twrFireRate := 2000
@export var twrDamage := 1
@export var twrBulletSpeed := 10
@export var tower_mesh: MeshInstance3D

var targetEnemy: Node3D = null

func _process(delta: float) -> void:
	
	if targetEnemy == null or not is_instance_valid(targetEnemy):
		var bodies = range_three.get_overlapping_bodies()
		if bodies.size() > 0:
			targetEnemy = bodies[0] # Pick the first enemy in range
		else:
			targetEnemy = null
			return
			
	print(targetEnemy.global_position.x)
