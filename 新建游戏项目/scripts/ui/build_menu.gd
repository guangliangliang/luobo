extends Control

signal tower_selected(tower_type: String)
signal cancel_pressed

const MENU_SIZE: Vector2 = Vector2(386, 204)
const TOWER_TYPES: Array[String] = ["arrow", "cannon", "ice"]
const GOLD_ICON: Texture2D = preload("res://assets/ui/icons/icon_gold.png")

var _buttons: Dictionary = {}
var _cost_labels: Dictionary = {}
var _name_labels: Dictionary = {}

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	size = MENU_SIZE
	custom_minimum_size = MENU_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP

	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.custom_minimum_size = MENU_SIZE
	panel.add_theme_stylebox_override("panel", _create_panel_stylebox())
	add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var header: HBoxContainer = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 24)
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(header)

	var title: Label = Label.new()
	title.text = "建造防御塔"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.38))
	title.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.02))
	title.add_theme_constant_override("outline_size", 2)
	header.add_child(title)

	var close_btn: Button = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(28, 26)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.add_theme_stylebox_override("normal", _create_close_stylebox(false))
	close_btn.add_theme_stylebox_override("hover", _create_close_stylebox(true))
	close_btn.add_theme_stylebox_override("pressed", _create_close_stylebox(true))
	close_btn.add_theme_color_override("font_color", Color(0.98, 0.90, 0.76))
	close_btn.pressed.connect(func(): cancel_pressed.emit())
	header.add_child(close_btn)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox)

	for tower_type: String in TOWER_TYPES:
		var td: TowerData = GameManager.get_tower_data(tower_type)
		if not td:
			continue
		var button: Button = _create_tower_button(tower_type, td)
		hbox.add_child(button)
		_buttons[tower_type] = button

	_update_button_states()

func _create_tower_button(tower_type: String, td: TowerData) -> Button:
	var button: Button = Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(112, 146)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = _tower_name(tower_type)
	button.add_theme_stylebox_override("normal", _create_tower_button_stylebox(false, false))
	button.add_theme_stylebox_override("hover", _create_tower_button_stylebox(true, false))
	button.add_theme_stylebox_override("pressed", _create_tower_button_stylebox(true, false))
	button.add_theme_stylebox_override("disabled", _create_tower_button_stylebox(false, true))
	button.pressed.connect(_on_tower_btn_pressed.bind(tower_type))

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 7
	vbox.offset_top = 7
	vbox.offset_right = -7
	vbox.offset_bottom = -7
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	button.add_child(vbox)

	var name_label: Label = Label.new()
	name_label.text = _tower_name(tower_type)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color(0.97, 0.91, 0.78))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)
	_name_labels[tower_type] = name_label

	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(58, 54)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _load_tower_icon(tower_type)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon)

	var role_label: Label = Label.new()
	role_label.text = _tower_role(tower_type)
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.add_theme_font_size_override("font_size", 11)
	role_label.add_theme_color_override("font_color", Color(0.64, 0.78, 0.92))
	role_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(role_label)

	var cost_badge: PanelContainer = PanelContainer.new()
	cost_badge.custom_minimum_size = Vector2(74, 24)
	cost_badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cost_badge.add_theme_stylebox_override("panel", _create_cost_badge_stylebox())
	cost_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(cost_badge)

	var cost_row: HBoxContainer = HBoxContainer.new()
	cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cost_row.add_theme_constant_override("separation", 3)
	cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_badge.add_child(cost_row)

	var gold_icon: TextureRect = TextureRect.new()
	gold_icon.custom_minimum_size = Vector2(16, 16)
	gold_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gold_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gold_icon.texture = GOLD_ICON
	gold_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_row.add_child(gold_icon)

	var cost_label: Label = Label.new()
	cost_label.text = "%d" % td.cost
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 15)
	cost_label.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.02))
	cost_label.add_theme_constant_override("outline_size", 2)
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_row.add_child(cost_label)
	_cost_labels[tower_type] = cost_label

	return button

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

func _on_tower_btn_pressed(tower_type: String) -> void:
	var td: TowerData = GameManager.get_tower_data(tower_type)
	if td and GameManager.current_gold >= td.cost:
		tower_selected.emit(tower_type)
	else:
		_update_button_states()

func refresh_button_states() -> void:
	_update_button_states()

func _update_button_states() -> void:
	for tower_type: String in _buttons:
		var td: TowerData = GameManager.get_tower_data(tower_type)
		if td:
			var can_afford: bool = GameManager.current_gold >= td.cost
			_buttons[tower_type].disabled = not can_afford
			if _cost_labels.has(tower_type):
				var cost_label: Label = _cost_labels[tower_type]
				cost_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.25) if can_afford else Color(0.58, 0.58, 0.58))
			if _name_labels.has(tower_type):
				var name_label: Label = _name_labels[tower_type]
				name_label.add_theme_color_override("font_color", Color(0.97, 0.91, 0.78) if can_afford else Color(0.56, 0.56, 0.56))

func _tower_name(tower_type: String) -> String:
	match tower_type:
		"arrow":
			return "箭塔"
		"cannon":
			return "炮塔"
		"ice":
			return "冰塔"
		_:
			return tower_type

func _tower_role(tower_type: String) -> String:
	match tower_type:
		"arrow":
			return "单体"
		"cannon":
			return "范围"
		"ice":
			return "减速"
		_:
			return ""

func _create_panel_stylebox() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.08, 0.07, 0.96)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.74, 0.47, 0.20)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	return style

func _create_tower_button_stylebox(hovered: bool, disabled: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	if disabled:
		style.bg_color = Color(0.15, 0.15, 0.15, 0.88)
		style.border_color = Color(0.30, 0.30, 0.30)
	elif hovered:
		style.bg_color = Color(0.26, 0.20, 0.12, 0.98)
		style.border_color = Color(1.0, 0.78, 0.30)
	else:
		style.bg_color = Color(0.16, 0.13, 0.10, 0.95)
		style.border_color = Color(0.48, 0.34, 0.18)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.content_margin_left = 6
	style.content_margin_top = 6
	style.content_margin_right = 6
	style.content_margin_bottom = 6
	return style

func _create_cost_badge_stylebox() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.04, 0.84)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.55, 0.38, 0.18)
	style.content_margin_left = 6
	style.content_margin_top = 2
	style.content_margin_right = 6
	style.content_margin_bottom = 2
	return style

func _create_close_stylebox(hovered: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.40, 0.12, 0.08, 0.98) if hovered else Color(0.20, 0.12, 0.10, 0.92)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.68, 0.42, 0.24)
	return style

func show_at(pos: Vector2) -> void:
	var screen_size: Vector2 = get_viewport_rect().size
	position = pos
	if position.x + MENU_SIZE.x > screen_size.x:
		position.x = screen_size.x - MENU_SIZE.x - 10
	if position.y + MENU_SIZE.y > screen_size.y:
		position.y = screen_size.y - MENU_SIZE.y - 10
	position.x = maxf(10.0, position.x)
	position.y = maxf(10.0, position.y)
	_update_button_states()
	visible = true

func hide_menu() -> void:
	visible = false
