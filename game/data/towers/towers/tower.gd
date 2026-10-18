extends Node3D

const bulletScene = preload("uid://bxdlpoael8gal")  # bullet/bullet.tscn
@export var tower_data: TowerData

#currently only range_three is being used, but if we implement more enemies/want the tower to focus on closer enemies instead of ones that have existed longer then should use smaller ranges too.
@export var range_one: Area3D
@export var range_two: Area3D
@export var range_three: Area3D

@export var type := 0
@export var level := 0
@export var twrFireRate := 1000
@export var twrDamage := 1
@export var twrBulletSpeed := 100
@export var twrMesh: MeshInstance3D
@export var twrHitParticle: PackedScene
@export var turnRate := 5
@export var muzzle: Marker3D
@export var twrShotParticle: PackedScene
@export var twrBulletVisual: PackedScene

@export var shoot_timer: Timer

var direction : Vector3
var targetEnemy: Node3D = null

func _ready() -> void:
	#should be determined when spawned by stronghold
	#twrDamage = tower_data.damageData[type][level]
	#twrFireRate = tower_data.fireRateData[type][level]
	#twrBulletSpeed = tower_data.bulletSpeedData[type][level]
	#twrHitParticle = tower_data.get_hit_particle(type,level)
	pass

func _process(_delta: float) -> void:
	#targeting logic
	#made change so that towers target closest enemies. However this may decrease performance so when web build is published, uncomment following line and add an indent to each line until ##marker
	#if targetEnemy == null or not is_instance_valid(targetEnemy):
	var bodies := range_three.get_overlapping_areas()
	if bodies.size() > 0:
		bodies.sort_custom(func(a,b):
			var distance_a := global_position.distance_to(a.global_position)
			var distance_b := global_position.distance_to(b.global_position)
			return distance_a < distance_b
		)
		targetEnemy = bodies[0] # Pick the first enemy in range
	else:
		targetEnemy = null
		return
	##marker
	#aiming logic
	direction = targetEnemy.global_position - global_position
	var target_angle := atan2(-direction.x, -direction.z)  # points -Z (the front) at the target
	global_rotation.y = lerp_angle(global_rotation.y, target_angle, 0.1)
		#shooting logic
	if targetEnemy and shoot_timer.is_stopped():
		shoot_timer.start(tower_data.fireRateData[type][level])
		_fire_volley()
		
		
## One shot for most towers, a quick burst for Fire 2 and Fire 3.
func _fire_volley() -> void:
	var shots := 1
	if type == TowerData.FIRE:
		shots = tower_data.burst_shots[level] #why isn't this working?
	if shots <= 1:
		_shoot()
		return
	# A tween owned by this tower: if the tower is upgraded (freed) mid-burst,
	# the remaining shots are cancelled cleanly.
	var tween := create_tween()
	for i in shots:
		tween.tween_callback(_shoot_if_target)
		tween.tween_interval(tower_data.burst_gap)


func _shoot_if_target() -> void:
	if is_instance_valid(targetEnemy):
		_shoot()


func _shoot() -> void:
	#firing logic
	var bulletInstance := bulletScene.instantiate()
	bulletInstance.targetEnemy = targetEnemy
	bulletInstance.visual_scene = twrBulletVisual
	add_sibling(bulletInstance)
	var spawn := muzzle.global_transform if muzzle else global_transform
	bulletInstance.global_transform = spawn
	bulletInstance.damage = twrDamage
	bulletInstance.bulletSpeed = twrBulletSpeed
	bulletInstance.hitParticle = twrHitParticle
	bulletInstance.type = type
	bulletInstance.level = level
	bulletInstance.tower_data = tower_data
	Audio.play_sfx(tower_data.get_shot_sound(type), 0.08, tower_data.shot_volume_db)

	if twrShotParticle:
		var flash := twrShotParticle.instantiate() as Node3D
		get_tree().current_scene.add_child(flash)
		flash.global_transform = spawn
