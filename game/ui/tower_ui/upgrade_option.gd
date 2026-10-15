class_name UpgradeOption
extends VBoxContainer
## One upgrade path card (Fire or Ice): portrait, name, description, and its button.

signal chosen(tower_type: int)

@export_enum("Cannon", "Fire", "Ice") var tower_type: int = TowerData.FIRE
@export var portrait: TextureRect
@export var name_label: Label
@export var description_label: Label
@export var button: Button

@export_group("Level 1")
@export var level_1_icon: Texture2D
@export var level_1_name: String = "Fire Tower"
@export_multiline var level_1_description: String = ""

@export_group("Level 2")
@export var level_2_icon: Texture2D
@export var level_2_name: String = "Fire Tower II"
@export_multiline var level_2_description: String = ""


func _ready() -> void:
	button.pressed.connect(func() -> void: chosen.emit(tower_type))


## Shows what buying `level` (0 = level 1, 1 = level 2) gives you.
func show_level(level: int, cost: int, can_afford: bool) -> void:
	_fill(level)
	button.text = "Upgrade - %d" % cost
	button.disabled = not can_afford
	button.theme_type_variation = &"" if can_afford else &"UnaffordableButton"


## The tower is already at its last level.
func show_max(level: int) -> void:
	_fill(level)
	button.text = "Max Level"
	button.disabled = true
	button.theme_type_variation = &""


func _fill(level: int) -> void:
	var is_two := level >= 1
	portrait.texture = level_2_icon if is_two else level_1_icon
	name_label.text = level_2_name if is_two else level_1_name
	description_label.text = level_2_description if is_two else level_1_description
