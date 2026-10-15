class_name TowerBuildPanel
extends TowerPanel
## Shown for an empty socket: one Build button per tower type.

@export var title_label: Label
## Same order as TowerData's rows: Cannon, Fire, Ice.
@export var build_buttons: Array[Button] = []


func _ready() -> void:
	super()
	for i in build_buttons.size():
		build_buttons[i].pressed.connect(_on_build_pressed.bind(i))


func _refresh() -> void:
	for i in build_buttons.size():
		var cost: int = stronghold.towerdata.costData[i][0]
		var can_afford := gold_manager.can_afford(cost)
		build_buttons[i].text = "Build - %d" % cost
		build_buttons[i].disabled = not can_afford
		build_buttons[i].theme_type_variation = &"" if can_afford else &"UnaffordableButton"


func _on_build_pressed(type: int) -> void:
	if socket == null or not socket.is_empty():
		return
	if gold_manager.try_spend(stronghold.towerdata.costData[type][0]):
		stronghold.build_tower(socket, type, 0)
		close()
