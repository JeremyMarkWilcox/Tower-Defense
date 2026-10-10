class_name LullDefinition
extends Resource
## One lull: the threads on offer, how long the player has, and the cut cooldown.
## Threads without a screen angle spread evenly, rotated randomly each lull.

@export var threads: Array[SignalThreadData] = []
@export_range(1.0, 120.0, 0.5, "suffix:s") var duration := 15.0
@export_range(0.0, 10.0, 0.1, "suffix:s") var cut_cooldown := 2.0
