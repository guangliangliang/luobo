extends Node2D

const BACKGROUND_TEXTURE: Texture2D = preload("res://assets/maps/background/grass_bg.png")
const BUILD_SPOT_TEXTURE: Texture2D = preload("res://assets/maps/build_spots/build_spot_base.png")
const VILLAGE_TEXTURE: Texture2D = preload("res://assets/maps/village/village_core.png")
const HEALTH_ICON: Texture2D = preload("res://assets/ui/icons/icon_health.png")
const MONSTER_SCRIPT: GDScript = preload("res://scripts/monsters/monster_base.gd")
const TOWER_SCRIPT: GDScript = preload("res://scripts/towers/tower_base.gd")
const PROJECTILE_SCRIPT: GDScript = preload("res://scripts/towers/projectile.gd")
const MONSTER_SPAWNER_SCRIPT: GDScript = preload("res://scripts/monsters/monster_spawner.gd")
const WAVE_MANAGER_SCRIPT: GDScript = preload("res://scripts/battle/wave_manager.gd")
const BUILD_MANAGER_SCRIPT: GDScript = preload("res://scripts/battle/build_manager.gd")
const BATTLE_MANAGER_SCRIPT: GDScript = preload("res://scripts/battle/battle_manager.gd")
const HUD_SCRIPT: GDScript = preload("res://scripts/ui/hud.gd")
const BUILD_MENU_SCRIPT: GDScript = preload("res://scripts/ui/build_menu.gd")
const TOWER_MENU_SCRIPT: GDScript = preload("res://scripts/ui/tower_menu.gd")
const SETTINGS_DIALOG_SCRIPT: GDScript = preload("res://scripts/ui/settings_dialog.gd")
const LEVEL_INFO_DIALOG_SCRIPT: GDScript = preload("res://scripts/ui/level_info_dialog.gd")
const CONFIRM_EXIT_LEVEL_DIALOG_SCRIPT: GDScript = preload("res://scripts/ui/confirm_exit_level_dialog.gd")
const BUILD_SPOT_REGION := Rect2(102, 46, 822.5, 490.5)
const START_COUNTDOWN_SECONDS := 3
const START_MESSAGE_DURATION := 0.2

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
var _village_health_bar: ProgressBar
var _build_spot_sprites: Dictionary = {}
var _selected_tower: Node2D = null
var _is_paused: bool = false
var _game_started: bool = false
var _level_info_dialog: Control
var _confirm_exit_level_dialog: Control
var _suppress_tower_menu_gold_update: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	AudioManager.play_bgm("battle")
	_level_data = GameManager.get_level_data(GameManager.current_level_id)
	if not _level_data:
		return
	MONSTER_SCRIPT.prewarm_monster_types(_get_level_monster_types())
	MONSTER_SCRIPT.prewarm_combat_effects()
	TOWER_SCRIPT.prewarm_tower_textures()
	PROJECTILE_SCRIPT.prewarm_projectile_assets()
	_create_battle_scene()
	GameManager.start_battle(GameManager.current_level_id)
	_start_countdown()

func _get_level_monster_types() -> Array:
	var monster_types: Array = []
	for wave: WaveData in _level_data.waves:
		if not wave.monster_type.is_empty() and not monster_types.has(wave.monster_type):
			monster_types.append(wave.monster_type)
		if not wave.support_monster_type.is_empty() and not monster_types.has(wave.support_monster_type):
			monster_types.append(wave.support_monster_type)
	return monster_types

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

func _draw_background() -> void:
	var bg_sprite: Sprite2D = Sprite2D.new()
	var bg_texture: Texture2D = _get_level_background_texture()
	var viewport_size: Vector2 = get_viewport_rect().size
	bg_sprite.texture = bg_texture
	bg_sprite.centered = false
	bg_sprite.scale = Vector2(viewport_size.x / bg_texture.get_width(), viewport_size.y / bg_texture.get_height())
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
	var raw_village_texture: Texture2D = _get_level_village_texture()
	var village_texture: AtlasTexture = _make_atlas_texture(raw_village_texture, _get_visible_texture_region(raw_village_texture))
	var village_sprite: Sprite2D = Sprite2D.new()
	village_sprite.texture = village_texture
	village_sprite.scale = Vector2.ONE * (236.0 / village_texture.get_height())
	village_sprite.position = Vector2(0, -64)
	village_sprite.z_index = 8
	_village_drawer.add_child(village_sprite)
	_create_village_health_marker()

func _create_village_health_marker() -> void:
	var marker: PanelContainer = PanelContainer.new()
	marker.position = Vector2(-78, -230)
	marker.size = Vector2(156, 48)
	marker.custom_minimum_size = Vector2(156, 48)
	marker.z_index = 20
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_theme_stylebox_override("panel", _create_village_health_stylebox())
	_village_drawer.add_child(marker)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 7)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(box)

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)

	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(20, 20)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = HEALTH_ICON
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	_village_health_label = Label.new()
	_village_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_village_health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_village_health_label.add_theme_font_size_override("font_size", 16)
	_village_health_label.add_theme_color_override("font_color", Color(1.0, 0.93, 0.88))
	_village_health_label.add_theme_color_override("font_outline_color", Color(0.14, 0.03, 0.02))
	_village_health_label.add_theme_constant_override("outline_size", 2)
	_village_health_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_village_health_label)

	_village_health_bar = ProgressBar.new()
	_village_health_bar.custom_minimum_size = Vector2(128, 10)
	_village_health_bar.show_percentage = false
	_village_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_village_health_bar.add_theme_stylebox_override("background", _create_village_health_bar_bg_stylebox())
	_village_health_bar.add_theme_stylebox_override("fill", _create_village_health_bar_fill_stylebox())
	box.add_child(_village_health_bar)
	_update_village_health_marker()

func _create_village_health_stylebox() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.07, 0.04, 0.92)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.95, 0.62, 0.32)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	return style

func _create_village_health_bar_bg_stylebox() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.02, 0.02, 0.9)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	return style

func _create_village_health_bar_fill_stylebox() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.92, 0.18, 0.12)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	return style

func _update_village_health_marker() -> void:
	if not _village_health_label:
		return
	var max_health: int = maxi(GameManager.max_village_health, GameManager.village_health)
	_village_health_label.text = "%d/%d" % [GameManager.village_health, max_health]
	if _village_health_bar:
		_village_health_bar.max_value = max_health
		_village_health_bar.value = GameManager.village_health

func _draw_build_spots() -> void:
	_build_spot_sprites.clear()
	var spot_texture: AtlasTexture = _make_atlas_texture(BUILD_SPOT_TEXTURE, BUILD_SPOT_REGION)
	for spot: Dictionary in _build_mgr.get_build_spots():
		var spot_sprite: Sprite2D = Sprite2D.new()
		spot_sprite.texture = spot_texture
		spot_sprite.position = spot.position
		spot_sprite.scale = Vector2.ONE * (93.0 / maxf(spot_texture.get_width(), spot_texture.get_height()))
		spot_sprite.z_index = -3
		_map_drawer.add_child(spot_sprite)
		_build_spot_sprites[int(spot.index)] = spot_sprite
	_refresh_build_spot_markers()

func _make_atlas_texture(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas

func _get_level_background_texture() -> Texture2D:
	if _level_data.background_texture:
		return _level_data.background_texture
	return BACKGROUND_TEXTURE

func _get_level_village_texture() -> Texture2D:
	if _level_data.village_texture:
		return _level_data.village_texture
	return VILLAGE_TEXTURE

func _get_visible_texture_region(texture: Texture2D) -> Rect2:
	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		return Rect2(Vector2.ZERO, texture.get_size())
	if image.detect_alpha() == Image.ALPHA_NONE:
		return Rect2(Vector2.ZERO, texture.get_size())

	var width: int = image.get_width()
	var height: int = image.get_height()
	var min_x: int = width
	var min_y: int = height
	var max_x: int = -1
	var max_y: int = -1

	for y in range(height):
		for x in range(width):
			if image.get_pixel(x, y).a > 0.05:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)

	if max_x < min_x or max_y < min_y:
		return Rect2(Vector2.ZERO, texture.get_size())

	var padding: int = 4
	min_x = maxi(min_x - padding, 0)
	min_y = maxi(min_y - padding, 0)
	max_x = mini(max_x + padding, width - 1)
	max_y = mini(max_y + padding, height - 1)
	return Rect2(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func _create_managers() -> void:
	_spawner = Node2D.new()
	_spawner.name = "MonsterSpawner"
	_spawner.process_mode = Node.PROCESS_MODE_PAUSABLE
	_spawner.set_script(MONSTER_SPAWNER_SCRIPT)
	_spawner.setup(_level_data)
	add_child(_spawner)
	
	_wave_mgr = Node2D.new()
	_wave_mgr.name = "WaveManager"
	_wave_mgr.process_mode = Node.PROCESS_MODE_PAUSABLE
	_wave_mgr.set_script(WAVE_MANAGER_SCRIPT)
	_wave_mgr.setup(_level_data)
	add_child(_wave_mgr)
	
	_build_mgr = Node2D.new()
	_build_mgr.name = "BuildManager"
	_build_mgr.process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_mgr.set_script(BUILD_MANAGER_SCRIPT)
	_build_mgr.setup(_level_data)
	add_child(_build_mgr)
	
	_battle_mgr = Node2D.new()
	_battle_mgr.name = "BattleManager"
	_battle_mgr.process_mode = Node.PROCESS_MODE_PAUSABLE
	_battle_mgr.set_script(BATTLE_MANAGER_SCRIPT)
	_battle_mgr.setup(_level_data, _spawner, _wave_mgr, _build_mgr)
	add_child(_battle_mgr)

func _create_ui() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 10
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	
	_hud = Control.new()
	_hud.name = "HUD"
	_hud.set_script(HUD_SCRIPT)
	canvas.add_child(_hud)
	
	_build_menu = Control.new()
	_build_menu.name = "BuildMenu"
	_build_menu.set_script(BUILD_MENU_SCRIPT)
	canvas.add_child(_build_menu)
	_build_menu.visible = false
	
	_tower_menu = Control.new()
	_tower_menu.name = "TowerMenu"
	_tower_menu.set_script(TOWER_MENU_SCRIPT)
	canvas.add_child(_tower_menu)
	_tower_menu.visible = false
	
	_countdown_label = Label.new()
	_countdown_label.name = "CountdownLabel"
	_countdown_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_countdown_label.add_theme_font_size_override("font_size", 120)
	_countdown_label.add_theme_color_override("font_color", Color.WHITE)
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_countdown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_countdown_label)
	_countdown_label.visible = false
	
	var dialog_canvas: CanvasLayer = CanvasLayer.new()
	dialog_canvas.layer = 100
	dialog_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(dialog_canvas)
	
	_settings_dialog = Control.new()
	_settings_dialog.name = "SettingsDialog"
	_settings_dialog.set_script(SETTINGS_DIALOG_SCRIPT)
	dialog_canvas.add_child(_settings_dialog)
	_settings_dialog.visible = false
	
	_level_info_dialog = Control.new()
	_level_info_dialog.name = "LevelInfoDialog"
	_level_info_dialog.set_script(LEVEL_INFO_DIALOG_SCRIPT)
	dialog_canvas.add_child(_level_info_dialog)
	_level_info_dialog.visible = false

	_confirm_exit_level_dialog = Control.new()
	_confirm_exit_level_dialog.name = "ConfirmExitLevelDialog"
	_confirm_exit_level_dialog.set_script(CONFIRM_EXIT_LEVEL_DIALOG_SCRIPT)
	dialog_canvas.add_child(_confirm_exit_level_dialog)
	_confirm_exit_level_dialog.visible = false

func _connect_signals() -> void:
	_hud.pause_pressed.connect(_on_pause_pressed)
	_hud.settings_pressed.connect(_on_settings_pressed)
	_settings_dialog.exit_level_pressed.connect(_on_exit_level)
	_settings_dialog.level_info_pressed.connect(_on_level_info)
	_settings_dialog.restart_level_pressed.connect(_on_restart_level)
	_settings_dialog.continue_pressed.connect(_on_continue)
	_level_info_dialog.close_pressed.connect(_on_close_level_info)
	_confirm_exit_level_dialog.confirm_pressed.connect(_on_confirm_exit_level)
	_confirm_exit_level_dialog.cancel_pressed.connect(_on_cancel_exit_level)
	_build_menu.tower_selected.connect(_on_build_tower)
	_build_menu.cancel_pressed.connect(_on_cancel_build)
	_tower_menu.upgrade_pressed.connect(_on_upgrade_tower)
	_tower_menu.sell_pressed.connect(_on_sell_tower)
	_tower_menu.cancel_pressed.connect(_on_cancel_tower_menu)
	_build_mgr.tower_placed.connect(_on_tower_placed)
	_spawner.monster_count_changed.connect(_on_monster_count_changed)
	_spawner.wave_complete.connect(_on_spawner_wave_complete)
	_wave_mgr.wave_started.connect(_on_wave_started)
	_wave_mgr.wave_completed.connect(_on_wave_completed)
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.village_health_changed.connect(_on_village_health_changed)

func _on_pause_pressed() -> void:
	_toggle_pause()

func _on_settings_pressed() -> void:
	if not _is_paused:
		_toggle_pause()
	_close_context_menus()
	_settings_dialog.show_dialog(_is_paused)

func _on_exit_level() -> void:
	_confirm_exit_level_dialog.show_dialog()

func _on_confirm_exit_level() -> void:
	_confirm_exit_level_dialog.hide_dialog()
	_settings_dialog.hide_dialog()
	if _is_paused:
		_toggle_pause()
	GameManager.is_battle_active = false
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")

func _on_cancel_exit_level() -> void:
	_confirm_exit_level_dialog.hide_dialog()

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
	_countdown_count = START_COUNTDOWN_SECONDS
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
		await get_tree().create_timer(START_MESSAGE_DURATION).timeout
		_countdown_label.visible = false
		_auto_start_first_wave()

func _auto_start_first_wave() -> void:
	if _wave_mgr.can_start_wave():
		_game_started = true
		_start_next_wave()

func _on_wave_started(wave_index: int) -> void:
	_update_hud()

func _on_wave_completed(_wave_index: int) -> void:
	_update_hud()
	if _wave_mgr.can_start_wave():
		get_tree().create_timer(3.0).timeout.connect(_auto_start_next_wave)

func _auto_start_next_wave() -> void:
	if _wave_mgr.can_start_wave():
		_start_next_wave()

func _start_next_wave() -> void:
	_wave_mgr.start_next_wave()
	var wave_index: int = _wave_mgr.get_current_wave_index()
	if wave_index >= 0:
		_spawner.start_wave(wave_index)

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
		_suppress_tower_menu_gold_update = true
		tower.upgrade()
		_suppress_tower_menu_gold_update = false
		if tower.can_upgrade() and GameManager.current_gold >= tower.get_upgrade_cost():
			_tower_menu.refresh_info()
		else:
			_tower_menu.hide_menu()
			_hide_tower_range()
	_update_hud()

func _on_sell_tower() -> void:
	var tower: Node2D = _tower_menu.get_tower()
	if tower and is_instance_valid(tower):
		var spot_idx: int = _build_mgr.get_spot_index_for_tower(tower)
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

func _close_context_menus() -> void:
	if _build_menu and _build_menu.visible:
		_build_menu.hide_menu()
	_selected_build_position = Vector2.ZERO
	if _tower_menu and _tower_menu.visible:
		_tower_menu.hide_menu()
	_hide_tower_range()

func _on_gold_changed(_new_gold: int) -> void:
	if _tower_menu and _tower_menu.visible and not _suppress_tower_menu_gold_update:
		_tower_menu.refresh_info()
	if _build_menu and _build_menu.visible:
		_build_menu.refresh_button_states()

func _on_village_health_changed(_new_health: int) -> void:
	_update_village_health_marker()
	if _game_started and _new_health < GameManager.max_village_health:
		_on_monster_reach_end()

func _on_tower_placed(_tower: Node2D, _spot_index: int) -> void:
	_refresh_build_spot_markers()

func _on_monster_count_changed(count: int) -> void:
	if _hud:
		_hud.update_monster_count(count)

func _on_spawner_wave_complete() -> void:
	if _wave_mgr and _wave_mgr.is_wave_active():
		_wave_mgr.on_wave_monsters_cleared()
		_update_hud()

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

	if _is_blocking_dialog_open():
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
	
	for tower: Node2D in _build_mgr.get_built_towers():
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

func _is_blocking_dialog_open() -> bool:
	return (_settings_dialog and _settings_dialog.visible) or (_level_info_dialog and _level_info_dialog.visible) or (_confirm_exit_level_dialog and _confirm_exit_level_dialog.visible)

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

var _screen_flash: ColorRect = null

func _on_monster_reach_end() -> void:
	_village_shake()
	_village_health_bar_flash()
	_spawn_damage_popup()
	_screen_red_flash()

func _village_shake() -> void:
	if not _village_drawer:
		return
	var original_pos: Vector2 = _village_drawer.position
	var tween: Tween = _village_drawer.create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	for i in range(4):
		var offset: Vector2 = Vector2(randf_range(-6, 6), randf_range(-4, 4))
		tween.tween_property(_village_drawer, "position", original_pos + offset, 0.05)
	tween.tween_property(_village_drawer, "position", original_pos, 0.05)

func _village_health_bar_flash() -> void:
	if not _village_health_bar:
		return
	var original_style: StyleBoxFlat = _village_health_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if not original_style:
		return
	var tween: Tween = create_tween()
	var flash_style: StyleBoxFlat = original_style.duplicate()
	flash_style.bg_color = Color(1.0, 0.2, 0.2)
	_village_health_bar.add_theme_stylebox_override("fill", flash_style)
	tween.tween_callback(func(): _village_health_bar.add_theme_stylebox_override("fill", original_style)).set_delay(0.1)
	tween.tween_callback(func(): _village_health_bar.add_theme_stylebox_override("fill", flash_style)).set_delay(0.1)
	tween.tween_callback(func(): _village_health_bar.add_theme_stylebox_override("fill", original_style)).set_delay(0.1)

func _spawn_damage_popup() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 50
	add_child(canvas)
	
	var label: Label = Label.new()
	label.text = "-1"
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	label.add_theme_color_override("font_outline_color", Color(0.3, 0.05, 0.05))
	label.add_theme_constant_override("outline_size", 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	if _village_drawer:
		label.global_position = _village_drawer.global_position + Vector2(0, -120)
	
	canvas.add_child(label)
	
	var tween: Tween = label.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", label.position.y - 60, 0.6)
	tween.tween_property(label, "modulate:a", 0, 0.3)
	tween.finished.connect(canvas.queue_free)

func _screen_red_flash() -> void:
	if not _screen_flash:
		_screen_flash = ColorRect.new()
		_screen_flash.color = Color(1.0, 0.1, 0.1, 0.0)
		_screen_flash.anchors_preset = Control.PRESET_FULL_RECT
		_screen_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_screen_flash.z_index = 999
		var canvas: CanvasLayer = CanvasLayer.new()
		canvas.layer = 99
		add_child(canvas)
		canvas.add_child(_screen_flash)
	
	var tween: Tween = _screen_flash.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_screen_flash, "modulate:a", 0.25, 0.08)
	tween.tween_property(_screen_flash, "modulate:a", 0.0, 0.2)
