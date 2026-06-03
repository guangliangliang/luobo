extends Node2D

const BACKGROUND_TEXTURE: Texture2D = preload("res://assets/maps/background/grass_bg.png")
const BUILD_SPOT_TEXTURE: Texture2D = preload("res://assets/maps/build_spots/build_spot_base.png")
const VILLAGE_TEXTURE: Texture2D = preload("res://assets/maps/village/village_core.png")
const HEALTH_ICON: Texture2D = preload("res://assets/ui/icons/icon_health.png")
const BUILD_SPOT_REGION := Rect2(204, 92, 1645, 981)

var _level_data: LevelData
var _spawner: Node
var _wave_mgr: Node
var _build_mgr: Node
var _battle_mgr: Node
var _hud: Control
var _build_menu: Control
var _tower_menu: Control
var _settings_dialog: Control
var _countdown_label: Label
var _selected_build_position: Vector2 = Vector2.ZERO
var _map_drawer: Node2D
var _village_drawer: Node2D
var _village_health_label: Label
var _build_spot_sprites: Dictionary = {}
var _selected_tower: Node2D = null
var _is_paused: bool = false
var _game_started: bool = false
var _level_info_dialog: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	AudioManager.play_bgm("battle")
	_level_data = GameManager.get_level_data(GameManager.current_level_id)
	if not _level_data:
		return
	_create_battle_scene()
	GameManager.start_battle(GameManager.current_level_id)
	_start_countdown()

func _create_battle_scene() -> void:
	_create_managers()
	_create_map()
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
	var bg_sprite: Sprite2D = Sprite2D.new()
	bg_sprite.texture = BACKGROUND_TEXTURE
	bg_sprite.centered = false
	bg_sprite.scale = Vector2(1280.0 / BACKGROUND_TEXTURE.get_width(), 720.0 / BACKGROUND_TEXTURE.get_height())
	bg_sprite.z_index = -10
	_map_drawer.add_child(bg_sprite)

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

func _draw_village() -> void:
	_village_drawer = Node2D.new()
	_village_drawer.position = _level_data.village_position
	_village_drawer.z_index = 0
	_map_drawer.add_child(_village_drawer)
	var village_texture: AtlasTexture = _make_atlas_texture(VILLAGE_TEXTURE, Rect2(576, 104, 885, 901))
	var village_sprite: Sprite2D = Sprite2D.new()
	village_sprite.texture = village_texture
	village_sprite.scale = Vector2.ONE * (118.0 / village_texture.get_height())
	village_sprite.position = Vector2(0, -32)
	village_sprite.z_index = 8
	_village_drawer.add_child(village_sprite)
	_create_village_health_marker()

func _create_village_health_marker() -> void:
	var marker: PanelContainer = PanelContainer.new()
	marker.position = Vector2(-58, -126)
	marker.size = Vector2(116, 34)
	marker.custom_minimum_size = Vector2(116, 34)
	marker.z_index = 20
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_theme_stylebox_override("panel", _create_village_health_stylebox())
	_village_drawer.add_child(marker)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(22, 22)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = HEALTH_ICON
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	_village_health_label = Label.new()
	_village_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_village_health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_village_health_label.add_theme_font_size_override("font_size", 17)
	_village_health_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.88))
	_village_health_label.add_theme_color_override("font_outline_color", Color(0.16, 0.03, 0.02))
	_village_health_label.add_theme_constant_override("outline_size", 2)
	_village_health_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_village_health_label)
	_update_village_health_marker()

func _create_village_health_stylebox() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.04, 0.03, 0.88)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.95, 0.33, 0.25)
	style.shadow_color = Color(0, 0, 0, 0.38)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 2)
	return style

func _update_village_health_marker() -> void:
	if not _village_health_label:
		return
	var max_health: int = maxi(GameManager.max_village_health, GameManager.village_health)
	_village_health_label.text = "%d/%d" % [GameManager.village_health, max_health]

func _draw_entrances() -> void:
	for path_points: PackedVector2Array in _level_data.path_points:
		if path_points.size() > 0:
			var entrance: Label = Label.new()
			entrance.text = "入口"
			entrance.position = path_points[0] + Vector2(-15, -30)
			entrance.add_theme_font_size_override("font_size", 14)
			entrance.add_theme_color_override("font_color", Color(1, 0.6, 0.6))
			_map_drawer.add_child(entrance)

func _draw_build_spots() -> void:
	_build_spot_sprites.clear()
	var spot_texture: AtlasTexture = _make_atlas_texture(BUILD_SPOT_TEXTURE, BUILD_SPOT_REGION)
	for spot: Dictionary in _build_mgr.get_build_spots():
		var spot_sprite: Sprite2D = Sprite2D.new()
		spot_sprite.texture = spot_texture
		spot_sprite.position = spot.position
		spot_sprite.scale = Vector2.ONE * (62.0 / maxf(spot_texture.get_width(), spot_texture.get_height()))
		spot_sprite.z_index = -3
		_map_drawer.add_child(spot_sprite)
		_build_spot_sprites[int(spot.index)] = spot_sprite
	_refresh_build_spot_markers()

func _make_atlas_texture(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas

func _create_managers() -> void:
	var spawner_script: GDScript = load("res://scripts/monsters/monster_spawner.gd")
	_spawner = Node2D.new()
	_spawner.name = "MonsterSpawner"
	_spawner.process_mode = Node.PROCESS_MODE_PAUSABLE
	_spawner.set_script(spawner_script)
	_spawner.setup(_level_data)
	add_child(_spawner)
	
	var wave_script: GDScript = load("res://scripts/battle/wave_manager.gd")
	_wave_mgr = Node2D.new()
	_wave_mgr.name = "WaveManager"
	_wave_mgr.process_mode = Node.PROCESS_MODE_PAUSABLE
	_wave_mgr.set_script(wave_script)
	_wave_mgr.setup(_level_data)
	add_child(_wave_mgr)
	
	var build_script: GDScript = load("res://scripts/battle/build_manager.gd")
	_build_mgr = Node2D.new()
	_build_mgr.name = "BuildManager"
	_build_mgr.process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_mgr.set_script(build_script)
	_build_mgr.setup(_level_data)
	add_child(_build_mgr)
	
	var battle_script: GDScript = load("res://scripts/battle/battle_manager.gd")
	_battle_mgr = Node2D.new()
	_battle_mgr.name = "BattleManager"
	_battle_mgr.process_mode = Node.PROCESS_MODE_PAUSABLE
	_battle_mgr.set_script(battle_script)
	_battle_mgr.setup(_level_data, _spawner, _wave_mgr, _build_mgr)
	add_child(_battle_mgr)

func _create_ui() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 10
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
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
	
	var settings_dialog_script: GDScript = load("res://scripts/ui/settings_dialog.gd")
	_settings_dialog = Control.new()
	_settings_dialog.name = "SettingsDialog"
	_settings_dialog.set_script(settings_dialog_script)
	canvas.add_child(_settings_dialog)
	_settings_dialog.visible = false
	
	_countdown_label = Label.new()
	_countdown_label.name = "CountdownLabel"
	_countdown_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_countdown_label.add_theme_font_size_override("font_size", 120)
	_countdown_label.add_theme_color_override("font_color", Color.WHITE)
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_countdown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_countdown_label.z_index = 200
	canvas.add_child(_countdown_label)
	_countdown_label.visible = false
	
	var level_info_script: GDScript = load("res://scripts/ui/level_info_dialog.gd")
	_level_info_dialog = Control.new()
	_level_info_dialog.name = "LevelInfoDialog"
	_level_info_dialog.set_script(level_info_script)
	canvas.add_child(_level_info_dialog)
	_level_info_dialog.visible = false

func _connect_signals() -> void:
	_hud.pause_pressed.connect(_on_pause_pressed)
	_hud.settings_pressed.connect(_on_settings_pressed)
	_settings_dialog.exit_level_pressed.connect(_on_exit_level)
	_settings_dialog.level_info_pressed.connect(_on_level_info)
	_settings_dialog.restart_level_pressed.connect(_on_restart_level)
	_settings_dialog.continue_pressed.connect(_on_continue)
	_level_info_dialog.close_pressed.connect(_on_close_level_info)
	_build_menu.tower_selected.connect(_on_build_tower)
	_build_menu.cancel_pressed.connect(_on_cancel_build)
	_tower_menu.upgrade_pressed.connect(_on_upgrade_tower)
	_tower_menu.sell_pressed.connect(_on_sell_tower)
	_tower_menu.cancel_pressed.connect(_on_cancel_tower_menu)
	_build_mgr.tower_placed.connect(_on_tower_placed)
	_wave_mgr.wave_started.connect(_on_wave_started)
	_wave_mgr.wave_completed.connect(_on_wave_completed)
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.village_health_changed.connect(_on_village_health_changed)

func _on_pause_pressed() -> void:
	_toggle_pause()

func _on_settings_pressed() -> void:
	if not _is_paused:
		_toggle_pause()
	_settings_dialog.show_dialog(_is_paused)

func _on_exit_level() -> void:
	_settings_dialog.hide_dialog()
	if _is_paused:
		_toggle_pause()
	GameManager.is_battle_active = false
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")

func _on_level_info() -> void:
	_level_info_dialog.show_dialog()

func _on_close_level_info() -> void:
	_level_info_dialog.hide_dialog()

func _on_restart_level() -> void:
	_settings_dialog.hide_dialog()
	if _is_paused:
		_toggle_pause()
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")

func _on_continue() -> void:
	_settings_dialog.hide_dialog()
	if _is_paused:
		_toggle_pause()

func _toggle_pause() -> void:
	_is_paused = !_is_paused
	get_tree().paused = _is_paused
	_hud.update_pause_button(_is_paused)

var _countdown_timer: Timer
var _countdown_count: int = 3

func _start_countdown() -> void:
	_countdown_label.visible = true
	_countdown_count = 3
	_countdown_label.text = str(_countdown_count)
	
	_countdown_timer = Timer.new()
	_countdown_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	_countdown_timer.wait_time = 1.0
	_countdown_timer.autostart = true
	_countdown_timer.one_shot = false
	_countdown_timer.timeout.connect(_on_countdown_tick)
	add_child(_countdown_timer)

func _on_countdown_tick() -> void:
	_countdown_count -= 1
	if _countdown_count > 0:
		_countdown_label.text = str(_countdown_count)
	else:
		_countdown_label.text = "开始！"
		_countdown_timer.stop()
		_countdown_timer.queue_free()
		_countdown_timer = null
		await get_tree().create_timer(0.5).timeout
		_countdown_label.visible = false
		_auto_start_first_wave()

func _auto_start_first_wave() -> void:
	if _wave_mgr.can_start_wave():
		_game_started = true
		_wave_mgr.start_next_wave()
		_spawner.start_wave(_wave_mgr._current_wave)

func _on_wave_started(wave_index: int) -> void:
	_update_hud()

func _on_wave_completed(_wave_index: int) -> void:
	_update_hud()
	if _wave_mgr.can_start_wave():
		get_tree().create_timer(3.0).timeout.connect(_auto_start_next_wave)

func _auto_start_next_wave() -> void:
	if _wave_mgr.can_start_wave():
		_wave_mgr.start_next_wave()
		_spawner.start_wave(_wave_mgr._current_wave)

func _on_build_tower(tower_type: String) -> void:
	if _build_mgr.can_build_at_position(_selected_build_position):
		_build_mgr.build_tower_at_position(_selected_build_position, tower_type)
		_build_menu.hide_menu()
		_selected_build_position = Vector2.ZERO
		_update_hud()

func _on_cancel_build() -> void:
	_build_menu.hide_menu()
	_selected_build_position = Vector2.ZERO

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
			_refresh_build_spot_markers()
	_selected_tower = null
	_tower_menu.hide_menu()
	_update_hud()

func _on_cancel_tower_menu() -> void:
	_hide_tower_range()
	_tower_menu.hide_menu()

func _on_gold_changed(_new_gold: int) -> void:
	if _tower_menu and _tower_menu.visible:
		_tower_menu._update_info()
	if _build_menu and _build_menu.visible:
		_build_menu._update_button_states()

func _on_village_health_changed(_new_health: int) -> void:
	_update_village_health_marker()

func _on_tower_placed(_tower: Node2D, _spot_index: int) -> void:
	_refresh_build_spot_markers()

func _update_hud() -> void:
	if _hud and _wave_mgr and _spawner:
		_hud.update_gold(GameManager.current_gold)
		_hud.update_health(GameManager.village_health)
		_update_village_health_marker()
		_hud.update_wave(_wave_mgr.get_current_wave(), _wave_mgr.get_total_waves())
		_hud.update_monster_count(_spawner.get_active_count())

func _input(event: InputEvent) -> void:
	var click_pos: Vector2 = Vector2.ZERO
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click_pos = (event as InputEventMouseButton).position
	elif event is InputEventScreenTouch and event.pressed:
		click_pos = (event as InputEventScreenTouch).position
	else:
		return

	if _build_menu and _build_menu.visible:
		var menu_rect: Rect2 = _build_menu.get_global_rect()
		if menu_rect.has_point(click_pos):
			return
		_build_menu.hide_menu()
		_selected_build_position = Vector2.ZERO
	
	if _tower_menu and _tower_menu.visible:
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
	if spot_idx >= 0 and _build_mgr.is_spot_occupied(spot_idx):
		var spot_tower: Node2D = _build_mgr.get_tower_at_spot(spot_idx)
		if spot_tower and is_instance_valid(spot_tower):
			_hide_tower_range()
			_selected_tower = spot_tower
			spot_tower.show_range(true)
			_tower_menu.show_for_tower(spot_tower, click_pos)
		return

	if _build_mgr.can_build_at_position(click_pos):
		_selected_build_position = click_pos
		_build_menu.show_at(click_pos)

func _hide_tower_range() -> void:
	if _selected_tower and is_instance_valid(_selected_tower):
		_selected_tower.show_range(false)
	_selected_tower = null

func _refresh_build_spot_markers() -> void:
	if _build_mgr == null:
		return
	for spot: Dictionary in _build_mgr.get_build_spots():
		var spot_index: int = int(spot.index)
		if _build_spot_sprites.has(spot_index):
			var marker: Sprite2D = _build_spot_sprites[spot_index]
			marker.visible = not _build_mgr.is_spot_occupied(spot_index)

func _process(_delta: float) -> void:
	if _is_paused:
		return

	if _spawner and _hud:
		_hud.update_monster_count(_spawner.get_active_count())
	
	if _wave_mgr and _spawner and _wave_mgr.is_wave_active() and _spawner.is_wave_clear():
		_wave_mgr.on_wave_monsters_cleared()
		_update_hud()
