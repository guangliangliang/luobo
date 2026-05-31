extends Node2D

var _level_data: LevelData
var _spawner: Node
var _wave_mgr: Node
var _build_mgr: Node
var _battle_mgr: Node
var _hud: Control
var _build_menu: Control
var _tower_menu: Control
var _selected_spot: int = -1
var _map_drawer: Node2D
var _village_drawer: Node2D
var _selected_tower: Node2D = null

func _ready() -> void:
	_level_data = GameManager.get_level_data(GameManager.current_level_id)
	if not _level_data:
		return
	GameManager.start_battle(GameManager.current_level_id)
	_create_battle_scene()

func _create_battle_scene() -> void:
	_create_map()
	_create_managers()
	_create_ui()
	_connect_signals()
	_update_hud()

func _create_map() -> void:
	_map_drawer = Node2D.new()
	_map_drawer.name = "MapDrawer"
	add_child(_map_drawer)
	_draw_background()
	_draw_paths()
	_draw_build_spots()
	_draw_village()
	_draw_entrances()

func _draw_background() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = _level_data.bg_color
	bg.size = Vector2(1920, 1080)
	bg.z_index = -10
	_map_drawer.add_child(bg)

func _draw_paths() -> void:
	for path_points: PackedVector2Array in _level_data.path_points:
		var line: Line2D = Line2D.new()
		line.points = path_points
		line.width = _level_data.path_width
		line.default_color = _level_data.path_color
		line.z_index = -5
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		_map_drawer.add_child(line)
		
		var line_border: Line2D = Line2D.new()
		line_border.points = path_points
		line_border.width = _level_data.path_width + 8
		line_border.default_color = Color(0.35, 0.25, 0.15)
		line_border.z_index = -6
		line_border.joint_mode = Line2D.LINE_JOINT_ROUND
		line_border.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line_border.end_cap_mode = Line2D.LINE_CAP_ROUND
		_map_drawer.add_child(line_border)

func _draw_build_spots() -> void:
	for i in range(_level_data.build_spots.size()):
		var pos: Vector2 = _level_data.build_spots[i]
		var spot: ColorRect = ColorRect.new()
		spot.position = pos - Vector2(22, 22)
		spot.size = Vector2(44, 44)
		spot.color = Color(0.6, 0.55, 0.3, 0.5)
		spot.z_index = -3
		_map_drawer.add_child(spot)
		
		var border: ReferenceRect = ReferenceRect.new()
		border.position = pos - Vector2(22, 22)
		border.size = Vector2(44, 44)
		border.border_color = Color(0.8, 0.75, 0.4, 0.7)
		border.editor_only = false
		border.z_index = -2
		_map_drawer.add_child(border)

func _draw_village() -> void:
	_village_drawer = Node2D.new()
	_village_drawer.position = _level_data.village_position
	_village_drawer.z_index = 0
	_map_drawer.add_child(_village_drawer)
	
	var house: ColorRect = ColorRect.new()
	house.position = Vector2(-25, -30)
	house.size = Vector2(50, 35)
	house.color = Color(0.7, 0.5, 0.3)
	_village_drawer.add_child(house)
	
	var roof: Polygon2D = Polygon2D.new()
	roof.polygon = PackedVector2Array([
		Vector2(-30, -30),
		Vector2(0, -55),
		Vector2(30, -30)
	])
	roof.color = Color(0.8, 0.25, 0.2)
	_village_drawer.add_child(roof)
	
	var door: ColorRect = ColorRect.new()
	door.position = Vector2(-8, -5)
	door.size = Vector2(16, 20)
	door.color = Color(0.4, 0.25, 0.1)
	_village_drawer.add_child(door)
	
	var label: Label = Label.new()
	label.text = "村庄"
	label.position = Vector2(-20, 15)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	_village_drawer.add_child(label)

func _draw_entrances() -> void:
	for path_points: PackedVector2Array in _level_data.path_points:
		if path_points.size() > 0:
			var entrance: Label = Label.new()
			entrance.text = "入口"
			entrance.position = path_points[0] + Vector2(-15, -30)
			entrance.add_theme_font_size_override("font_size", 14)
			entrance.add_theme_color_override("font_color", Color(1, 0.6, 0.6))
			_map_drawer.add_child(entrance)

func _create_managers() -> void:
	var spawner_script: GDScript = load("res://scripts/monsters/monster_spawner.gd")
	_spawner = Node2D.new()
	_spawner.name = "MonsterSpawner"
	_spawner.set_script(spawner_script)
	_spawner.setup(_level_data)
	add_child(_spawner)
	
	var wave_script: GDScript = load("res://scripts/battle/wave_manager.gd")
	_wave_mgr = Node2D.new()
	_wave_mgr.name = "WaveManager"
	_wave_mgr.set_script(wave_script)
	_wave_mgr.setup(_level_data)
	add_child(_wave_mgr)
	
	var build_script: GDScript = load("res://scripts/battle/build_manager.gd")
	_build_mgr = Node2D.new()
	_build_mgr.name = "BuildManager"
	_build_mgr.set_script(build_script)
	_build_mgr.setup(_level_data)
	add_child(_build_mgr)
	
	var battle_script: GDScript = load("res://scripts/battle/battle_manager.gd")
	_battle_mgr = Node2D.new()
	_battle_mgr.name = "BattleManager"
	_battle_mgr.set_script(battle_script)
	_battle_mgr.setup(_level_data, _spawner, _wave_mgr, _build_mgr)
	add_child(_battle_mgr)

func _create_ui() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)
	
	var hud_script: GDScript = load("res://scripts/ui/hud.gd")
	_hud = Control.new()
	_hud.name = "HUD"
	_hud.set_script(hud_script)
	canvas.add_child(_hud)
	
	var build_menu_script: GDScript = load("res://scripts/ui/build_menu.gd")
	_build_menu = Control.new()
	_build_menu.name = "BuildMenu"
	_build_menu.set_script(build_menu_script)
	canvas.add_child(_build_menu)
	_build_menu.visible = false
	
	var tower_menu_script: GDScript = load("res://scripts/ui/tower_menu.gd")
	_tower_menu = Control.new()
	_tower_menu.name = "TowerMenu"
	_tower_menu.set_script(tower_menu_script)
	canvas.add_child(_tower_menu)
	_tower_menu.visible = false

func _connect_signals() -> void:
	_hud.start_wave_pressed.connect(_on_start_wave)
	_build_menu.tower_selected.connect(_on_build_tower)
	_build_menu.cancel_pressed.connect(_on_cancel_build)
	_tower_menu.upgrade_pressed.connect(_on_upgrade_tower)
	_tower_menu.sell_pressed.connect(_on_sell_tower)
	_tower_menu.cancel_pressed.connect(_on_cancel_tower_menu)
	_wave_mgr.wave_started.connect(_on_wave_started)
	_wave_mgr.wave_completed.connect(_on_wave_completed)
	GameManager.gold_changed.connect(_on_gold_changed)

func _on_start_wave() -> void:
	if _wave_mgr.can_start_wave():
		_wave_mgr.start_next_wave()
		_spawner.start_wave(_wave_mgr._current_wave)

func _on_wave_started(wave_index: int) -> void:
	_update_hud()

func _on_wave_completed(_wave_index: int) -> void:
	_update_hud()

func _on_build_tower(tower_type: String) -> void:
	if _selected_spot >= 0:
		_build_mgr.build_tower(_selected_spot, tower_type)
		_build_menu.hide_menu()
		_selected_spot = -1
		_update_hud()

func _on_cancel_build() -> void:
	_build_menu.hide_menu()
	_selected_spot = -1

func _on_upgrade_tower() -> void:
	var tower: Node2D = _tower_menu.get_tower()
	if tower and is_instance_valid(tower):
		tower.upgrade()
		_tower_menu._update_info()
	_update_hud()

func _on_sell_tower() -> void:
	var tower: Node2D = _tower_menu.get_tower()
	if tower and is_instance_valid(tower):
		var spot_idx: int = -1
		for idx: int in _build_mgr._built_towers:
			if _build_mgr._built_towers[idx] == tower:
				spot_idx = idx
				break
		tower.sell()
		if spot_idx >= 0:
			_build_mgr.free_spot(spot_idx)
	_selected_tower = null
	_tower_menu.hide_menu()
	_update_hud()

func _on_cancel_tower_menu() -> void:
	_hide_tower_range()
	_tower_menu.hide_menu()

func _on_gold_changed(_new_gold: int) -> void:
	if _tower_menu.visible:
		_tower_menu._update_info()
	if _build_menu.visible:
		_build_menu._update_button_states()

func _update_hud() -> void:
	if _hud:
		_hud.update_gold(GameManager.current_gold)
		_hud.update_health(GameManager.village_health)
		_hud.update_wave(_wave_mgr.get_current_wave(), _wave_mgr.get_total_waves())
		_hud.update_monster_count(_spawner.get_active_count())
		_hud.update_start_button(_wave_mgr.can_start_wave(), _wave_mgr.is_all_done())

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos: Vector2 = (event as InputEventMouseButton).position
		
		if _build_menu.visible:
			var menu_rect: Rect2 = _build_menu.get_global_rect()
			if menu_rect.has_point(click_pos):
				return
			_build_menu.hide_menu()
			_selected_spot = -1
		
		if _tower_menu.visible:
			var tower_rect: Rect2 = _tower_menu.get_global_rect()
			if tower_rect.has_point(click_pos):
				return
			_hide_tower_range()
			_tower_menu.hide_menu()
		
		for tower: Node2D in _build_mgr._built_towers.values():
			if is_instance_valid(tower) and tower.is_click_in_area(click_pos):
				_hide_tower_range()
				_selected_tower = tower
				tower.show_range(true)
				_tower_menu.show_for_tower(tower, click_pos)
				return
		
		var spot_idx: int = _build_mgr.get_spot_index_at_position(click_pos)
		if spot_idx >= 0 and not _build_mgr.is_spot_occupied(spot_idx):
			_selected_spot = spot_idx
			_build_menu.show_at(click_pos)

func _hide_tower_range() -> void:
	if _selected_tower and is_instance_valid(_selected_tower):
		_selected_tower.show_range(false)
	_selected_tower = null

func _process(_delta: float) -> void:
	if _spawner and _hud:
		_hud.update_monster_count(_spawner.get_active_count())
	
	if _wave_mgr and _spawner and _wave_mgr.is_wave_active() and _spawner.is_wave_clear():
		_wave_mgr.on_wave_monsters_cleared()
		_update_hud()
