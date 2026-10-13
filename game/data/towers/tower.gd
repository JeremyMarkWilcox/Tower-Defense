extends Node3D

const bulletScene = preload("res://game/data/towers/bullet.tscn")
@export var tower_data: TowerData

@export var range_one: Area3D
@export var range_two: Area3D
@export var range_three: Area3D

@export var type := 0
@export var level := 0
@export var twrFireRate := 1000
@export var twrDamage := 1
@export var twrBulletSpeed := 100
@export var twrMesh: MeshInstance3D
@export var turnRate := 5

@export var shoot_timer: Timer

var direction : Vector3
var targetEnemy: Node3D = null

func _ready() -> void:
	twrDamage = tower_data.damageData[type][level]
	twrFireRate = tower_data.fireRateData[type][level]
	twrBulletSpeed = tower_data.bulletSpeedData[type][level]

func _process(delta: float) -> void:
	#targeting logic
	if targetEnemy == null or not is_instance_valid(targetEnemy):
		var bodies := range_three.get_overlapping_areas()
		if bodies.size() > 0:
			targetEnemy = bodies[0] # Pick the first enemy in range
		else:
			targetEnemy = null
			return
	#aiming logic
	direction = (targetEnemy.global_position - global_position) * -1
	var target_angle = atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_angle, 0.1)
	#shooting logic
	if (targetEnemy):
		if (shoot_timer.is_stopped()):
			_shoot()
			shoot_timer.start(tower_data.fireRateData[type][level])

func _shoot() -> void:
	#firing logic
	var bulletInstance := bulletScene.instantiate()
	bulletInstance.direction = direction.normalized()
	add_sibling(bulletInstance)
	bulletInstance.global_transform = self.global_transform
	bulletInstance.damage = twrDamage
	bulletInstance.bulletSpeed = twrBulletSpeed
	
	return
