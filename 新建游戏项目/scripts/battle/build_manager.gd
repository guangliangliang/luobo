extends Node2D

signal build_spot_clicked(spot_index: int)
signal tower_placed(tower: Node2D, spot_index: int)

const TOWER_SCRIPT: GDScript = preload("res://scripts/towers/tower_base.gd")
const MAP_BOUNDS := Rect2(40.0, 40.0, 1200.0, 640.0)
const PATH_BUILD_MARGIN := 58.0
const TOWER_SPACING := 96.0
const VILLAGE_BLOCK_RADIUS := 92.0

var _build_spots: Array[Dictionary] = []
var _level_data: LevelData
var _built_towers: Dictionary = {}
var _next_spot_index: int = 0

func setup(level_data: LevelData) -> void:
	_level_data = level_data
	_build_spots.clear()
	_built_towers.clear()
	_next_spot_index = 0
	_generate_build_spots()

func get_build_spots() -> Array:
	return _build_spots

func is_spot_occupied(spot_index: int) -> bool:
	var spot: Dictionary = _get_spot_by_index(spot_index)
	if spot.is_empty():
		return true
	return bool(spot.get("occupied", false))

func occupy_spot(spot_index: int, tower: Node2D) -> void:
	var spot: Dictionary = _get_spot_by_index(spot_index)
	if spot.is_empty():
		return
	spot["occupied"] = true
	_built_towers[spot_index] = tower

func free_spot(spot_index: int) -> void:
	var spot: Dictionary = _get_spot_by_index(spot_index)
	if not spot.is_empty():
		spot["occupied"] = false
	_built_towers.erase(spot_index)

func get_tower_at_spot(spot_index: int) -> Node2D:
	return _built_towers.get(spot_index)

func get_spot_index_at_position(pos: Vector2) -> int:
	for spot in _build_spots:
		if pos.distance_to(spot.position) < TOWER_SPACING * 0.5:
			return int(spot.index)
	return -1

func can_build_on_spot(spot_index: int) -> bool:
	var spot: Dictionary = _get_spot_by_index(spot_index)
	if spot.is_empty():
		return false
	return not bool(spot.get("occupied", false))

func can_build_at_position(pos: Vector2) -> bool:
	var spot_index: int = get_spot_index_at_position(pos)
	return can_build_on_spot(spot_index)

func build_tower(spot_index: int, tower_type: String) -> Node2D:
	if not can_build_on_spot(spot_index):
		return null
	var spot: Dictionary = _get_spot_by_index(spot_index)
	if spot.is_empty():
		return null
	return build_tower_at_position(spot.position, tower_type)

func build_tower_at_position(pos: Vector2, tower_type: String) -> Node2D:
	var spot_index: int = get_spot_index_at_position(pos)
	if not can_build_on_spot(spot_index):
		return null
	var td: TowerData = GameManager.get_tower_data(tower_type)
	if not td:
		return null
	if not GameManager.spend_gold(td.cost):
		return null
	var spot: Dictionary = _get_spot_by_index(spot_index)
	pos = spot.position

	var tower: Node2D = Node2D.new()
	tower.set_script(TOWER_SCRIPT)
	tower.global_position = pos
	add_child(tower)
	tower.setup(tower_type, td)

	occupy_spot(spot_index, tower)
	AudioManager.play_sfx("build")
	tower_placed.emit(tower, spot_index)

	return tower

func _generate_build_spots() -> void:
	if _level_data == null:
		return
	var start_x: float = MAP_BOUNDS.position.x + TOWER_SPACING * 0.5
	var end_x: float = MAP_BOUNDS.end.x - TOWER_SPACING * 0.5
	var start_y: float = MAP_BOUNDS.position.y + TOWER_SPACING * 0.5
	var end_y: float = MAP_BOUNDS.end.y - TOWER_SPACING * 0.5
	var y: float = start_y
	while y <= end_y:
		var x: float = start_x
		while x <= end_x:
			var pos := Vector2(x, y)
			if _is_valid_build_position(pos):
				_build_spots.append({
					"index": _next_spot_index,
					"position": pos,
					"occupied": false,
				})
				_next_spot_index += 1
			x += TOWER_SPACING
		y += TOWER_SPACING

func _is_valid_build_position(pos: Vector2) -> bool:
	if not MAP_BOUNDS.has_point(pos):
		return false
	if _level_data == null:
		return false
	if pos.distance_to(_level_data.village_position) < VILLAGE_BLOCK_RADIUS:
		return false
	for path_points: PackedVector2Array in _level_data.path_points:
		if _distance_to_path(pos, path_points) < (_level_data.path_width * 0.5 + PATH_BUILD_MARGIN):
			return false
	return true

func _get_spot_by_index(spot_index: int) -> Dictionary:
	for spot in _build_spots:
		if int(spot.get("index", -1)) == spot_index:
			return spot
	return {}

func _distance_to_path(pos: Vector2, path_points: PackedVector2Array) -> float:
	if path_points.is_empty():
		return INF
	var closest_distance: float = INF
	if path_points.size() == 1:
		return pos.distance_to(path_points[0])
	for i in range(path_points.size() - 1):
		var distance: float = Geometry2D.get_closest_point_to_segment(pos, path_points[i], path_points[i + 1]).distance_to(pos)
		if distance < closest_distance:
			closest_distance = distance
	return closest_distance
