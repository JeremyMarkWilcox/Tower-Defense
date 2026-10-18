class_name TowerData
extends Resource
## Stats and assets for every tower. Every socket builds a Cannon; the Cannon upgrades
## into Fire or Ice level 1, which upgrades once more to level 2.
## costData[type][level] is the price of reaching that tower (building or upgrading into it).

const CANNON := 0
const FIRE := 1
const ICE := 2

@export_group("Models")
@export var basiclvl_1: PackedScene
@export var firelvl_1: PackedScene
@export var firelvl_2: PackedScene
@export var firelvl_3: PackedScene
@export var icelvl_1: PackedScene
@export var icelvl_2: PackedScene
@export var icelvl_3: PackedScene

@export_group("Hit Effects")
@export var cannon_hit: PackedScene
@export var fire_hit: PackedScene
@export var ice_hit: PackedScene
## Visual for Ice 2's area slow, sized to slow_radius.
@export var frost_nova: PackedScene

@export_group("Bullets")
@export var cannon_bullet: PackedScene
@export var fire_bullet: PackedScene
@export var ice_bullet: PackedScene

@export_group("Shot Effects")
@export var cannon_shoot: PackedScene
@export var ice_shoot: PackedScene
@export var fire_shoot: PackedScene

@export_group("Shot Sounds")
@export var cannon_shot_sound: AudioStream
@export var fire_shot_sound: AudioStream
@export var ice_shot_sound: AudioStream
## Shots play constantly, so they sit quieter than other sounds.
@export var shot_volume_db := -8.0

@export_group("Hit Sounds")
## Leave a slot empty for no hit sound (e.g. Fire and Ice 1).
@export var cannon_hit_sound: AudioStream
@export var fire_hit_sound: AudioStream
@export var ice_hit_sound: AudioStream
@export var hit_volume_db := -10.0

# One row per type; one entry per level on that path.
var costData: Array[Array] = [
	[10],      # Cannon: build
	[15, 75, 100],  # Fire: Cannon -> Fire 1, Fire 1 -> Fire 2
	[10, 50, 75],  # Ice:  Cannon -> Ice 1,  Ice 1 -> Ice 2
]

var damageData: Array[Array] = [
	[2],
	[4, 5, 6],
	[5, 7, 8],
]

## Seconds between shots (lower = faster).
var fireRateData: Array[Array] = [
	[0.8],
	[0.6, .9, 1.0],
	[1.5, 1.75, 2],
]

var bulletSpeedData: Array[Array] = [
	[20],
	[25, 35, 40],
	[12, 12, 12],
]


@export_group("Fire")
## Seconds an enemy keeps burning after a hit.
@export var burn_duration: Array[float] = [3.0, 4.0, 5.0]
## Damage per burn tick (2 ticks per second).
@export var burn_tick_damage: Array[float] = [1.0, 2.0, 3.0]
## Bullets per volley. Fire 2 fires a 3-shot burst like a gatling gun.
@export var burst_shots: Array[int] = [1, 30, 60] #Doesn't work?
## Seconds between the bullets in one burst.
@export var burst_gap := 0.08

@export_group("Ice")
## Seconds an enemy stays slowed.
@export var slow_duration: Array[float] = [2.0, 2.5, 3.0]
## How much slower: 0.4 = 40% slower.
@export var slow_amount: Array[float] = [0.35, 0.5, .6]
## Ice 2 slows everything within this radius of the hit. 0 = only the target.
@export var slow_radius: Array[float] = [0.0, 3.0, 8.0]


## The highest level index on a type's path (Cannon 0, Fire/Ice 1).
func max_level(type: int) -> int:
	return costData[type].size() - 1


func get_mesh(type: int, level: int) -> PackedScene:
	var meshes := [
		[basiclvl_1],
		[firelvl_1, firelvl_2, firelvl_3],
		[icelvl_1, icelvl_2, icelvl_3],
	]
	# Until a level 2 model exists, fall back to level 1 so the game still runs.
	var mesh: PackedScene = meshes[type][level]
	return mesh if mesh else meshes[type][0]


func get_hit_particle(type: int, _level: int) -> PackedScene:
	return [cannon_hit, fire_hit, ice_hit][type]


func get_shot_particle(type: int, _level: int) -> PackedScene:
	var scene: PackedScene
	match type:
		FIRE:
			scene = fire_shoot
		ICE:
			scene = ice_shoot
		_:
			scene = cannon_shoot
	return scene if scene else cannon_shoot  # fall back if an export is empty


func get_shot_sound(type: int) -> AudioStream:
	match type:
		FIRE:
			return fire_shot_sound
		ICE:
			return ice_shot_sound
		_:
			return cannon_shot_sound
			
			
func get_hit_sound(type: int) -> AudioStream:
	match type:
		FIRE:
			return fire_hit_sound
		ICE:
			return ice_hit_sound
		_:
			return cannon_hit_sound


func get_bullet_mesh(type: int, _level: int) -> PackedScene:
	return [cannon_bullet, fire_bullet, ice_bullet][type]
