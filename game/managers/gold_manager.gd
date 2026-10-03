class_name GoldManager
extends Node
## Owns the gold balance. Nothing else changes it.

signal gold_changed(current: int)

@export_range(0, 1000) var starting_gold := 10

var gold := 0


func reset() -> void:
	gold = starting_gold
	gold_changed.emit(gold)


func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	gold_changed.emit(gold)


func can_afford(cost: int) -> bool:
	return cost >= 0 and gold >= cost


## Spends only if the full cost is available. Returns whether it succeeded.
func try_spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	gold -= cost
	gold_changed.emit(gold)
	return true
