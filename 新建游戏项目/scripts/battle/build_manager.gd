extends Node2D

signal build_spot_clicked(spot_index: int)
signal tower_placed(tower: Node2D, spot_index: int)

const TOWER_SCRIPT: GDScript = preload("res://scripts/towers/tower_base.gd")

var _build_spots: Array[Dictionary] = []
var _level_data: LevelData
var _built_towers: Dictionary = {}

func setup(level_data: LevelData) -> void:
	_level_data = level_data
	_build_spots.clear()
	_built_towers.clear()
	for i in range(level_data.build_spots.size()):
		_build_spots.append({
			"index": i,
			"position": level_data.build_spots[i],
			"occupied": false,
		})

func get_build_spots() -> Array:
	return _build_spots

func is_spot_occupied(spot_index: int) -> bool:
	if spot_index >= _build_spots.size():
		return true
	return _build_spots[spot_index].occupied

func occupy_spot(spot_index: int, tower: Node2D) -> void:
	if spot_index < _build_spots.size():
		_build_spots[spot_index].occupied = true
		_built_towers[spot_index] = tower

func free_spot(spot_index: int) -> void:
	if spot_index < _build_spots.size():
		_build_spots[spot_index].occupied = false
		_built_towers.erase(spot_index)

func get_tower_at_spot(spot_index: int) -> Node2D:
	return _built_towers.get(spot_index)

func get_spot_index_at_position(pos: Vector2) -> int:
	for spot in _build_spots:
		if pos.distance_to(spot.position) < 30:
			return spot.index
	return -1

func build_tower(spot_index: int, tower_type: String) -> Node2D:
	if is_spot_occupied(spot_index):
		return null
	var td: TowerData = GameManager.get_tower_data(tower_type)
	if not td:
		return null
	if not GameManager.spend_gold(td.cost):
		return null
	
	var tower: Node2D = Node2D.new()
	tower.set_script(TOWER_SCRIPT)
	tower.global_position = _build_spots[spot_index].position
	add_child(tower)
	tower.setup(tower_type, td)
	
	occupy_spot(spot_index, tower)
	AudioManager.play_sfx("build")
	tower_placed.emit(tower, spot_index)
	
	return tower
