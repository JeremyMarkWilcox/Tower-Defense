class_name Stronghold
extends Node3D

signal health_changed(current: int, maximum: int)
signal destroyed
signal socket_clicked(socket: TowerSocket)

const TOWER_SCENE := preload("uid://hfqj55tjn8l8")  # towers/towers/tower.tscn

@export var towerdata: TowerData
@export_range(1, 10000) var max_health := 20
## The node holding the TowerSocket children.
@export var sockets_root: Node3D
## A free tower built when the run starts. -1 = start with nothing.
@export var starting_tower_type := 0
@export var starting_socket := 1

var health := 0
var sockets: Array[TowerSocket] = []
## type * 10 + level per socket, or -1 if empty. Kept for anything that reads it.
var loadout: Array[int] = []

var _is_destroyed := false


func _ready() -> void:
	health = max_health
	for child in sockets_root.get_children():
		var socket := child as TowerSocket
		if socket:
			sockets.append(socket)
			loadout.append(-1)
			socket.clicked.connect(func(s: TowerSocket) -> void: socket_clicked.emit(s))
	if starting_tower_type >= 0 and starting_socket < sockets.size():
		build_tower(sockets[starting_socket], starting_tower_type, 0)


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

## Builds a tower on a socket, replacing any tower already there.
## Doesn't touch gold; the shop checks and spends before calling this.
func build_tower(socket: TowerSocket, type: int, level: int) -> void:
	if socket.tower:
		socket.tower.queue_free()

	var tower := TOWER_SCENE.instantiate()
	tower.tower_data = towerdata
	tower.type = type
	tower.level = level
	tower.twrDamage = towerdata.damageData[type][level]
	tower.twrFireRate = towerdata.fireRateData[type][level]
	tower.twrBulletSpeed = towerdata.bulletSpeedData[type][level]
	tower.twrHitParticle = towerdata.get_hit_particle(type, level)
	tower.twrShotParticle = towerdata.get_shot_particle(type, level)
	socket.build_point.add_child(tower)

	var model := towerdata.get_mesh(type, level).instantiate() as Node3D
	model.rotation.y = PI
	tower.add_child(model)

	socket.tower = tower
	socket.tower_type = type
	socket.tower_level = level
	loadout[sockets.find(socket)] = type * 10 + level
