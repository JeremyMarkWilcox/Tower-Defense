class_name TowerUpgradePanel
extends TowerPanel
## Shown for a socket with a tower.
## Cannon: both path cards. Fire/Ice: only that path's card (level 2, then max).

@export var stats_label: Label
@export var fire_option: UpgradeOption
@export var ice_option: UpgradeOption


func _ready() -> void:
	super()
	fire_option.chosen.connect(_on_option_chosen)
	ice_option.chosen.connect(_on_option_chosen)


func _refresh() -> void:
	if socket == null or socket.is_empty():
		return
	var data := stronghold.towerdata
	var type := socket.tower_type
	var level := socket.tower_level
	stats_label.text = "Current damage: %d" % data.damageData[type][level]

	if type == TowerData.CANNON:
		_show_option(fire_option, 0)
		_show_option(ice_option, 0)
		return

	# On a path: only that path's card stays.
	fire_option.visible = type == TowerData.FIRE
	ice_option.visible = type == TowerData.ICE
	var option := fire_option if type == TowerData.FIRE else ice_option
	if level >= data.max_level(type):
		option.show_max(level)
	else:
		_show_option(option, level + 1)


func _show_option(option: UpgradeOption, next_level: int) -> void:
	option.visible = true
	var cost: int = stronghold.towerdata.costData[option.tower_type][next_level]
	option.show_level(next_level, cost, gold_manager.can_afford(cost))


## Cannon -> Fire 1 / Ice 1, or Fire/Ice 1 -> 2.
func _on_option_chosen(type: int) -> void:
	if socket == null or socket.is_empty():
		return
	var data := stronghold.towerdata
	var current := socket.tower_type
	if current != TowerData.CANNON and current != type:
		return  # already on the other path
	var next := 0 if current == TowerData.CANNON else socket.tower_level + 1
	if next > data.max_level(type):
		return
	if gold_manager.try_spend(data.costData[type][next]):
		stronghold.build_tower(socket, type, next)
		_refresh()  # stays open showing the next step
