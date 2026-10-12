extends Node3D

const bulletScene = preload("res://game/data/towers/bullet.tscn")

@export var range_one: CollisionShape3D
@export var range_two: CollisionShape3D
@export var range_three: CollisionShape3D
@export var twrFireRate := 2000
@export var twrDamage := 1
@export var twrBulletSpeed := 10
@export var tower_mesh: MeshInstance3D

#this script will handle detecting and aiming at enemies.
#stronghold script will detect when a socket is hovered over,
#which will create a popup menu, which will instantiate one of these towers.
var targetEnemy : Node3D = null
var aimDirection := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	range_three.debug_color


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#will lock on to enemy and fire bullet
	if(targetEnemy == null):
		targetEnemy = range_three.get_overlapping_bodies()
	
	#debug fire bullet etc
	print(targetEnemy.position.x)
	
