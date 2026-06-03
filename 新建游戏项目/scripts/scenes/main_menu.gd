extends Control

const MENU_BG: Texture2D = preload("res://assets/ui/menu/menu_bg_village.png")
const LOGO_TEXTURE: Texture2D = preload("res://assets/ui/menu/logo_village_defense.png")
const BUTTON_NORMAL: Texture2D = preload("res://assets/ui/buttons/button_menu_normal.png")
const BUTTON_HOVER: Texture2D = preload("res://assets/ui/buttons/button_menu_hover.png")
const BUTTON_PRESSED: Texture2D = preload("res://assets/ui/buttons/button_menu_pressed.png")
const BUTTON_REGION: Rect2 = Rect2(145, 350, 1245, 289)

func _ready() -> void:
	AudioManager.play_bgm("menu")
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
	shade.color = Color(0, 0, 0, 0.16)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

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

func _apply_menu_button_style(button: Button, font_size: int) -> void:
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
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
	style.set_texture_margin(SIDE_LEFT, 56)
	style.set_texture_margin(SIDE_RIGHT, 56)
	style.set_texture_margin(SIDE_TOP, 20)
	style.set_texture_margin(SIDE_BOTTOM, 20)
	style.set_content_margin(SIDE_LEFT, 58)
	style.set_content_margin(SIDE_RIGHT, 58)
	style.set_content_margin(SIDE_TOP, 16)
	style.set_content_margin(SIDE_BOTTOM, 20)
	return style

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
