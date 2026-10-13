class_name TowerData
extends Resource

@export var basiclvl_1: PackedScene
@export var firelvl_1: PackedScene
@export var icelvl_1: PackedScene

var costData : Array[Array] = [
	[10,20,30],
	[10,20,30],
	[10,20,30]
]

var damageData : Array[Array] = [
	[10,20,30],
	[10,20,30],
	[10,20,30]
]

var fireRateData : Array[Array] = [
	[10,20,30],
	[10,20,30],
	[10,20,30]
]

var bulletSpeedData : Array[Array] = [
	[10,20,30],
	[10,20,30],
	[10,20,30]
]

# Use a function instead of a variable array so it evaluates live
func get_scene(type: int, level: int) -> PackedScene:
	var matching_array := [
		[basiclvl_1, basiclvl_1, basiclvl_1],
		[firelvl_1, firelvl_1, firelvl_1],
		[icelvl_1, icelvl_1, icelvl_1]
	]
	return matching_array[type][level]
