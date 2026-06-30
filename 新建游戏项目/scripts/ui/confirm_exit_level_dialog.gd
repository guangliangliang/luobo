extends Control

signal confirm_pressed
signal cancel_pressed

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_ui()

func _setup_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.12, 0.07, 0.02, 0.54)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 260)
	panel.add_theme_stylebox_override("panel", _create_panel_stylebox())
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 26)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)

	var title_label: Label = Label.new()
	title_label.text = "确认退出"
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", Color(0.48, 0.18, 0.05))
	title_label.add_theme_color_override("font_outline_color", Color(1.0, 0.80, 0.38, 0.55))
	title_label.add_theme_constant_override("outline_size", 2)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	var message_label: Label = Label.new()
	message_label.text = "退出本关会放弃当前进度，确定要退出吗？"
	message_label.add_theme_font_size_override("font_size", 20)
	message_label.add_theme_color_override("font_color", Color(0.34, 0.19, 0.08))
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size = Vector2(340, 58)
	vbox.add_child(message_label)

	var button_row: HBoxContainer = HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 18)
	vbox.add_child(button_row)

	var cancel_btn: Button = _make_menu_button("取消")
	cancel_btn.pressed.connect(func(): cancel_pressed.emit())
	button_row.add_child(cancel_btn)

	var confirm_btn: Button = _make_menu_button("确定退出")
	confirm_btn.pressed.connect(func(): confirm_pressed.emit())
	button_row.add_child(confirm_btn)

func _make_menu_button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(138, 46)
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_stylebox_override("normal", _create_menu_button_stylebox(false))
	button.add_theme_stylebox_override("hover", _create_menu_button_stylebox(true))
	button.add_theme_stylebox_override("pressed", _create_menu_button_stylebox(true))
	button.add_theme_color_override("font_color", Color(0.98, 0.88, 0.58))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.70))
	button.add_theme_color_override("font_pressed_color", Color(0.93, 0.72, 0.32))
	button.add_theme_color_override("font_outline_color", Color(0.20, 0.08, 0.02, 0.95))
	button.add_theme_constant_override("outline_size", 2)
	button.focus_mode = Control.FOCUS_NONE
	return button

func _create_panel_stylebox() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.94, 0.78, 0.48, 0.98)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.52, 0.25, 0.07)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 5)
	return style

func _create_menu_button_stylebox(hovered: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.48, 0.20, 0.08, 0.98) if hovered else Color(0.32, 0.14, 0.06, 0.96)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.92, 0.60, 0.22) if hovered else Color(0.66, 0.38, 0.14)
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
	return style

func show_dialog() -> void:
	visible = true

func hide_dialog() -> void:
	visible = false
