class_name WardAura
extends Area3D
## A cultist's ward. Enemies inside take less damage while it's active.
## Doesn't stack, and skips enemies whose data has can_be_warded off.
## Put it on the enemy root (not the bobbing model). The shape is made in code.

@export_range(0.5, 30.0, 0.1, "suffix:m") var radius := 5.0
## 0.5 = warded enemies take half damage.
@export_range(0.0, 1.0, 0.05) var damage_taken := 0.5
## Off: the ward is up from spawn. On: it starts when the cultist stops near the base.
@export var activate_on_arrival := true
## Optional: a flat disc with radius 1, scaled to show the ward's range.
@export var range_visual: Node3D

var _warded: Array[BaseEnemy] = []
var _is_active := false


func _ready() -> void:
	monitorable = false
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	var shape := CollisionShape3D.new()
	shape.shape = sphere
	add_child(shape)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	tree_exiting.connect(_release_all)
	var owner_enemy := get_parent() as BaseEnemy
	if activate_on_arrival and owner_enemy:
		_set_active(false)
		owner_enemy.arrived.connect(func(_enemy: BaseEnemy) -> void: _set_active(true))
	else:
		_set_active(true)


func _set_active(value: bool) -> void:
	_is_active = value
	set_deferred("monitoring", value)  # existing overlaps get picked up once it turns on
	if range_visual == null:
		return
	range_visual.visible = value
	if value:
		# The ritual circle spreads out from the cultist.
		range_visual.scale = Vector3(0.01, 1.0, 0.01)
		create_tween().tween_property(range_visual, "scale", Vector3(radius, 1.0, radius), 0.4) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_area_entered(area: Area3D) -> void:
	if not _is_active:
		return
	var enemy := area.get_parent() as BaseEnemy
	if enemy == null or enemy == get_parent() or enemy.data == null:
		return
	if not enemy.data.can_be_warded:
		return
	enemy.add_ward(self, damage_taken)
	_warded.append(enemy)


func _on_area_exited(area: Area3D) -> void:
	var enemy := area.get_parent() as BaseEnemy
	if enemy == null or not enemy in _warded:
		return
	_warded.erase(enemy)
	enemy.remove_ward(self)


## The cultist died: lift the ward from everyone it was protecting.
func _release_all() -> void:
	for enemy: BaseEnemy in _warded:
		if is_instance_valid(enemy):
			enemy.remove_ward(self)
	_warded.clear()
