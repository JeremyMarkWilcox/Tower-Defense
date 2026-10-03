class_name BaseEnemy
extends Node3D
## Walks straight to the Stronghold. Reports death or arrival once, then frees itself.

signal died(enemy: BaseEnemy)
signal reached_stronghold(enemy: BaseEnemy)

var data: EnemyData
var health := 0

var _target := Vector3.ZERO
var _arrive_radius := 1.5
var _is_finished := false


## Called by WaveManager right after spawning.
func setup(enemy_data: EnemyData, target: Vector3, arrive_radius: float) -> void:
	data = enemy_data
	health = data.max_health
	_target = target
	_arrive_radius = arrive_radius


func _physics_process(delta: float) -> void:
	if _is_finished or data == null:
		return
	var to_target := _target - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	if distance <= _arrive_radius:
		_is_finished = true
		reached_stronghold.emit(self)
		queue_free()
		return
	var direction := to_target / distance
	global_position += direction * data.move_speed * delta
	look_at(global_position + direction, Vector3.UP)


func take_damage(amount: int) -> void:
	if _is_finished:
		return
	health -= amount
	if health <= 0:
		_is_finished = true
		died.emit(self)
		queue_free()
