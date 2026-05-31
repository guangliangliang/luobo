extends Node

const SAVE_PATH: String = "user://save_data.json"

var unlock_level: int = 1
var best_score: int = 0

func _ready() -> void:
	load_save()

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json: JSON = JSON.new()
	var err: Error = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return
	var data: Dictionary = json.data
	unlock_level = data.get("unlock_level", 1)
	best_score = data.get("best_score", 0)

func save_game() -> void:
	var data: Dictionary = {
		"unlock_level": unlock_level,
		"best_score": best_score
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func unlock_next_level(current_level: int) -> void:
	var next_level: int = current_level + 1
	if next_level > unlock_level:
		unlock_level = next_level
		save_game()

func update_best_score(score: int) -> void:
	if score > best_score:
		best_score = score
		save_game()
