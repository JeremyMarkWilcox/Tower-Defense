class_name EnemyData
extends Resource
## Stats for one enemy type. Make one .tres per type.

@export var display_name := "Enemy"
## The enemy scene to spawn. WaveManager hands this data to it on spawn,
## so the scene itself never stores an EnemyData (avoids a circular reference).
@export var scene: PackedScene
@export_range(0.1, 20.0, 0.1, "suffix:m/s") var move_speed := 2.0
@export_range(1, 10000) var max_health := 10
@export_range(0, 1000) var stronghold_damage := 1
@export_range(0, 1000) var bounty := 1
## Color of Signal Threads that hold this enemy type.
@export var thread_color := Color.WHITE
## Killing a boss wins the run.
@export var is_boss := false
