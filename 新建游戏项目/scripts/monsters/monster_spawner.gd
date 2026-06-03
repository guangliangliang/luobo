extends Node2D

signal all_monsters_spawned
signal wave_complete

const MONSTER_SCENE: PackedScene = preload("res://scenes/Monster.tscn")

var _spawn_queue: Array[Dictionary] = []
var _spawn_timer: float = 0.0
var _is_spawning: bool = false
var _active_monsters: Array[PathFollow2D] = []
var _current_wave_index: int = -1
var _path_curves: Array = []
var _level_data: LevelData
var _all_spawned_emitted: bool = false

func setup(level_data: LevelData) -> void:
	_level_data = level_data
	_build_path_curves()
	set_process(true)

func _build_path_curves() -> void:
	_path_curves.clear()
	for path_points: PackedVector2Array in _level_data.path_points:
		var curve: Curve2D = Curve2D.new()
		for point: Vector2 in path_points:
			curve.add_point(point)
		_path_curves.append(curve)

func start_wave(wave_index: int) -> void:
	if wave_index >= _level_data.waves.size():
		return
	_current_wave_index = wave_index
	var wave: WaveData = _level_data.waves[wave_index]
	_is_spawning = true
	_all_spawned_emitted = false
	_spawn_queue.clear()
	set_process(true)
	
	var path_indices: Array[int] = []
	if wave.path_index < 0 or wave.path_index >= _path_curves.size():
		for i in range(_path_curves.size()):
			path_indices.append(i)
	else:
		path_indices = [wave.path_index]

	if wave.support_monster_type != "" and wave.support_count > 0:
		var front_support_count: int = ceili(float(wave.support_count) * 0.5)
		var back_support_count: int = wave.support_count - front_support_count
		_append_spawn_entries(wave.support_monster_type, front_support_count, wave.support_spawn_interval, path_indices)
		_append_spawn_entries(wave.monster_type, wave.count, wave.spawn_interval, path_indices)
		_append_spawn_entries(wave.support_monster_type, back_support_count, wave.support_spawn_interval, path_indices)
	else:
		_append_spawn_entries(wave.monster_type, wave.count, wave.spawn_interval, path_indices)
	
	_spawn_timer = 0.0

func _append_spawn_entries(monster_type: String, count: int, interval: float, path_indices: Array[int]) -> void:
	if count <= 0 or path_indices.is_empty():
		return
	for i in range(count):
		_spawn_queue.append({
			"monster_type": monster_type,
			"path_index": path_indices[i % path_indices.size()],
			"interval": interval,
		})

func get_active_count() -> int:
	return _active_monsters.size() + _spawn_queue.size()

func get_current_wave() -> int:
	return _current_wave_index

func _process(delta: float) -> void:
	if not _is_spawning:
		return
	
	if _spawn_queue.is_empty():
		_emit_all_spawned_once()
		if _active_monsters.is_empty():
			_is_spawning = false
			wave_complete.emit()
		return
	
	_spawn_timer -= delta
	if _spawn_timer <= 0:
		var info: Dictionary = _spawn_queue.pop_front()
		_spawn_monster(info.monster_type, info.path_index)
		if _spawn_queue.size() > 0:
			_spawn_timer = _spawn_queue[0].interval
		else:
			_spawn_timer = 0
	
	if _spawn_queue.is_empty() and _active_monsters.is_empty():
		_emit_all_spawned_once()
		_is_spawning = false
		wave_complete.emit()

func _emit_all_spawned_once() -> void:
	if _all_spawned_emitted:
		return
	_all_spawned_emitted = true
	all_monsters_spawned.emit()

func _spawn_monster(monster_type: String, path_index: int) -> void:
	if path_index >= _path_curves.size():
		return
	var monster_data: MonsterData = GameManager.get_monster_data(monster_type)
	if not monster_data:
		return
	
	var path: Path2D = Path2D.new()
	path.curve = _path_curves[path_index]
	add_child(path)
	
	var follow: PathFollow2D = MONSTER_SCENE.instantiate()
	path.add_child(follow)
	
	follow.setup(monster_data, _level_data.path_points[path_index])
	
	_active_monsters.append(follow)
	follow.tree_exiting.connect(_on_monster_removed.bind(follow, path))
	follow.monster_reached_end.connect(_on_monster_reached_end.bind(follow))

func _on_monster_removed(monster: PathFollow2D, path: Path2D) -> void:
	_active_monsters.erase(monster)
	if is_instance_valid(path):
		path.queue_free()

func _on_monster_reached_end(monster: PathFollow2D) -> void:
	_active_monsters.erase(monster)

func is_wave_clear() -> bool:
	return _spawn_queue.is_empty() and _active_monsters.is_empty()

func get_all_monsters() -> Array:
	return _active_monsters
