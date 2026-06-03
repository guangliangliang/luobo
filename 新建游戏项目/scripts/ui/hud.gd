extends Control

signal pause_pressed
signal settings_pressed

var _gold_label: Label
var _wave_label: Label
var _pause_btn: Button
var _settings_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_ui()
	GameManager.gold_changed.connect(_on_gold_changed)

func _setup_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var top_center: CenterContainer = CenterContainer.new()
	top_center.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_center.offset_top = 8
	top_center.offset_bottom = 58
	top_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_center.z_index = 100
	add_child(top_center)

	var h_box: HBoxContainer = HBoxContainer.new()
	h_box.alignment = BoxContainer.ALIGNMENT_CENTER
	h_box.add_theme_constant_override("separation", 20)
	h_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_center.add_child(h_box)

	_gold_label = _make_hud_label(Color(1.0, 0.86, 0.25))
	h_box.add_child(_gold_label)

	_wave_label = _make_hud_label(Color.WHITE)
	h_box.add_child(_wave_label)

	_pause_btn = _make_hud_button("暂停")
	_pause_btn.pressed.connect(func(): pause_pressed.emit())
	h_box.add_child(_pause_btn)

	_settings_btn = _make_hud_button("设置")
	_settings_btn.pressed.connect(func(): settings_pressed.emit())
	h_box.add_child(_settings_btn)

func _make_hud_label(color: Color) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(120, 42)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _make_hud_button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.flat = true
	button.custom_minimum_size = Vector2(96, 42)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.45))
	button.add_theme_color_override("font_pressed_color", Color(0.85, 0.95, 1.0))
	button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)
	return button

func update_gold(gold: int) -> void:
	if _gold_label:
		_gold_label.text = "金币: %d" % gold

func update_health(_health: int) -> void:
	pass

func update_wave(current: int, total: int) -> void:
	if _wave_label:
		_wave_label.text = "波次: %d/%d" % [current, total]

func update_monster_count(_count: int) -> void:
	pass

func update_pause_button(is_paused: bool) -> void:
	if _pause_btn:
		_pause_btn.text = "继续" if is_paused else "暂停"

func _on_gold_changed(new_gold: int) -> void:
	update_gold(new_gold)
