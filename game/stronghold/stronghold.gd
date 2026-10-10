class_name Stronghold
extends Node3D
## The central base. Owns its health; sockets and purchases come later.

signal health_changed(current: int, maximum: int)
signal destroyed

@export_range(1, 10000) var max_health := 20

var health := 0
var _is_destroyed := false


#new tower stuff
#loadout keeps track of what tower types and levels are on the stronghold
var loadout: Array[int] = [
	11, 00, 00, 00, 00, 00
]
var cx : float = self.position.x
var cy : float = self.position.y
var cz : float = self.position.z
var towerPositions : Array[Vector3] = [
	Vector3(cx - 6.3, cy + 2.8, cz + .4),
	Vector3(cx - 1.9, cy + 2.8, cz - .4),
	Vector3(cx + 2.4, cy + 2.8, cz -1.5),
	Vector3(cx - 5.4, cy + 2.8, cz + 4.2),
	Vector3(cx - 1.0, cy + 2.8, cz + 3.4),
	Vector3(cx + 3.3, cy + 2.8,cz + 2.3)
]

func _ready() -> void:
	health = max_health
	change_tower(0, 0, 0)


func take_damage(amount: int) -> void:
	if _is_destroyed or amount <= 0:
		return  # each hit applies once; nothing after destruction
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health == 0:
		_is_destroyed = true
		destroyed.emit()

func change_tower(slot: int, type: int, level: int) -> void:
	#description
	
	pass
