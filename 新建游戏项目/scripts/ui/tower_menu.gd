extends Control

signal upgrade_pressed
signal sell_pressed
signal cancel_pressed

const MENU_SIZE: Vector2 = Vector2(296, 154)
const GOLD_ICON: Texture2D = preload("res://assets/ui/icons/icon_gold.png")

var _tower: Node2D
var _upgrade_btn: Button
var _sell_btn: Button

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	size = MENU_SIZE
	custom_minimum_size = MENU_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.custom_minimum_size = MENU_SIZE
	panel.add_theme_stylebox_override("panel", _create_panel_stylebox())
	add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 7)
	margin.add_child(vbox)

	var header: HBoxContainer = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 24)
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(header)

	var title: Label = Label.new()
	title.text = "防御塔操作"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.38))
	title.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.02))
	title.add_theme_constant_override("outline_size", 2)
	header.add_child(title)

	var close_btn: Button = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(28, 24)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.add_theme_color_override("font_color", Color(0.98, 0.90, 0.76))
	close_btn.add_theme_stylebox_override("normal", _create_close_stylebox(false))
	close_btn.add_theme_stylebox_override("hover", _create_close_stylebox(true))
	close_btn.add_theme_stylebox_override("pressed", _create_close_stylebox(true))
	close_btn.pressed.connect(func(): cancel_pressed.emit())
	header.add_child(close_btn)

	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 10)
	vbox.add_child(action_row)

	_upgrade_btn = _create_action_button()
	_upgrade_btn.pressed.connect(func(): upgrade_pressed.emit())
	action_row.add_child(_upgrade_btn)

	_sell_btn = _create_action_button()
	_sell_btn.pressed.connect(func(): sell_pressed.emit())
	action_row.add_child(_sell_btn)

func _create_action_button() -> Button:
	var button: Button = Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(128, 96)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _create_action_stylebox(false, false))
	button.add_theme_stylebox_override("hover", _create_action_stylebox(true, false))
	button.add_theme_stylebox_override("pressed", _create_action_stylebox(true, false))
	button.add_theme_stylebox_override("disabled", _create_action_stylebox(false, true))
	return button

func _set_button_content(button: Button, icon_text: String, title_text: String, detail_text: String, color: Color, show_gold: bool) -> void:
	for child in button.get_children():
		button.remove_child(child)
		child.queue_free()

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 8
	vbox.offset_top = 6
	vbox.offset_right = -8
	vbox.offset_bottom = -7
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	button.add_child(vbox)

	var icon_label: Label = Label.new()
	icon_label.text = icon_text
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 28)
	icon_label.add_theme_color_override("font_color", color)
	icon_label.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.02))
	icon_label.add_theme_constant_override("outline_size", 2)
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_label)

	var title_label: Label = Label.new()
	title_label.text = title_text
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", color)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title_label)

	if show_gold:
		vbox.add_child(_create_gold_badge(detail_text, color))
	else:
		var detail_label: Label = Label.new()
		detail_label.text = detail_text
		detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detail_label.add_theme_font_size_override("font_size", 13)
		detail_label.add_theme_color_override("font_color", color)
		detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(detail_label)

func _create_gold_badge(text: String, color: Color) -> Control:
	var badge: PanelContainer = PanelContainer.new()
	badge.custom_minimum_size = Vector2(76, 23)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge.add_theme_stylebox_override("panel", _create_cost_badge_stylebox())
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 3)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(row)

	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(15, 15)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = GOLD_ICON
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.02))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)

	return badge

func show_for_tower(tower: Node2D, pos: Vector2) -> void:
	_tower = tower
	_update_info()

	position = pos
	var screen_size: Vector2 = get_viewport_rect().size
	if position.x + MENU_SIZE.x > screen_size.x:
		position.x = screen_size.x - MENU_SIZE.x - 10
	if position.y + MENU_SIZE.y > screen_size.y:
		position.y = screen_size.y - MENU_SIZE.y - 10
	position.x = maxf(10.0, position.x)
	position.y = maxf(10.0, position.y)

	visible = true

func refresh_info() -> void:
	_update_info()

func _update_info() -> void:
	if not _tower or not is_instance_valid(_tower):
		hide_menu()
		return

	if _tower.can_upgrade():
		var cost: int = _tower.get_upgrade_cost()
		var can_afford: bool = GameManager.current_gold >= cost
		var upgrade_color: Color = Color(1.0, 0.86, 0.25) if can_afford else Color(0.56, 0.56, 0.56)
		_upgrade_btn.disabled = not can_afford
		_set_button_content(_upgrade_btn, "↑", "升级", "%d" % cost, upgrade_color, true)
	else:
		_upgrade_btn.disabled = true
		_set_button_content(_upgrade_btn, "↑", "升级", "已满级", Color(0.56, 0.56, 0.56), false)

	var sell_value: int = GameManager.get_sell_value(_tower.tower_type, _tower.tower_level)
	_sell_btn.disabled = false
	_set_button_content(_sell_btn, "X", "出售", "%d" % sell_value, Color(1.0, 0.48, 0.35), true)

func get_tower() -> Node2D:
	return _tower

func hide_menu() -> void:
	_tower = null
	visible = false

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

func _create_action_stylebox(hovered: bool, disabled: bool) -> StyleBoxFlat:
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
