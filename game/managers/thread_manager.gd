class_name ThreadManager
extends Node
## Runs one lull at a time: lays out the threads, handles selection and cutting,
## counts down the shared timer, and releases every uncut thread at zero.
## It never spawns enemies; it emits thread_released and lets WaveManager do that.

signal lull_started(duration: float)
signal lull_ended
signal thread_released(data: SignalThreadData, spawn_position: Vector3)
signal swarm_started
signal cut_refused(thread: SignalThread, reason: StringName)
signal selection_changed(thread: SignalThread)

const REFUSED_UNCUTTABLE := &"uncuttable"
const REFUSED_COOLDOWN := &"cooldown"

@export var thread_scene: PackedScene
## Where thread nodes are parented.
@export var thread_container: Node3D
## The Stronghold. Threads start here.
@export var center: Node3D
## Used to turn screen angles ("top of the screen") into world directions.
@export var camera: Camera3D
## Distance from the Stronghold to the map edge, where groups spawn.
@export var thread_length := 18.0
@export var default_color := Color.WHITE

var _lull: LullDefinition
var _threads: Array[SignalThread] = []  # sorted clockwise from the top of the screen
var _selected := -1
var _time_left := 0.0
var _cooldown_left := 0.0


func _ready() -> void:
	get_viewport().physics_object_picking = true


func is_active() -> bool:
	return _lull != null


func get_time_left() -> float:
	return _time_left


func get_cooldown_left() -> float:
	return _cooldown_left
	
	
func get_duration() -> float:
	return _lull.duration if is_active() else 0.0


func start_lull(lull: LullDefinition) -> void:
	if is_active():
		_swarm()  # never stack two lulls
	if lull == null or lull.threads.is_empty():
		return
	_lull = lull
	_time_left = lull.duration
	_cooldown_left = 0.0
	var angles := _layout_angles(lull.threads)
	var order: Array[int] = []
	for i in lull.threads.size():
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool:
		return fposmod(angles[a], 360.0) < fposmod(angles[b], 360.0))
	for i in order:
		_spawn_thread(lull.threads[i], angles[i])
	_select(0)
	lull_started.emit(lull.duration)
	
	
## Ends the current lull without releasing anything.
func stop() -> void:
	for thread in _threads:
		thread.queue_free()
	_threads.clear()
	if is_active():
		_end_lull()


func _process(delta: float) -> void:
	if not is_active():
		return
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_time_left = maxf(_time_left - delta, 0.0)
	var urgency := 1.0 - _time_left / _lull.duration
	for thread in _threads:
		thread.set_urgency(urgency)
	if _time_left <= 0.0:
		_swarm()


func _unhandled_input(event: InputEvent) -> void:
	if not is_active():
		return
	if event.is_action_pressed("thread_next"):
		_select(_selected + 1)
	elif event.is_action_pressed("thread_prev"):
		_select(_selected - 1)
	elif event.is_action_pressed("thread_cut") and _selected >= 0:
		_try_cut(_threads[_selected])
	else:
		return
	get_viewport().set_input_as_handled()


## Screen angles in degrees (0 = top, 90 = right). Threads are spaced evenly.
## A thread with a screen angle anchors the layout; otherwise it's rotated randomly.
func _layout_angles(threads: Array[SignalThreadData]) -> Array[float]:
	var count := threads.size()
	var step := 360.0 / count
	var anchor := -1
	for i in count:
		if threads[i].use_screen_angle:
			anchor = i
			break
	var offset := threads[anchor].screen_angle if anchor >= 0 else randf() * 360.0
	var free_slots: Array[float] = []
	for slot in count:
		free_slots.append(offset + slot * step)
	if anchor >= 0:
		free_slots.remove_at(0)  # the anchor takes this slot
	free_slots.shuffle()
	var angles: Array[float] = []
	angles.resize(count)
	for i in count:
		if threads[i].use_screen_angle:
			angles[i] = threads[i].screen_angle
		else:
			angles[i] = free_slots.pop_back()
	return angles


func _screen_to_world(degrees: float) -> Vector3:
	var forward := -camera.global_basis.z
	forward.y = 0.0
	var right := camera.global_basis.x
	right.y = 0.0
	var radians := deg_to_rad(degrees)
	return (forward.normalized() * cos(radians) + right.normalized() * sin(radians)).normalized()


func _spawn_thread(data: SignalThreadData, screen_angle: float) -> void:
	var thread := thread_scene.instantiate() as SignalThread
	thread_container.add_child(thread)
	thread.global_position = center.global_position
	var color := data.enemy.thread_color if data.enemy else default_color
	thread.setup(data, _screen_to_world(screen_angle), thread_length, color)
	thread.hovered.connect(_on_thread_hovered)
	thread.clicked.connect(_on_thread_clicked)
	_threads.append(thread)


func _select(index: int) -> void:
	if _threads.is_empty():
		_selected = -1
		return
	_selected = wrapi(index, 0, _threads.size())
	for i in _threads.size():
		_threads[i].set_highlighted(i == _selected)
	selection_changed.emit(_threads[_selected])


func _try_cut(thread: SignalThread) -> void:
	if not is_active():
		return
	if not thread.data.can_cut:
		cut_refused.emit(thread, REFUSED_UNCUTTABLE)
	elif _cooldown_left > 0.0:
		cut_refused.emit(thread, REFUSED_COOLDOWN)
	else:
		_cooldown_left = _lull.cut_cooldown
		_release(thread)


func _release(thread: SignalThread) -> void:
	var index := _threads.find(thread)
	if index < 0:
		return
	_threads.remove_at(index)
	thread_released.emit(thread.data, thread.get_end_position())
	thread.queue_free()
	if _threads.is_empty():
		_end_lull()
	else:
		# Keep the selection on the next thread clockwise.
		_select(_selected - 1 if index < _selected else _selected)


func _swarm() -> void:
	swarm_started.emit()
	for thread in _threads.duplicate():
		_release(thread)


func _end_lull() -> void:
	_lull = null
	_selected = -1
	_time_left = 0.0
	_cooldown_left = 0.0
	lull_ended.emit()


func _on_thread_hovered(thread: SignalThread) -> void:
	var index := _threads.find(thread)
	if index >= 0:
		_select(index)


func _on_thread_clicked(thread: SignalThread) -> void:
	var index := _threads.find(thread)
	if index >= 0:
		_select(index)
		_try_cut(thread)
