extends Node2D

var _level_data: LevelData
var _spawner: Node
var _wave_mgr: Node
var _build_mgr: Node
var _result_shown: bool = false

func setup(level_data: LevelData, spawner: Node, wave_mgr: Node, build_mgr: Node) -> void:
	_level_data = level_data
	_spawner = spawner
	_wave_mgr = wave_mgr
	_build_mgr = build_mgr
	
	_wave_mgr.all_waves_completed.connect(_on_all_waves_completed)
	GameManager.game_lost.connect(_on_game_lost)

func _on_all_waves_completed() -> void:
	if _result_shown:
		return
	GameManager.is_battle_active = false
	AudioManager.play_sfx("victory")
	await get_tree().create_timer(1.5).timeout
	_show_result(true)

func _on_game_lost() -> void:
	if _result_shown:
		return
	AudioManager.play_sfx("defeat")
	await get_tree().create_timer(1.5).timeout
	_show_result(false)

func _show_result(won: bool) -> void:
	_result_shown = true
	if won:
		SaveManager.unlock_next_level(_level_data.level_id)
	SaveManager.update_best_score(GameManager.kill_count * 10 + GameManager.total_gold_earned)
	GameManager.set_result(won, _level_data.level_id)
	GameManager.is_battle_active = false
	get_tree().change_scene_to_file("res://scenes/Result.tscn")
