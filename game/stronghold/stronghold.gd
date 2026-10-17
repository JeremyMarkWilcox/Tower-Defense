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

@export_group("Feedback")
@export var hit_sound: AudioStream
@export var hit_volume_db := 0.0
@export var destroyed_sound: AudioStream
@export var destroyed_volume_db := 0.0
## Spawned where the Stronghold stood when it falls.
@export var destroyed_effect: PackedScene
@export var destroyed_effect_height := 1.5

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
	if health > 0:
		Audio.play_sfx(hit_sound, 0.1, hit_volume_db)
		return
	_is_destroyed = true
	Audio.play_sfx(destroyed_sound, 0.1, destroyed_volume_db)
	_spawn_destroyed_effect()
	destroyed.emit()


func _spawn_destroyed_effect() -> void:
	if destroyed_effect == null:
		return
	var effect := destroyed_effect.instantiate() as Node3D
	get_tree().current_scene.add_child(effect)
	effect.global_position = global_position + Vector3.UP * destroyed_effect_height

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
	tower.twrBulletVisual = towerdata.get_bullet_mesh(type, level)
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
