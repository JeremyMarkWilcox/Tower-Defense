class_name TowerUpgradePanel
extends TowerPanel
## Shown for a socket with a tower.
## Cannon: choose the Fire or Ice path. Fire/Ice level 1: upgrade to level 2. Level 2: max.

@export var title_label: Label
@export var stats_label: Label
## Fire/Ice level 1 -> level 2.
@export var upgrade_button: Button
## Shown only on a Cannon: the two path choices.
@export var fire_button: Button
@export var ice_button: Button
@export var fire_2_icon: Texture2D
@export var ice_2_icon: Texture2D
@export var tower_names: Array[String] = ["Cannon", "Fire", "Ice"]


func _ready() -> void:
	super()
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	fire_button.pressed.connect(_on_path_pressed.bind(TowerData.FIRE))
	ice_button.pressed.connect(_on_path_pressed.bind(TowerData.ICE))


func _refresh() -> void:
	if socket == null or socket.is_empty():
		return
	var data := stronghold.towerdata
	var type := socket.tower_type
	var level := socket.tower_level
	var is_cannon := type == TowerData.CANNON

	fire_button.visible = is_cannon
	ice_button.visible = is_cannon
	upgrade_button.visible = not is_cannon

	if is_cannon:
		title_label.text = tower_names[type]
		stats_label.text = "Damage %d\nChoose a path:" % data.damageData[type][level]
		_show_path_button(fire_button, TowerData.FIRE)
		_show_path_button(ice_button, TowerData.ICE)
		return

	title_label.text = "%s - Level %d" % [tower_names[type], level + 1]
	upgrade_button.icon = fire_2_icon if type == TowerData.FIRE else ice_2_icon
	if level >= data.max_level(type):
		stats_label.text = "Damage %d" % data.damageData[type][level]
		upgrade_button.text = "Max Level"
		upgrade_button.disabled = true
		return

	stats_label.text = "Damage %d -> %d" % [data.damageData[type][level], data.damageData[type][level + 1]]
	var cost: int = data.costData[type][level + 1]
	upgrade_button.text = "Upgrade - %d" % cost
	upgrade_button.disabled = not gold_manager.can_afford(cost)


func _show_path_button(button: Button, type: int) -> void:
	var cost: int = stronghold.towerdata.costData[type][0]
	button.text = "%s - %d" % [tower_names[type], cost]
	button.disabled = not gold_manager.can_afford(cost)


## Cannon -> Fire 1 or Ice 1.
func _on_path_pressed(type: int) -> void:
	if socket == null or socket.tower_type != TowerData.CANNON:
		return
	if gold_manager.try_spend(stronghold.towerdata.costData[type][0]):
		stronghold.build_tower(socket, type, 0)
		_refresh()  # stay open, now showing that path's upgrade


## Fire/Ice level 1 -> level 2.
func _on_upgrade_pressed() -> void:
	if socket == null or socket.is_empty() or socket.tower_type == TowerData.CANNON:
		return
	var type := socket.tower_type
	var next := socket.tower_level + 1
	if next > stronghold.towerdata.max_level(type):
		return
	if gold_manager.try_spend(stronghold.towerdata.costData[type][next]):
		stronghold.build_tower(socket, type, next)
		_refresh()
