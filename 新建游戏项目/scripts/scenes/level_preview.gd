extends Control

const MENU_BG: Texture2D = preload("res://assets/ui/menu/menu_bg_village.png")
const BACK_BUTTON_TEXTURE: Texture2D = preload("res://assets/ui/icons/icon_back_turn.svg")
const ICON_PLAY: Texture2D = preload("res://assets/ui/icons/icon_play.svg")
const BUTTON_NORMAL: Texture2D = preload("res://assets/ui/buttons/button_menu_normal.png")
const BUTTON_HOVER: Texture2D = preload("res://assets/ui/buttons/button_menu_hover.png")
const BUTTON_PRESSED: Texture2D = preload("res://assets/ui/buttons/button_menu_pressed.png")
const BUTTON_REGION: Rect2 = Rect2(72.5, 175, 622.5, 144.5)
const TOWER_TYPES: Array[String] = ["arrow", "cannon", "ice"]
const MAP_SOURCE_SIZE: Vector2 = Vector2(1280, 720)
const CONTENT_MAX_WIDTH: float = 1180.0
const CONTENT_MARGIN: float = 24.0
const BACK_BUTTON_SIZE: Vector2 = Vector2(68, 68)
const BACK_BUTTON_MARGIN: float = 22.0

var _level_data: LevelData

func _ready() -> void:
	AudioManager.play_bgm("menu")
	_level_data = GameManager.get_level_data(GameManager.current_level_id)
	if not _level_data:
		get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")
		return
	_setup_ui()

func _setup_ui() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	var viewport_size: Vector2 = get_viewport_rect().size
	var horizontal_margin: float = maxf(CONTENT_MARGIN, (viewport_size.x - CONTENT_MAX_WIDTH) * 0.5)

	var bg: TextureRect = TextureRect.new()
	bg.texture = MENU_BG
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0, 0, 0, 0.34)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var root: VBoxContainer = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = horizontal_margin
	root.offset_top = 18
	root.offset_right = -horizontal_margin
	root.offset_bottom = -18
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var header: VBoxContainer = VBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 2)
	root.add_child(header)

	var title: Label = Label.new()
	title.text = "第%d关  %s" % [_level_data.level_id, _level_data.level_name]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.0, 0.90, 0.46))
	title.add_theme_color_override("font_outline_color", Color(0.24, 0.08, 0.02))
	title.add_theme_constant_override("outline_size", 5)
	header.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "作战准备"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.93, 0.82, 0.62))
	subtitle.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.02))
	subtitle.add_theme_constant_override("outline_size", 3)
	header.add_child(subtitle)

	var content: HBoxContainer = HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	root.add_child(content)

	var tower_panel: PanelContainer = _create_panel("可用防御塔", Vector2(250, 0))
	content.add_child(tower_panel)
	_fill_tower_panel(tower_panel)

	var map_panel: PanelContainer = _create_panel("地图预览", Vector2(520, 0))
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(map_panel)
	_fill_map_panel(map_panel)

	var enemy_panel: PanelContainer = _create_panel("来袭敌人", Vector2(250, 0))
	content.add_child(enemy_panel)
	_fill_enemy_panel(enemy_panel)

	var footer: HBoxContainer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 22)
	root.add_child(footer)

	var start_btn: Button = Button.new()
	start_btn.text = "开始战斗"
	start_btn.custom_minimum_size = Vector2(260, 76)
	_apply_menu_button_style(start_btn, 24)
	_apply_button_icon(start_btn, ICON_PLAY)
	start_btn.pressed.connect(_on_start_pressed)
	footer.add_child(start_btn)

	add_child(_create_back_icon_button("返回关卡"))

func _create_back_icon_button(tooltip: String) -> Button:
	var button: Button = Button.new()
	button.text = ""
	button.tooltip_text = ""
	button.custom_minimum_size = BACK_BUTTON_SIZE
	button.size = BACK_BUTTON_SIZE
	button.position = Vector2(BACK_BUTTON_MARGIN, BACK_BUTTON_MARGIN)
	button.focus_mode = Control.FOCUS_NONE
	_apply_back_icon_button_style(button)
	button.pressed.connect(_on_back_pressed)

	var icon: TextureRect = TextureRect.new()
	icon.texture = BACK_BUTTON_TEXTURE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	button.add_child(icon)
	return button

func _apply_back_icon_button_style(button: Button) -> void:
	var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", empty_style)
	button.add_theme_stylebox_override("pressed", empty_style)
	button.add_theme_stylebox_override("focus", empty_style)

func _create_panel(title_text: String, min_size: Vector2) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = min_size
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _create_panel_stylebox())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "Content"
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title: Label = Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.38))
	title.add_theme_color_override("font_outline_color", Color(0.10, 0.05, 0.02))
	title.add_theme_constant_override("outline_size", 3)
	vbox.add_child(title)
	return panel

func _get_panel_content(panel: PanelContainer) -> VBoxContainer:
	var margin: MarginContainer = panel.get_child(0) as MarginContainer
	return margin.get_child(0) as VBoxContainer

func _fill_tower_panel(panel: PanelContainer) -> void:
	var vbox: VBoxContainer = _get_panel_content(panel)
	for tower_type: String in TOWER_TYPES:
		var tower_data: TowerData = GameManager.get_tower_data(tower_type)
		if not tower_data:
			continue
		vbox.add_child(_create_tower_row(tower_type, tower_data))

func _create_tower_row(tower_type: String, tower_data: TowerData) -> Control:
	var row: PanelContainer = PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 118)
	row.add_theme_stylebox_override("panel", _create_item_stylebox())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	row.add_child(margin)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)

	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(64, 72)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _load_tower_icon(tower_type)
	hbox.add_child(icon)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	hbox.add_child(info)

	var name_label: Label = _create_item_name_label(_tower_display_name(tower_type, tower_data))
	info.add_child(name_label)
	info.add_child(_create_stat_label("费用 %d" % tower_data.cost))
	info.add_child(_create_stat_label(_tower_role(tower_type)))
	info.add_child(_create_stat_label("伤害 %.0f  范围 %.0f" % [tower_data.damage[0], tower_data.attack_range[0]]))
	return row

func _fill_enemy_panel(panel: PanelContainer) -> void:
	var vbox: VBoxContainer = _get_panel_content(panel)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	for monster_type: String in _get_level_monster_types():
		var monster_data: MonsterData = GameManager.get_monster_data(monster_type)
		if not monster_data:
			continue
		list.add_child(_create_enemy_row(monster_type, monster_data))

func _create_enemy_row(monster_type: String, monster_data: MonsterData) -> Control:
	var row: PanelContainer = PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 104)
	row.add_theme_stylebox_override("panel", _create_item_stylebox())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	row.add_child(margin)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)

	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(58, 62)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _load_monster_icon(monster_type)
	hbox.add_child(icon)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	hbox.add_child(info)

	info.add_child(_create_item_name_label(_monster_display_name(monster_type, monster_data)))
	info.add_child(_create_stat_label("生命 %d" % monster_data.max_health))
	info.add_child(_create_stat_label("速度 %.0f  奖励 %s" % [monster_data.move_speed, _format_level_reward(monster_type, monster_data.reward)]))
	info.add_child(_create_stat_label(_enemy_trait(monster_data)))
	return row

func _fill_map_panel(panel: PanelContainer) -> void:
	var vbox: VBoxContainer = _get_panel_content(panel)
	var map_frame: PanelContainer = PanelContainer.new()
	map_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_frame.add_theme_stylebox_override("panel", _create_map_frame_stylebox())
	vbox.add_child(map_frame)

	var preview: Control = Control.new()
	preview.clip_contents = true
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_frame.add_child(preview)
	preview.resized.connect(_redraw_map_preview.bind(preview))
	_redraw_map_preview(preview)

	var stats: Label = Label.new()
	stats.text = "初始金币 %d    村庄生命 %d    波次 %d" % [_level_data.starting_gold, _level_data.village_health, _level_data.waves.size()]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 20)
	stats.add_theme_color_override("font_color", Color(0.95, 0.86, 0.64))
	stats.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.02))
	stats.add_theme_constant_override("outline_size", 3)
	vbox.add_child(stats)

func _redraw_map_preview(preview: Control) -> void:
	for child: Node in preview.get_children():
		child.queue_free()
	var area_size: Vector2 = preview.size
	if area_size.x <= 1 or area_size.y <= 1:
		return

	if _level_data.background_texture:
		var bg: TextureRect = TextureRect.new()
		bg.texture = _level_data.background_texture
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		preview.add_child(bg)
	else:
		var fallback_bg: ColorRect = ColorRect.new()
		fallback_bg.color = _level_data.bg_color
		fallback_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		preview.add_child(fallback_bg)

	var scale: float = minf(area_size.x / MAP_SOURCE_SIZE.x, area_size.y / MAP_SOURCE_SIZE.y)
	var origin: Vector2 = (area_size - MAP_SOURCE_SIZE * scale) * 0.5

	for path_points: PackedVector2Array in _level_data.path_points:
		if path_points.size() < 2:
			continue
		var border: Line2D = Line2D.new()
		border.width = _level_data.path_width * scale + 8
		border.default_color = Color(0.22, 0.12, 0.06, 0.62)
		for point: Vector2 in path_points:
			border.add_point(origin + point * scale)
		preview.add_child(border)

		var line: Line2D = Line2D.new()
		line.width = _level_data.path_width * scale
		line.default_color = _level_data.path_color
		for point: Vector2 in path_points:
			line.add_point(origin + point * scale)
		preview.add_child(line)

	for spot: Vector2 in _level_data.build_spots:
		var build_spot: ColorRect = ColorRect.new()
		build_spot.color = Color(0.18, 0.62, 0.22, 0.75)
		var spot_size: float = maxf(8.0, 26.0 * scale)
		build_spot.size = Vector2(spot_size, spot_size)
		build_spot.position = origin + spot * scale - build_spot.size * 0.5
		preview.add_child(build_spot)

	var village_marker: ColorRect = ColorRect.new()
	village_marker.color = Color(0.88, 0.24, 0.16, 0.95)
	var marker_size: float = maxf(14.0, 42.0 * scale)
	village_marker.size = Vector2(marker_size, marker_size)
	village_marker.position = origin + _level_data.village_position * scale - village_marker.size * 0.5
	preview.add_child(village_marker)

func _get_level_monster_types() -> Array[String]:
	var types: Array[String] = []
	for wave: WaveData in _level_data.waves:
		if not wave.monster_type.is_empty() and not types.has(wave.monster_type):
			types.append(wave.monster_type)
		if not wave.support_monster_type.is_empty() and not types.has(wave.support_monster_type):
			types.append(wave.support_monster_type)
	return types

func _format_level_reward(monster_type: String, base_reward: int) -> String:
	var rewards: Array[int] = []
	for wave: WaveData in _level_data.waves:
		if wave.monster_type == monster_type:
			rewards.append(_get_wave_reward(base_reward, wave.reward_multiplier))
		if wave.support_monster_type == monster_type:
			rewards.append(_get_wave_reward(base_reward, wave.reward_multiplier))
	if rewards.is_empty():
		return str(base_reward)
	rewards.sort()
	var min_reward: int = rewards[0]
	var max_reward: int = rewards[rewards.size() - 1]
	if min_reward == max_reward:
		return str(min_reward)
	return "%d-%d" % [min_reward, max_reward]

func _get_wave_reward(base_reward: int, reward_multiplier: float) -> int:
	return maxi(0, int(round(float(base_reward) * reward_multiplier)))

func _create_item_name_label(text_value: String) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color(1.0, 0.91, 0.66))
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.02))
	label.add_theme_constant_override("outline_size", 2)
	return label

func _create_stat_label(text_value: String) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.82, 0.78, 0.68))
	return label

func _load_tower_icon(tower_type: String) -> Texture2D:
	var texture_path: String = ""
	match tower_type:
		"arrow":
			texture_path = "res://assets/towers/tower_lv1_transparent.png"
		"cannon":
			texture_path = "res://assets/towers/cannon_tower_lv1_transparent.png"
		"ice":
			texture_path = "res://assets/towers/ice_tower_lv1.png_transparent.png"
		_:
			return null
	return load(texture_path) as Texture2D

func _load_monster_icon(monster_type: String) -> Texture2D:
	return load("res://assets/monsters/%s/%s_icon.png" % [monster_type, monster_type]) as Texture2D

func _tower_display_name(tower_type: String, tower_data: TowerData) -> String:
	if not tower_data.tower_name.is_empty():
		return tower_data.tower_name
	match tower_type:
		"arrow":
			return "箭塔"
		"cannon":
			return "炮塔"
		"ice":
			return "冰塔"
		_:
			return tower_type

func _monster_display_name(monster_type: String, monster_data: MonsterData) -> String:
	if not monster_data.monster_name.is_empty():
		return monster_data.monster_name
	return monster_type

func _tower_role(tower_type: String) -> String:
	match tower_type:
		"arrow":
			return "单体输出"
		"cannon":
			return "范围伤害"
		"ice":
			return "范围减速"
		_:
			return "防御塔"

func _enemy_trait(monster_data: MonsterData) -> String:
	if monster_data.max_health >= 160:
		return "特点 高生命"
	if monster_data.move_speed >= 115.0:
		return "特点 快速"
	if monster_data.reward >= 60:
		return "特点 高奖励"
	if not monster_data.monster_category.is_empty():
		return "类型 %s" % monster_data.monster_category
	return "特点 普通"

func _apply_menu_button_style(button: Button, font_size: int) -> void:
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _make_menu_button_style(BUTTON_NORMAL))
	button.add_theme_stylebox_override("hover", _make_menu_button_style(BUTTON_HOVER))
	button.add_theme_stylebox_override("pressed", _make_menu_button_style(BUTTON_PRESSED))
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(1.0, 0.9, 0.48))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.62))
	button.add_theme_color_override("font_pressed_color", Color(0.95, 0.76, 0.35))
	button.add_theme_color_override("font_outline_color", Color(0.36, 0.12, 0.02, 0.95))
	button.add_theme_color_override("font_shadow_color", Color(0.2, 0.08, 0.02, 0.95))
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)

func _apply_button_icon(button: Button, icon: Texture2D) -> void:
	button.icon = icon
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_constant_override("h_separation", 8)
	button.add_theme_constant_override("icon_max_width", 30)

func _make_menu_button_style(texture: Texture2D) -> StyleBoxTexture:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = BUTTON_REGION

	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = atlas
	style.draw_center = true
	style.set_texture_margin(SIDE_LEFT, 28)
	style.set_texture_margin(SIDE_RIGHT, 28)
	style.set_texture_margin(SIDE_TOP, 10)
	style.set_texture_margin(SIDE_BOTTOM, 10)
	style.set_content_margin(SIDE_LEFT, 58)
	style.set_content_margin(SIDE_RIGHT, 58)
	style.set_content_margin(SIDE_TOP, 16)
	style.set_content_margin(SIDE_BOTTOM, 20)
	return style

func _create_panel_stylebox() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.08, 0.06, 0.94)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.70, 0.45, 0.22)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 4)
	return style

func _create_item_stylebox() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.17, 0.13, 0.09, 0.92)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.48, 0.34, 0.18)
	return style

func _create_map_frame_stylebox() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.03, 0.96)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.36, 0.25, 0.13)
	return style

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")
