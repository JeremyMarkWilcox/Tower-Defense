class_name LullDefinition
extends Resource
## One lull: the threads on offer, how long the player has, and the cut cooldown.
## Threads without a screen angle spread evenly, rotated randomly each lull.

@export var threads: Array[SignalThreadData] = []
@export_range(1.0, 120.0, 0.5, "suffix:s") var duration := 15.0
@export_range(0.0, 10.0, 0.1, "suffix:s") var cut_cooldown := 2.0
## Degrees per second all threads rotate around the Stronghold. 0 = no spin (e.g. tutorial and boss lulls).
## Negative spins the other way.
@export_range(-90.0, 90.0, 1.0, "suffix:°/s") var spin_speed := 0.0
