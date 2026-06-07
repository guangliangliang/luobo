extends Control

signal close_pressed

var _tower_tab_btn: Button
var _enemy_tab_btn: Button
var _selector_row: HBoxContainer
var _content_list: VBoxContainer
var _active_tab: String = "tower"
var _selected_tower_type: String = ""
var _selected_monster_type: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_ui()
	_show_tower_tab()

func _setup_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.58)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 540)
	panel.add_theme_stylebox_override("panel", _create_panel_stylebox())
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var header: HBoxContainer = HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(header)

	var title: Label = Label.new()
	title.text = "本关说明"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn: Button = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(42, 38)
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): close_pressed.emit())
	header.add_child(close_btn)

	var tab_hbox: HBoxContainer = HBoxContainer.new()
	tab_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(tab_hbox)

	_tower_tab_btn = _make_tab_button("炮塔")
	_tower_tab_btn.pressed.connect(_show_tower_tab)
	tab_hbox.add_child(_tower_tab_btn)

	_enemy_tab_btn = _make_tab_button("敌人")
	_enemy_tab_btn.pressed.connect(_show_enemy_tab)
	tab_hbox.add_child(_enemy_tab_btn)

	var selector_panel: PanelContainer = PanelContainer.new()
	selector_panel.custom_minimum_size = Vector2(620, 108)
	selector_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selector_panel.add_theme_stylebox_override("panel", _create_selector_panel_stylebox())
	vbox.add_child(selector_panel)

	var selector_margin: MarginContainer = MarginContainer.new()
	selector_margin.add_theme_constant_override("margin_left", 12)
	selector_margin.add_theme_constant_override("margin_top", 10)
	selector_margin.add_theme_constant_override("margin_right", 12)
	selector_margin.add_theme_constant_override("margin_bottom", 10)
	selector_panel.add_child(selector_margin)

	_selector_row = HBoxContainer.new()
	_selector_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_selector_row.add_theme_constant_override("separation", 12)
	selector_margin.add_child(_selector_row)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 250)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_content_list = VBoxContainer.new()
	_content_list.add_theme_constant_override("separation", 10)
	_content_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content_list)

func _make_tab_button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(118, 42)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 21)
	return button

func _make_avatar_button(label_text: String, image_path: String, selected: bool) -> Button:
	var button: Button = Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(104, 86)
	button.add_theme_stylebox_override("normal", _create_avatar_stylebox(selected))
	button.add_theme_stylebox_override("hover", _create_avatar_stylebox(true))
	button.add_theme_stylebox_override("pressed", _create_avatar_stylebox(true))
	button.add_theme_stylebox_override("disabled", _create_avatar_stylebox(true))
	button.disabled = selected

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 3)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	var image: TextureRect = _make_unit_image(image_path, Vector2(48, 48))
	vbox.add_child(image)

	var label: Label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(label)
	return button

func _show_tower_tab() -> void:
	_active_tab = "tower"
	_refresh_tabs()

	var tower_types: Array = GameManager.tower_datas.keys()
	tower_types.sort()
	if not tower_types.has(_selected_tower_type):
		_selected_tower_type = str(tower_types[0]) if not tower_types.is_empty() else ""
	_refresh_selectors(tower_types)
	_show_selected_tower()

func _show_enemy_tab() -> void:
	_active_tab = "enemy"
	_refresh_tabs()

	var monster_types: Array = _get_current_level_monster_types()
	if monster_types.is_empty():
		monster_types = GameManager.monster_datas.keys()
	monster_types.sort()
	if not monster_types.has(_selected_monster_type):
		_selected_monster_type = str(monster_types[0]) if not monster_types.is_empty() else ""
	_refresh_selectors(monster_types)
	_show_selected_enemy()

func _refresh_tabs() -> void:
	if not _tower_tab_btn or not _enemy_tab_btn:
		return
	_tower_tab_btn.disabled = _active_tab == "tower"
	_enemy_tab_btn.disabled = _active_tab == "enemy"

func _clear_content() -> void:
	if not _content_list:
		return
	for child: Node in _content_list.get_children():
		_content_list.remove_child(child)
		child.queue_free()

func _clear_selectors() -> void:
	if not _selector_row:
		return
	for child: Node in _selector_row.get_children():
		_selector_row.remove_child(child)
		child.queue_free()

func _refresh_selectors(item_types: Array) -> void:
	_clear_selectors()
	for item_type in item_types:
		var id: String = str(item_type)
		var selected: bool = false
		if _active_tab == "tower":
			selected = id == _selected_tower_type
		else:
			selected = id == _selected_monster_type
		var button: Button
		if _active_tab == "tower":
			button = _make_avatar_button(_tower_name(id), _tower_image_path(id), selected)
			button.pressed.connect(_select_tower.bind(id))
		else:
			button = _make_avatar_button(_monster_name(id), _monster_image_path(id), selected)
			button.pressed.connect(_select_enemy.bind(id))
		_selector_row.add_child(button)

func _select_tower(tower_type: String) -> void:
	_selected_tower_type = tower_type
	var tower_types: Array = GameManager.tower_datas.keys()
	tower_types.sort()
	_refresh_selectors(tower_types)
	_show_selected_tower()

func _select_enemy(monster_type: String) -> void:
	_selected_monster_type = monster_type
	var monster_types: Array = _get_current_level_monster_types()
	if monster_types.is_empty():
		monster_types = GameManager.monster_datas.keys()
	monster_types.sort()
	_refresh_selectors(monster_types)
	_show_selected_enemy()

func _show_selected_tower() -> void:
	_clear_content()
	var data: TowerData = GameManager.get_tower_data(_selected_tower_type)
	if data:
		_content_list.add_child(_create_tower_card(data))

func _show_selected_enemy() -> void:
	_clear_content()
	var data: MonsterData = GameManager.get_monster_data(_selected_monster_type)
	if data:
		_content_list.add_child(_create_enemy_card(data))

func _create_tower_card(data: TowerData) -> Control:
	var card: PanelContainer = _make_card()
	var vbox: VBoxContainer = _make_card_body(card, _tower_image_path(data.tower_type))

	var title: Label = _make_title_label("%s  |  三种形态" % _tower_name(data.tower_type))
	vbox.add_child(title)

	var detail: Label = _make_body_label(_tower_description(data))
	vbox.add_child(detail)

	var level_row: HBoxContainer = HBoxContainer.new()
	level_row.alignment = BoxContainer.ALIGNMENT_CENTER
	level_row.add_theme_constant_override("separation", 10)
	level_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(level_row)

	for level_index in range(3):
		level_row.add_child(_create_tower_level_card(data, level_index))
	return card

func _create_enemy_card(data: MonsterData) -> Control:
	var card: PanelContainer = _make_card()
	var vbox: VBoxContainer = _make_card_body(card, _monster_image_path(data.monster_type))

	var title: Label = _make_title_label("%s  |  击败奖励 %d 金币" % [_monster_name(data.monster_type), data.reward])
	vbox.add_child(title)

	var stats: Label = _make_body_label("分类: %s    生命: %d    速度: %d    体型: %d" % [
		data.monster_category if data.monster_category != "" else "普通",
		data.max_health,
		int(data.move_speed),
		int(data.body_radius)
	])
	vbox.add_child(stats)

	var detail: Label = _make_body_label(_monster_description(data))
	vbox.add_child(detail)
	return card

func _make_card() -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _create_card_stylebox())
	return card

func _make_card_body(card: PanelContainer, image_path: String) -> VBoxContainer:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(hbox)

	hbox.add_child(_make_unit_image(image_path))

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	return vbox

func _create_tower_level_card(data: TowerData, level_index: int) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(138, 152)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _create_level_stylebox())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	vbox.add_child(_make_unit_image(_tower_image_path(data.tower_type, level_index), Vector2(58, 58)))

	var level_label: Label = _make_small_center_label("%d级形态" % (level_index + 1), Color(1.0, 0.88, 0.38))
	vbox.add_child(level_label)

	var coin_label: Label = _make_small_center_label(_tower_level_coin_text(data, level_index), Color(0.96, 0.96, 0.9))
	vbox.add_child(coin_label)

	var stats_label: Label = _make_small_center_label("伤害 %s  范围 %s" % [
		_level_value_at(data.damage, level_index),
		_level_value_at(data.attack_range, level_index)
	], Color(0.82, 0.88, 0.98))
	vbox.add_child(stats_label)
	return card

func _make_unit_image(image_path: String, image_size: Vector2 = Vector2(92, 92)) -> TextureRect:
	var image: TextureRect = TextureRect.new()
	image.custom_minimum_size = image_size
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if image_path != "" and ResourceLoader.exists(image_path):
		image.texture = load(image_path) as Texture2D
	return image

func _make_title_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 21)
	label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.34))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _make_body_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _make_small_center_label(text: String, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _level_values(values: Array) -> String:
	var parts: Array[String] = []
	for value in values:
		var number: float = float(value)
		parts.append(str(int(number)) if is_equal_approx(number, roundf(number)) else "%.1f" % number)
	var result: String = ""
	for i in range(parts.size()):
		if i > 0:
			result += "/"
		result += parts[i]
	return result

func _level_value_at(values: Array, level_index: int) -> String:
	if values.is_empty():
		return "-"
	var value_index: int = clampi(level_index, 0, values.size() - 1)
	var number: float = float(values[value_index])
	return str(int(number)) if is_equal_approx(number, roundf(number)) else "%.1f" % number

func _tower_level_coin_text(data: TowerData, level_index: int) -> String:
	if level_index == 0:
		return "建造 %d 金币" % data.cost
	if level_index < data.upgrade_cost.size():
		return "升级 %d 金币" % int(data.upgrade_cost[level_index])
	return "升级 - 金币"

func _get_current_level_monster_types() -> Array:
	var result: Array = []
	var level_data: LevelData = GameManager.get_level_data(GameManager.current_level_id)
	if not level_data:
		return result
	for wave: WaveData in level_data.waves:
		if not result.has(wave.monster_type):
			result.append(wave.monster_type)
		if wave.support_monster_type != "" and not result.has(wave.support_monster_type):
			result.append(wave.support_monster_type)
	return result

func _tower_image_path(tower_type: String, level_index: int = 0) -> String:
	var level: int = clampi(level_index + 1, 1, 3)
	match tower_type:
		"arrow":
			return "res://assets/towers/tower_lv%d_transparent.png" % level
		"cannon":
			return "res://assets/towers/cannon_tower_lv%d_transparent.png" % level
		"ice":
			return "res://assets/towers/ice_tower_lv%d.png_transparent.png" % level
		_:
			return ""

func _monster_image_path(monster_type: String) -> String:
	var icon_path: String = "res://assets/monsters/%s/%s_icon.png" % [monster_type, monster_type]
	if ResourceLoader.exists(icon_path):
		return icon_path

	var sheet_path: String = "res://assets/monsters/%s/%s_sheet.png" % [monster_type, monster_type]
	if ResourceLoader.exists(sheet_path):
		return sheet_path
	return ""

func _tower_name(tower_type: String) -> String:
	match tower_type:
		"arrow":
			return "箭塔"
		"cannon":
			return "炮塔"
		"ice":
			return "冰冻塔"
		_:
			return tower_type

func _tower_description(data: TowerData) -> String:
	match data.tower_type:
		"arrow":
			return "单体输出稳定，建造便宜，适合在前期快速补足防线。升级后射程和伤害都会提升。"
		"cannon":
			return "高伤害并带范围溅射，适合放在怪物密集转弯处，对成群敌人效果最好。"
		"ice":
			return "伤害较低，但可以减速敌人，适合配合箭塔和炮塔延长输出时间。"
		_:
			return "可建造防御单位。"

func _monster_name(monster_type: String) -> String:
	var data: MonsterData = GameManager.get_monster_data(monster_type)
	if data and data.monster_name != "":
		return data.monster_name
	return monster_type

func _monster_description(data: MonsterData) -> String:
	match data.monster_type:
		"wild_wolf":
			return "速度较快、生命较低，常以数量压迫防线，适合用箭塔快速清理。"
		"thief":
			return "移动速度最快，生命值低，容易钻过火力空档，适合用冰冻塔减速。"
		"robber":
			return "轻装人形敌人，速度快于普通山贼，适合穿插在兽群后制造压力。"
		"boar":
			return "冲锋型野兽，生命和速度都较均衡，容易顶住前期火力。"
		"mountain_bandit":
			return "山路强袭单位，生命比劫匪更高，适合作为中段主力。"
		"shield_bandit":
			return "重甲单位，速度慢但抗打，适合用炮塔和升级箭塔持续压制。"
		"brown_bear":
			return "重型野兽，生命高、速度偏慢，能拖住防线输出节奏。"
		"black_bear":
			return "更耐打的重型野兽，适合在后期和快速单位混合出场。"
		"tiger":
			return "精英野兽，速度快且生命不低，需要减速和集中火力处理。"
		"bandit_leader":
			return "首领单位，生命很高，会带着山贼和盾牌强盗一起冲击防线。"
		_:
			return "敌方单位，会沿道路向村庄前进。"

func _create_panel_stylebox() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.10, 0.13, 0.97)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.42, 0.50, 0.62)
	return style

func _create_card_stylebox() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.17, 0.21, 0.96)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.32, 0.38, 0.46)
	return style

func _create_selector_panel_stylebox() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.12, 0.16, 0.92)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.26, 0.31, 0.39)
	return style

func _create_avatar_stylebox(selected: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.24, 0.29, 0.36, 0.96) if selected else Color(0.16, 0.18, 0.23, 0.95)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2 if selected else 1
	style.border_width_top = 2 if selected else 1
	style.border_width_right = 2 if selected else 1
	style.border_width_bottom = 2 if selected else 1
	style.border_color = Color(1.0, 0.78, 0.28) if selected else Color(0.34, 0.40, 0.49)
	return style

func _create_level_stylebox() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.16, 0.95)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.30, 0.36, 0.45)
	return style

func show_dialog() -> void:
	visible = true
	_show_tower_tab()

func hide_dialog() -> void:
	visible = false
