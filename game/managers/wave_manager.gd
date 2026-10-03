class_name WaveManager
extends Node
## Spawns waves on a timer. Never waits for an empty battlefield.
## Uses its own clock in _process, so pause and game speed both just work.

signal wave_started(wave_number: int, total_waves: int)
signal enemy_killed(bounty: int)
signal enemy_reached_stronghold(damage: int)
signal early_call_rewarded(bonus: int)
signal boss_defeated


@export var waves: Array[WaveDefinition] = []
@export var enemy_container: Node3D
@export var stronghold: Stronghold
@export var spawn_radius := 18.0
@export var arrive_radius := 1.5

var current_wave := -1  # index into waves; -1 before the first wave

var _is_running := false
var _run_clock := 0.0
var _wave_time_left := 0.0
var _pending: Array[Dictionary] = []  # { "time": float, "enemy": EnemyData }, sorted by time
var _alive: Array[BaseEnemy] = []


func start() -> void:
	if waves.is_empty():
		push_warning("WaveManager: no waves assigned")
		return
	_is_running = true
	_start_wave(0)


func stop() -> void:
	_is_running = false


func has_next_wave() -> bool:
	return current_wave + 1 < waves.size()


func get_time_until_next_wave() -> float:
	return _wave_time_left if has_next_wave() else 0.0


## Starts the next wave now and pays the current wave's early-call bonus.
func call_next_wave() -> void:
	if not _is_running or not has_next_wave():
		return
	var bonus := waves[current_wave].early_call_bonus
	_start_wave(current_wave + 1)
	if bonus > 0:
		early_call_rewarded.emit(bonus)


func _process(delta: float) -> void:
	if not _is_running:
		return
	_run_clock += delta
	while not _pending.is_empty() and float(_pending[0]["time"]) <= _run_clock:
		var entry: Dictionary = _pending.pop_front()
		_spawn(entry["enemy"] as EnemyData)
	if has_next_wave():
		_wave_time_left -= delta
		if _wave_time_left <= 0.0:
			_start_wave(current_wave + 1)


func _start_wave(index: int) -> void:
	current_wave = index
	var wave := waves[index]
	_wave_time_left = wave.duration
	# Spawn times are on the run clock, so an early call never cancels
	# spawns still pending from the previous wave.
	for group in wave.groups:
		if group == null or group.enemy == null:
			continue
		for i in group.count:
			_pending.append({
				"time": _run_clock + group.start_delay + i * group.interval,
				"enemy": group.enemy,
			})
	_pending.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["time"]) < float(b["time"]))
	wave_started.emit(index + 1, waves.size())


func _spawn(enemy_data: EnemyData) -> void:
	if enemy_data.scene == null:
		push_warning("WaveManager: %s has no scene" % enemy_data.display_name)
		return
	var enemy := enemy_data.scene.instantiate() as BaseEnemy
	if enemy == null:
		push_error("WaveManager: %s scene root is not a BaseEnemy" % enemy_data.display_name)
		return
	var center := stronghold.global_position
	var angle := randf() * TAU
	enemy_container.add_child(enemy)
	enemy.global_position = center + Vector3(cos(angle), 0.0, sin(angle)) * spawn_radius
	enemy.setup(enemy_data, center, arrive_radius)
	enemy.died.connect(_on_enemy_died)
	enemy.reached_stronghold.connect(_on_enemy_reached_stronghold)
	_alive.append(enemy)


func _on_enemy_died(enemy: BaseEnemy) -> void:
	_alive.erase(enemy)
	enemy_killed.emit(enemy.data.bounty)
	if enemy.data.is_boss:
		boss_defeated.emit()


func _on_enemy_reached_stronghold(enemy: BaseEnemy) -> void:
	_alive.erase(enemy)
	enemy_reached_stronghold.emit(enemy.data.stronghold_damage)


func _unhandled_input(event: InputEvent) -> void:
	# Debug only: K damages every enemy by 10 until towers exist.
	if OS.is_debug_build() and event is InputEventKey and event.is_pressed() \
			and not event.is_echo() and (event as InputEventKey).keycode == KEY_K:
		for enemy in _alive.duplicate():
			(enemy as BaseEnemy).take_damage(10)
