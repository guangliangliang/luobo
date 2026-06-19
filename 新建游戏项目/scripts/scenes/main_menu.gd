extends Control

const MENU_BG: Texture2D = preload("res://assets/ui/menu/menu_bg_village.png")
const LOGO_TEXTURE: Texture2D = preload("res://assets/ui/menu/logo_village_defense.png")
const BUTTON_NORMAL: Texture2D = preload("res://assets/ui/buttons/button_menu_normal.png")
const BUTTON_HOVER: Texture2D = preload("res://assets/ui/buttons/button_menu_hover.png")
const BUTTON_PRESSED: Texture2D = preload("res://assets/ui/buttons/button_menu_pressed.png")
const BUTTON_REGION: Rect2 = Rect2(72.5, 175, 622.5, 144.5)

var _settings_dialog: Control
var _codex_dialog: Control
var _bgm_slider: HSlider
var _bgm_label: Label
var _sfx_slider: HSlider
var _sfx_label: Label

func _ready() -> void:
	AudioManager.play_bgm("menu")
	_setup_ui()

func _setup_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg: TextureRect = TextureRect.new()
	bg.texture = MENU_BG
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0, 0, 0, 0.16)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var top_buttons: Control = Control.new()
	top_buttons.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_buttons.offset_left = -212
	top_buttons.offset_top = 24
	top_buttons.offset_right = -24
	top_buttons.offset_bottom = 68
	top_buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_buttons)

	var settings_btn: Button = _make_top_button("设置")
	settings_btn.position = Vector2(0, 0)
	settings_btn.size = Vector2(88, 44)
	settings_btn.pressed.connect(_on_settings_pressed)
	top_buttons.add_child(settings_btn)

	var codex_btn: Button = _make_top_button("图鉴")
	codex_btn.position = Vector2(100, 0)
	codex_btn.size = Vector2(88, 44)
	codex_btn.pressed.connect(_on_codex_pressed)
	top_buttons.add_child(codex_btn)

	var center: VBoxContainer = VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.offset_left = -215
	center.offset_top = -220
	center.offset_right = 215
	center.offset_bottom = 220
	center.add_theme_constant_override("separation", 14)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(center)

	var logo: TextureRect = TextureRect.new()
	logo.texture = LOGO_TEXTURE
	logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(430, 220)
	center.add_child(logo)

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 18)
	center.add_child(spacer)

	var start_btn: Button = Button.new()
	start_btn.text = "开始游戏"
	start_btn.custom_minimum_size = Vector2(252, 78)
	_apply_menu_button_style(start_btn, 24)
	start_btn.pressed.connect(_on_start_pressed)
	center.add_child(start_btn)

	var exit_btn: Button = Button.new()
	exit_btn.text = "退出游戏"
	exit_btn.custom_minimum_size = Vector2(252, 78)
	_apply_menu_button_style(exit_btn, 24)
	exit_btn.pressed.connect(_on_exit_pressed)
	center.add_child(exit_btn)

	var dialog_canvas: CanvasLayer = CanvasLayer.new()
	dialog_canvas.layer = 100
	dialog_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(dialog_canvas)

	_settings_dialog = _create_simple_settings_dialog()
	_settings_dialog.visible = false
	dialog_canvas.add_child(_settings_dialog)

	_codex_dialog = load("res://scripts/ui/codex_dialog.gd").new()
	_codex_dialog.visible = false
	_codex_dialog.close_pressed.connect(_on_codex_closed)
	dialog_canvas.add_child(_codex_dialog)

func _create_simple_settings_dialog() -> Control:
	var dialog = Control.new()
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	dialog.add_child(bg)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(430, 420)
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
	_create_sfx_control(vbox)
	vbox.add_child(_make_separator())

	var close_btn: Button = _make_menu_button("关闭")
	close_btn.pressed.connect(_on_settings_closed)
	vbox.add_child(close_btn)

	return dialog

func _update_settings_dialog_values():
	if _bgm_slider and AudioManager:
		_bgm_slider.value = AudioManager.get_bgm_volume()
	if _bgm_label:
		_bgm_label.text = "音量: %d%%" % int(_bgm_slider.value * 100)
	if _sfx_slider and AudioManager:
		_sfx_slider.value = AudioManager.get_sfx_volume()
	if _sfx_label:
		_sfx_label.text = "音量: %d%%" % int(_sfx_slider.value * 100)

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
	bgm_vbox.add_child(_bgm_slider)

	_bgm_label = Label.new()
	_bgm_label.text = "音量: %d%%" % int(_bgm_slider.value * 100)
	_bgm_label.add_theme_font_size_override("font_size", 17)
	_bgm_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	_bgm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bgm_vbox.add_child(_bgm_label)

	_bgm_slider.value_changed.connect(func(value):
		_bgm_label.text = "音量: %d%%" % int(value * 100)
		if AudioManager: AudioManager.set_bgm_volume(value)
	)

func _create_sfx_control(parent: VBoxContainer) -> void:
	var sfx_vbox: VBoxContainer = VBoxContainer.new()
	sfx_vbox.add_theme_constant_override("separation", 8)
	parent.add_child(sfx_vbox)

	var sfx_title: Label = Label.new()
	sfx_title.text = "音效"
	sfx_title.add_theme_font_size_override("font_size", 20)
	sfx_title.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	sfx_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sfx_vbox.add_child(sfx_title)

	_sfx_slider = HSlider.new()
	_sfx_slider.min_value = 0.0
	_sfx_slider.max_value = 1.0
	_sfx_slider.step = 0.01
	_sfx_slider.value = AudioManager.get_sfx_volume() if AudioManager else 0.5
	_sfx_slider.custom_minimum_size = Vector2(320, 28)
	sfx_vbox.add_child(_sfx_slider)

	_sfx_label = Label.new()
	_sfx_label.text = "音量: %d%%" % int(_sfx_slider.value * 100)
	_sfx_label.add_theme_font_size_override("font_size", 17)
	_sfx_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	_sfx_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sfx_vbox.add_child(_sfx_label)

	_sfx_slider.value_changed.connect(func(value):
		_sfx_label.text = "音量: %d%%" % int(value * 100)
		if AudioManager: AudioManager.set_sfx_volume(value)
	)

func _make_top_button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(88, 44)
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_stylebox_override("normal", _create_top_button_stylebox(Color(0.18, 0.20, 0.26, 0.96)))
	button.add_theme_stylebox_override("hover", _create_top_button_stylebox(Color(0.25, 0.29, 0.38, 0.98)))
	button.add_theme_stylebox_override("pressed", _create_top_button_stylebox(Color(0.13, 0.15, 0.20, 1.0)))
	button.add_theme_color_override("font_color", Color(1.0, 0.90, 0.48))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.62))
	button.add_theme_color_override("font_pressed_color", Color(0.95, 0.76, 0.35))
	return button

func _create_top_button_stylebox(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1.0, 0.78, 0.24, 0.85)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _make_menu_button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(180, 44)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 21)
	button.focus_mode = Control.FOCUS_NONE
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

func _on_settings_pressed() -> void:
	if _settings_dialog:
		_update_settings_dialog_values()
		_settings_dialog.visible = true

func _on_settings_closed() -> void:
	if _settings_dialog:
		_settings_dialog.visible = false

func _on_codex_pressed() -> void:
	if _codex_dialog and _codex_dialog.has_method("show_dialog"):
		_codex_dialog.show_dialog()

func _on_codex_closed() -> void:
	if _codex_dialog and _codex_dialog.has_method("hide_dialog"):
		_codex_dialog.hide_dialog()

func _apply_menu_button_style(button: Button, font_size: int) -> void:
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _make_button_style(BUTTON_NORMAL))
	button.add_theme_stylebox_override("hover", _make_button_style(BUTTON_HOVER))
	button.add_theme_stylebox_override("pressed", _make_button_style(BUTTON_PRESSED))
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(1.0, 0.9, 0.48))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.62))
	button.add_theme_color_override("font_pressed_color", Color(0.95, 0.76, 0.35))
	button.add_theme_color_override("font_outline_color", Color(0.36, 0.12, 0.02, 0.95))
	button.add_theme_color_override("font_shadow_color", Color(0.2, 0.08, 0.02, 0.95))
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)

func _make_button_style(texture: Texture2D) -> StyleBoxTexture:
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

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
