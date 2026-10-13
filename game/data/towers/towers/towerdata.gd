class_name TowerData
extends Resource

@export var basiclvl_1: PackedScene
@export var firelvl_1: PackedScene
@export var icelvl_1: PackedScene

@export var standard_hit: PackedScene
@export var fire_hit: PackedScene
@export var ice_hit: PackedScene

@export var standard_shoot: PackedScene


var costData : Array[Array] = [
	[10,20,30],
	[10,20,30],
	[10,20,30]
]

var damageData : Array[Array] = [
	[4,8,12],
	[10,20,30],
	[10,20,30]
]

var fireRateData : Array[Array] = [
	[.80,.80,.80],
	[.10,.20,.30],
	[.10,.20,.30]
]

var bulletSpeedData : Array[Array] = [
	[20,40,60],
	[20,40,60],
	[20,40,60]
]

# Use a function instead of a variable array so it evaluates live
func get_mesh(type: int, level: int) -> PackedScene:
	var matching_array := [
		[basiclvl_1, basiclvl_1, basiclvl_1],
		[firelvl_1, firelvl_1, firelvl_1],
		[icelvl_1, icelvl_1, icelvl_1]
	]
	return matching_array[type][level]

func get_hit_particle(type: int, level: int) -> PackedScene:
	var matching_array := [
		[standard_hit, standard_hit, standard_hit],
		[fire_hit, fire_hit, fire_hit],
		[ice_hit, ice_hit, ice_hit]
	]
	return matching_array[type][level]
	
func get_shot_particle(_type: int, _level: int) -> PackedScene:
	return standard_shoot  # one shared muzzle flash for now
	

func get_bullet_mesh(type: int, level: int) -> PackedScene:
	var matching_array := [
		#add here later
		[basiclvl_1, basiclvl_1, basiclvl_1],
		[firelvl_1, firelvl_1, firelvl_1],
		[icelvl_1, icelvl_1, icelvl_1]
	]
	return matching_array[type][level]
