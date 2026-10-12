class_name WaveDefinition
extends Resource
## One wave: the baseline trickle, how long until the next wave, and an optional lull.

@export var groups: Array[SpawnGroup] = []
## Optional Signal Threads lull for this wave.
@export var lull: LullDefinition
## Seconds into the wave before the lull starts. Keep lull_start + the lull's
## Seconds into the wave before the lull starts.
@export_range(0.0, 300.0, 0.5, "suffix:s") var lull_start := 8.0
