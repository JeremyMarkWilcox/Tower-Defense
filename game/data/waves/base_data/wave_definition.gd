class_name WaveDefinition
extends Resource
## One wave: the baseline trickle, how long until the next wave, and an optional lull.

@export var groups: Array[SpawnGroup] = []
## Seconds until the next wave starts on its own.
@export_range(1.0, 300.0, 0.5, "suffix:s") var duration := 30.0
## Optional Signal Threads lull for this wave.
@export var lull: LullDefinition
## Seconds into the wave before the lull starts. Keep lull_start + the lull's
## duration under this wave's duration, or the next wave cuts the lull short.
@export_range(0.0, 300.0, 0.5, "suffix:s") var lull_start := 8.0
