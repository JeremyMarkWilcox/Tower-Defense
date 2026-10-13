class_name Stronghold
extends Node3D

signal health_changed(current: int, maximum: int)
signal destroyed
@export var towerdata: Resource
@export_range(1, 10000) var max_health := 20
const towerScene = preload("res://game/data/towers/tower.tscn")

var health := 0
var _is_destroyed := false

var loadout: Array[int] = [11, 00, 00, 00, 00, 00]
var towerPositions: Array[Vector3] = []

func _ready() -> void:
	health = max_health
	

	var cx := position.x
	var cy := position.y
	var cz := position.z
	
	towerPositions = [
		Vector3(cx + 6, cy, cz + .5),
		Vector3(cx + 1.5, cy, cz + 1.5),
		Vector3(cx - 3, cy, cz + 2.5),
		Vector3(cx - 5.4, cy, cz + 4.2),
		Vector3(cx - 1.0, cy, cz + 3.4),
		Vector3(cx + 3.3, cy, cz + 2.3)
	]
	
	change_tower(0, 0, 0)

func take_damage(amount: int) -> void:
	if Debug.stronghold_invincible:
		return
	if _is_destroyed or amount <= 0:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health == 0:
		_is_destroyed = true
		destroyed.emit()

func change_tower(slot: int, type: int, level: int) -> void:
	var newTower := towerScene.instantiate()
	
	# Set position and stats
	newTower.position = towerPositions[slot]
	newTower.twrDamage = towerdata.damageData[type][level]
	newTower.twrFireRate = towerdata.fireRateData[type][level]
	newTower.type = type
	newTower.level = level
	
	# 1. Add the tower to the scene tree first
	add_child(newTower)
	
	# 2. Grab the .glb PackedScene from your resource data
	@warning_ignore("untyped_declaration")
	var glb_scene = towerdata.get_scene(type, level)
	@warning_ignore("untyped_declaration")
	var glb_instance = glb_scene.instantiate()
	glb_instance.position = Vector3.ZERO
	glb_instance.rotation.y = deg_to_rad(180)
	newTower.add_child(glb_instance)
	loadout[slot] = (type * 10) + level
