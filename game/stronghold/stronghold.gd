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

## The intact Stronghold model (the stronghold_base node).
@export var model: Node3D
## Shown in its place when the Stronghold falls. Same origin and scale as the intact model.
@export var destroyed_model: PackedScene
@export var hit_flash_color := Color(1.0, 0.15, 0.1, 0.6)
@export var hit_flash_time := 0.15

## How long the intact model takes to drop into the dust before the ruins replace it.
@export var collapse_time := 0.35
@export var collapse_sink := 0.8

var health := 0
var sockets: Array[TowerSocket] = []
## type * 10 + level per socket, or -1 if empty. Kept for anything that reads it.
var loadout: Array[int] = []

var _model_meshes: Array[MeshInstance3D] = []
var _flash_mat: StandardMaterial3D
var _flash_tween: Tween

var _is_destroyed := false
var _locked := false


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
		
	if model:
		for node in model.find_children("*", "MeshInstance3D", true, false):
			_model_meshes.append(node)
	_flash_mat = StandardMaterial3D.new()
	_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


func take_damage(amount: int) -> void:
	if _locked:
		return
	if Debug.stronghold_invincible:
		return
	if _is_destroyed or amount <= 0:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health > 0:
		Audio.play_sfx(hit_sound, 0.1, hit_volume_db)
		_flash_hit()
		return
	_is_destroyed = true
	Audio.play_sfx(destroyed_sound, 0.0, destroyed_volume_db)
	_spawn_destroyed_effect()
	_clear_towers()
	_collapse()
	destroyed.emit()


## Stops all further damage (used once the run is won).
func lock() -> void:
	_locked = true


## Red flash over the model that fades out quickly.
func _flash_hit() -> void:
	if _model_meshes.is_empty():
		return
	if _flash_tween:
		_flash_tween.kill()
	_flash_mat.albedo_color = hit_flash_color
	for mesh in _model_meshes:
		mesh.material_overlay = _flash_mat
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash_mat, "albedo_color:a", 0.0, hit_flash_time)
	_flash_tween.tween_callback(_clear_flash)


func _clear_flash() -> void:
	for mesh in _model_meshes:
		mesh.material_overlay = null


## Every tower stops at once, then shrinks away. Sockets stop taking clicks.
## Every tower stops at once, then each socket shrinks away with its tower.
## The ruins model has its own socket pads, so the live sockets disappear.
func _clear_towers() -> void:
	for socket in sockets:
		socket.process_mode = Node.PROCESS_MODE_DISABLED  # no more clicks, hover or shooting
		var tower := socket.tower
		var tween := create_tween()
		tween.tween_interval(randf_range(0.0, 0.25))  # a little stagger between sockets
		tween.tween_property(socket, "scale", Vector3.ONE * 0.01, 0.3) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_callback(socket.hide)
		if tower:
			tween.tween_callback(tower.queue_free)
		socket.tower = null
		socket.tower_type = -1
		socket.tower_level = -1


## The intact model shakes, then sinks and squashes into the dust; the ruins replace it.
func _collapse() -> void:
	if _flash_tween:
		_flash_tween.kill()
	_clear_flash()
	if model == null or destroyed_model == null:
		return
	var rest := model.transform  # the ruins go here, not wherever the model sank to
	var start := model.position
	var tween := create_tween()
	for i in 5:
		var jolt := Vector3(randf_range(-0.12, 0.12), 0.0, randf_range(-0.12, 0.12))
		tween.tween_property(model, "position", start + jolt, 0.04)
	tween.tween_property(model, "position:y", start.y - collapse_sink, collapse_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(model, "scale:y", model.scale.y * 0.5, collapse_time)
	tween.tween_callback(_swap_to_ruins.bind(rest))


## Hides the intact model and puts the ruins where it originally stood.
func _swap_to_ruins(rest: Transform3D) -> void:
	var ruins := destroyed_model.instantiate() as Node3D
	model.add_sibling(ruins)
	ruins.transform = rest
	model.hide()


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
