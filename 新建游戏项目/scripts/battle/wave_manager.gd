extends Node2D

signal wave_started(wave_index: int)
signal wave_completed(wave_index: int)
signal all_waves_completed

var _level_data: LevelData
var _current_wave: int = -1
var _total_waves: int = 0
var _wave_active: bool = false
var _all_done: bool = false
var _auto_next_delay: float = 0.0

func setup(level_data: LevelData) -> void:
	_level_data = level_data
	_total_waves = level_data.waves.size()
	_current_wave = -1
	_wave_active = false
	_all_done = false

func start_next_wave() -> void:
	if _all_done:
		return
	_current_wave += 1
	if _current_wave >= _total_waves:
		_all_done = true
		all_waves_completed.emit()
		return
	_wave_active = true
	wave_started.emit(_current_wave)
	AudioManager.play_sfx("wave_start")

func on_wave_monsters_cleared() -> void:
	if not _wave_active:
		return
	_wave_active = false
	wave_completed.emit(_current_wave)
	if _current_wave >= _total_waves - 1:
		_all_done = true
		all_waves_completed.emit()

func get_current_wave() -> int:
	return _current_wave + 1

func get_current_wave_index() -> int:
	return _current_wave

func get_total_waves() -> int:
	return _total_waves

func is_wave_active() -> bool:
	return _wave_active

func is_all_done() -> bool:
	return _all_done

func can_start_wave() -> bool:
	return not _wave_active and not _all_done
