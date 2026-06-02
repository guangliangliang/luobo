extends Control

const MENU_BG: Texture2D = preload("res://assets/ui/menu/menu_bg_village.png")
const LOGO_TEXTURE: Texture2D = preload("res://assets/ui/menu/logo_village_defense.png")
const BUTTON_NORMAL: Texture2D = preload("res://assets/ui/buttons/button_menu_normal.png")
const BUTTON_HOVER: Texture2D = preload("res://assets/ui/buttons/button_menu_hover.png")
const BUTTON_PRESSED: Texture2D = preload("res://assets/ui/buttons/button_menu_pressed.png")
const LEVEL_CARD_NORMAL: Texture2D = preload("res://assets/ui/level_select/level_card_normal.png")
const LEVEL_CARD_HOVER: Texture2D = preload("res://assets/ui/level_select/level_card_hover.png")
const LEVEL_CARD_LOCKED: Texture2D = preload("res://assets/ui/level_select/level_card_locked.png")
const BUTTON_REGION: Rect2 = Rect2(145, 350, 1245, 289)

var _level_buttons: Dictionary = {}

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	anchors_preset = Control.PRESET_FULL_RECT

	var bg: TextureRect = TextureRect.new()
	bg.texture = MENU_BG
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0, 0, 0, 0.2)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var center: VBoxContainer = VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.offset_left = -310
	center.offset_top = -285
	center.offset_right = 310
	center.offset_bottom = 285
	center.add_theme_constant_override("separation", 10)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(center)

	var logo: TextureRect = TextureRect.new()
	logo.texture = LOGO_TEXTURE
	logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(430, 220)
	center.add_child(logo)

	var title: Label = Label.new()
	title.text = "选择关卡"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	title.add_theme_color_override("font_shadow_color", Color(0.18, 0.08, 0.02, 0.95))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)

	var levels_hbox: HBoxContainer = HBoxContainer.new()
	levels_hbox.add_theme_constant_override("separation", 44)
	levels_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(levels_hbox)

	var level_configs: Array = [
		{"id": 1, "name": "第一关\n村口防线"},
		{"id": 2, "name": "第二关\n分兵两路"},
	]

	for cfg: Dictionary in level_configs:
		var btn: Button = Button.new()
		btn.text = cfg.name
		btn.custom_minimum_size = Vector2(280, 150)
		_apply_level_button_style(btn)
		btn.pressed.connect(_on_level_pressed.bind(cfg.id))
		levels_hbox.add_child(btn)
		_level_buttons[cfg.id] = btn

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 14)
	center.add_child(spacer)

	var back_btn: Button = Button.new()
	back_btn.text = "返回菜单"
	back_btn.custom_minimum_size = Vector2(330, 78)
	_apply_menu_button_style(back_btn, 24)
	back_btn.pressed.connect(_on_back_pressed)
	center.add_child(back_btn)

	_update_buttons()

func _apply_menu_button_style(button: Button, font_size: int) -> void:
	button.add_theme_stylebox_override("normal", _make_menu_button_style(BUTTON_NORMAL))
	button.add_theme_stylebox_override("hover", _make_menu_button_style(BUTTON_HOVER))
	button.add_theme_stylebox_override("pressed", _make_menu_button_style(BUTTON_PRESSED))
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(1.0, 0.9, 0.48))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.62))
	button.add_theme_color_override("font_pressed_color", Color(0.95, 0.76, 0.35))
	button.add_theme_color_override("font_shadow_color", Color(0.2, 0.08, 0.02, 0.95))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)

func _apply_level_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _make_level_card_style(LEVEL_CARD_NORMAL))
	button.add_theme_stylebox_override("hover", _make_level_card_style(LEVEL_CARD_HOVER))
	button.add_theme_stylebox_override("pressed", _make_level_card_style(LEVEL_CARD_HOVER))
	button.add_theme_stylebox_override("disabled", _make_level_card_style(LEVEL_CARD_LOCKED))
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_color_override("font_color", Color(0.28, 0.12, 0.02))
	button.add_theme_color_override("font_hover_color", Color(0.18, 0.08, 0.01))
	button.add_theme_color_override("font_disabled_color", Color(0.25, 0.24, 0.23))
	button.add_theme_color_override("font_outline_color", Color(1.0, 0.86, 0.48))
	button.add_theme_color_override("font_shadow_color", Color(1.0, 0.86, 0.48, 0.9))
	button.add_theme_constant_override("outline_size", 3)
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)

func _make_menu_button_style(texture: Texture2D) -> StyleBoxTexture:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = BUTTON_REGION

	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = atlas
	style.draw_center = true
	style.set_texture_margin(SIDE_LEFT, 56)
	style.set_texture_margin(SIDE_RIGHT, 56)
	style.set_texture_margin(SIDE_TOP, 20)
	style.set_texture_margin(SIDE_BOTTOM, 20)
	return style

func _make_level_card_style(texture: Texture2D) -> StyleBoxTexture:
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = texture
	style.draw_center = true
	style.set_texture_margin(SIDE_LEFT, 34)
	style.set_texture_margin(SIDE_RIGHT, 34)
	style.set_texture_margin(SIDE_TOP, 30)
	style.set_texture_margin(SIDE_BOTTOM, 30)
	return style

func _update_buttons() -> void:
	for id: int in _level_buttons:
		var btn: Button = _level_buttons[id]
		if id <= SaveManager.unlock_level:
			btn.disabled = false
			btn.modulate = Color.WHITE
		else:
			btn.disabled = true
			btn.modulate = Color.WHITE

func _on_level_pressed(level_id: int) -> void:
	GameManager.current_level_id = level_id
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
