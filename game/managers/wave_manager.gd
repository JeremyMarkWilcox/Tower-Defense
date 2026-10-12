class_name WaveManager
extends Node
## Runs the baseline trickle on a timer and hands each wave's lull to ThreadManager.
## The only place enemies are spawned, including groups released by Signal Threads.
## Never waits for an empty battlefield. Uses its own clock, so pause and game speed work.

signal wave_started(wave_number: int, total_waves: int)
signal enemy_killed(bounty: int)
signal enemy_reached_stronghold(damage: int)
signal lull_requested(lull: LullDefinition)
signal boss_defeated
signal stronghold_attacked(damage: int)

@export var waves: Array[WaveDefinition] = []
@export var enemy_container: Node3D
@export var stronghold: Stronghold
## Match ThreadManager's thread_length so both spawn at the map edge.
@export var spawn_radius := 18.0
## Used to spawn the trickle just off-screen. Leave empty to use Spawn Radius.
@export var camera: Camera3D
## How far beyond the screen edge the trickle appears.
@export var offscreen_margin := 2.0
## Roughly the Stronghold's footprint radius. Enemies stop this far plus their attack range from its center.
@export var stronghold_radius := 1.5
## Random spread around a thread's end so a group doesn't stack on one spot.
@export var group_spread := 0.8

var current_wave := -1  # index into waves; -1 before the first wave

var _is_running := false
var _run_clock := 0.0
var _wave_time_left := 0.0
# { "time": float, "enemy": EnemyData, "position": Vector3 or null for the ring }
var _pending: Array[Dictionary] = []
var _pending_lull: LullDefinition
var _lull_time := 0.0
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


## Spawns a group at a fixed point. Signal Threads use this through GameManager.
func spawn_group(enemy_data: EnemyData, count: int, interval: float, at: Vector3) -> void:
	if not _is_running or enemy_data == null:
		return
	for i in count:
		_pending.append({"time": _run_clock + i * interval, "enemy": enemy_data, "position": at})
	_sort_pending()


func _process(delta: float) -> void:
	if not _is_running:
		return
	_run_clock += delta
	while not _pending.is_empty() and float(_pending[0]["time"]) <= _run_clock:
		var entry: Dictionary = _pending.pop_front()
		_spawn(entry["enemy"] as EnemyData, entry["position"])
	if _pending_lull and _run_clock >= _lull_time:
		var lull := _pending_lull
		_pending_lull = null
		lull_requested.emit(lull)
	if has_next_wave():
		_wave_time_left -= delta
		if _wave_time_left <= 0.0:
			_start_wave(current_wave + 1)


func _start_wave(index: int) -> void:
	current_wave = index
	var wave := waves[index]
	_wave_time_left = wave.duration
	for group in wave.groups:
		if group == null or group.enemy == null:
			continue
		for i in group.count:
			_pending.append({
				"time": _run_clock + group.start_delay + i * group.interval,
				"enemy": group.enemy,
				"position": null,
			})
	_sort_pending()
	_pending_lull = wave.lull
	_lull_time = _run_clock + wave.lull_start
	wave_started.emit(index + 1, waves.size())


func _sort_pending() -> void:
	_pending.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["time"]) < float(b["time"]))


func _spawn(enemy_data: EnemyData, at: Variant) -> void:
	if enemy_data.scene == null:
		push_warning("WaveManager: %s has no scene" % enemy_data.display_name)
		return
	var enemy := enemy_data.scene.instantiate() as BaseEnemy
	if enemy == null:
		push_error("WaveManager: %s scene root is not a BaseEnemy" % enemy_data.display_name)
		return
	var center := stronghold.global_position
	var spawn_position: Vector3
	if at == null:
		# Baseline trickle: just off-screen in a random direction.
		var angle := randf() * TAU
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		var distance := spawn_radius
		if camera:
			distance = ScreenEdge.distance(camera, center, dir, spawn_radius) + offscreen_margin
		spawn_position = center + dir * distance
	else:
		# Signal Thread group: at the thread's end, slightly spread out.
		var spot: Vector3 = at
		spawn_position = spot + Vector3(randf_range(-group_spread, group_spread), 0.0,
				randf_range(-group_spread, group_spread))
	enemy_container.add_child(enemy)
	enemy.global_position = spawn_position
	enemy.setup(enemy_data, center, stronghold_radius)
	enemy.died.connect(_on_enemy_died)
	enemy.attacked.connect(_on_enemy_attacked)
	_alive.append(enemy)


func _on_enemy_died(enemy: BaseEnemy) -> void:
	_alive.erase(enemy)
	enemy_killed.emit(enemy.data.bounty)
	if enemy.data.is_boss:
		boss_defeated.emit()


func _on_enemy_attacked(_enemy: BaseEnemy, damage: int) -> void:
	stronghold_attacked.emit(damage)

func _on_enemy_reached_stronghold(enemy: BaseEnemy) -> void:
	_alive.erase(enemy)
	enemy_reached_stronghold.emit(enemy.data.stronghold_damage)


func _unhandled_input(event: InputEvent) -> void:
	# Debug only: K damages every enemy by 10 until towers exist.
	if OS.is_debug_build() and event is InputEventKey and event.is_pressed() \
			and not event.is_echo() and (event as InputEventKey).keycode == KEY_K:
		for enemy: BaseEnemy in _alive.duplicate():
			(enemy as BaseEnemy).take_damage(10)
