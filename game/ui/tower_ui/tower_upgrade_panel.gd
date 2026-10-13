class_name TowerUpgradePanel
extends TowerPanel
## Shown for a socket with a tower: its level, damage now and next, and an Upgrade button.

@export var title_label: Label
@export var stats_label: Label
@export var upgrade_button: Button
@export var tower_names: Array[String] = ["Cannon", "Fire", "Ice"]


func _ready() -> void:
	super()
	upgrade_button.pressed.connect(_on_upgrade_pressed)


func _refresh() -> void:
	if socket == null or socket.is_empty():
		return
	var data := stronghold.towerdata
	var type := socket.tower_type
	var level := socket.tower_level
	var max_level: int = data.costData[type].size() - 1
	title_label.text = "%s - Level %d" % [tower_names[type], level + 1]

	if level >= max_level:
		stats_label.text = "Damage %d" % data.damageData[type][level]
		upgrade_button.text = "Max Level"
		upgrade_button.disabled = true
		return

	stats_label.text = "Damage %d -> %d" % [data.damageData[type][level], data.damageData[type][level + 1]]
	var cost: int = data.costData[type][level + 1]
	upgrade_button.text = "Upgrade - %d" % cost
	upgrade_button.disabled = not gold_manager.can_afford(cost)


func _on_upgrade_pressed() -> void:
	if socket == null or socket.is_empty():
		return
	var type := socket.tower_type
	var next := socket.tower_level + 1
	if gold_manager.try_spend(stronghold.towerdata.costData[type][next]):
		stronghold.build_tower(socket, type, next)
		_refresh()  # stay open to show the new level
