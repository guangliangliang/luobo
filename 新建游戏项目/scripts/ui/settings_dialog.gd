extends Control

signal exit_level_pressed
signal level_info_pressed
signal restart_level_pressed
signal continue_pressed

var _bgm_slider: HSlider
var _bgm_label: Label
var _is_paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_ui()

func _setup_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(430, 430)
	panel.add_theme_stylebox_override("panel", _create_panel_stylebox())
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title_label: Label = Label.new()
	title_label.text = "游戏设置"
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	vbox.add_child(_make_separator())
	_create_bgm_control(vbox)
	vbox.add_child(_make_separator())

	var exit_btn: Button = _make_menu_button("退出本关")
	exit_btn.pressed.connect(func(): exit_level_pressed.emit())
	vbox.add_child(exit_btn)

	var info_btn: Button = _make_menu_button("本关说明")
	info_btn.pressed.connect(func(): level_info_pressed.emit())
	vbox.add_child(info_btn)

	var restart_btn: Button = _make_menu_button("重新开始")
	restart_btn.pressed.connect(func(): restart_level_pressed.emit())
	vbox.add_child(restart_btn)

	var continue_btn: Button = _make_menu_button("继续游戏")
	continue_btn.pressed.connect(func(): continue_pressed.emit())
	vbox.add_child(continue_btn)

func _create_bgm_control(parent: VBoxContainer) -> void:
	var bgm_vbox: VBoxContainer = VBoxContainer.new()
	bgm_vbox.add_theme_constant_override("separation", 8)
	parent.add_child(bgm_vbox)

	var bgm_title: Label = Label.new()
	bgm_title.text = "背景音乐"
	bgm_title.add_theme_font_size_override("font_size", 20)
	bgm_title.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	bgm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bgm_vbox.add_child(bgm_title)

	_bgm_slider = HSlider.new()
	_bgm_slider.min_value = 0.0
	_bgm_slider.max_value = 1.0
	_bgm_slider.step = 0.01
	_bgm_slider.value = AudioManager.get_bgm_volume() if AudioManager else 0.5
	_bgm_slider.custom_minimum_size = Vector2(320, 28)
	_bgm_slider.value_changed.connect(_on_bgm_volume_changed)
	bgm_vbox.add_child(_bgm_slider)

	_bgm_label = Label.new()
	_bgm_label.text = "音量: %d%%" % int(_bgm_slider.value * 100)
	_bgm_label.add_theme_font_size_override("font_size", 17)
	_bgm_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	_bgm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bgm_vbox.add_child(_bgm_label)

func _make_menu_button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(180, 44)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 21)
	return button

func _make_separator() -> HSeparator:
	var separator: HSeparator = HSeparator.new()
	separator.custom_minimum_size = Vector2(0, 8)
	return separator

func _create_panel_stylebox() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.12, 0.96)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.36, 0.45, 0.56)
	return style

func _on_bgm_volume_changed(value: float) -> void:
	_bgm_label.text = "音量: %d%%" % int(value * 100)
	if AudioManager:
		AudioManager.set_bgm_volume(value)

func show_dialog(is_paused_state: bool) -> void:
	_is_paused = is_paused_state
	if _bgm_slider and AudioManager:
		_bgm_slider.value = AudioManager.get_bgm_volume()
	visible = true

func hide_dialog() -> void:
	visible = false
