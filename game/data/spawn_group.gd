class_name SpawnGroup
extends Resource
## A batch of one enemy type inside a wave.

@export var enemy: EnemyData
@export_range(1, 200) var count := 5
@export_range(0.05, 10.0, 0.05, "suffix:s") var interval := 1.0
## Seconds after the wave starts before this group begins.
@export_range(0.0, 120.0, 0.5, "suffix:s") var start_delay := 0.0
