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

# Note: meshData initialization is fixed below!
var meshData : Array[Array] = []

func _init() -> void:
	# Initialize meshData here so it actually captures the exported PackedScenes
	meshData = [
		[basiclvl_1, basiclvl_1, basiclvl_1],
		[firelvl_1, firelvl_1, firelvl_1],
		[icelvl_1, icelvl_1, icelvl_1]
	]
