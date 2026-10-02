class_name WaveDefinition
extends Resource
## One wave: what spawns, how long until the next wave, and the early-call reward.

@export var groups: Array[SpawnGroup] = []
## Seconds until the next wave starts on its own.
@export_range(1.0, 300.0, 0.5, "suffix:s") var duration := 20.0
## Gold for calling the next wave before this one's timer runs out.
@export_range(0, 1000) var early_call_bonus := 3
