class_name Stronghold
extends Node3D
## The central base. Owns its health; sockets and purchases come later.

signal health_changed(current: int, maximum: int)
signal destroyed

@export_range(1, 10000) var max_health := 20

var health := 0

var _is_destroyed := false


func _ready() -> void:
	health = max_health


func take_damage(amount: int) -> void:
	if _is_destroyed or amount <= 0:
		return  # each hit applies once; nothing after destruction
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health == 0:
		_is_destroyed = true
		destroyed.emit()
