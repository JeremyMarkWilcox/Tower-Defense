class_name SignalThreadData
extends Resource
## One thread: a single group of one enemy type, waiting in the dark.

@export var enemy: EnemyData
@export_range(1, 50) var count := 3
## Seconds between each enemy in the group once the thread is released.
@export_range(0.05, 5.0, 0.05, "suffix:s") var spawn_interval := 0.4
## Off for the boss: trying to cut it plays the refusal feedback instead.
@export var can_cut := true

@export_group("Direction")
## Aim this thread instead of letting it auto-spread with the others.
@export var use_screen_angle := false
## 0 = straight up the screen, 90 = right, -90 = left. Relative to the camera.
@export_range(-180.0, 180.0, 1.0, "suffix:°") var screen_angle := 0.0
