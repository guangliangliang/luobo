extends Node2D

const MENU_BG: Texture2D = preload("res://assets/ui/menu/menu_bg_village.png")
const LOGO_TEXTURE: Texture2D = preload("res://assets/ui/menu/logo_village_defense.png")
const BUTTON_NORMAL: Texture2D = preload("res://assets/ui/buttons/button_menu_normal.png")
const BUTTON_HOVER: Texture2D = preload("res://assets/ui/buttons/button_menu_hover.png")
const BUTTON_PRESSED: Texture2D = preload("res://assets/ui/buttons/button_menu_pressed.png")
const ICON_PLAY: Texture2D = preload("res://assets/ui/icons/icon_play.svg")
const BUTTON_REGION: Rect2 = Rect2(72.5, 175, 622.5, 144.5)

func _ready() -> void:
	AudioManager.play_bgm("menu")
	_setup_base_ui()
	_show_main_menu_ui()

func _get_viewport_size() -> Vector2:
	return get_viewport_rect().size

func _setup_base_ui() -> void:
	for child in get_children():
		child.queue_free()
	var viewport_size: Vector2 = _get_viewport_size()

	var bg: Sprite2D = Sprite2D.new()
	bg.texture = MENU_BG
	bg.centered = false
	bg.position = Vector2.ZERO
	bg.scale = Vector2(viewport_size.x / MENU_BG.get_width(), viewport_size.y / MENU_BG.get_height())
	add_child(bg)

	var shade: ColorRect = ColorRect.new()
	shade.size = viewport_size
	shade.color = Color(0, 0, 0, 0.18)
	add_child(shade)

	var logo: Sprite2D = Sprite2D.new()
	logo.texture = LOGO_TEXTURE
	logo.position = Vector2(viewport_size.x * 0.5, viewport_size.y * 0.32)
	logo.scale = Vector2(0.43, 0.43)
	add_child(logo)

func _show_main_menu_ui() -> void:
	var viewport_size: Vector2 = _get_viewport_size()
	var menu_size := Vector2(330, 180)
	var menu: VBoxContainer = VBoxContainer.new()
	menu.position = Vector2(
		viewport_size.x * 0.5 - menu_size.x * 0.5,
		maxf(24.0, minf(viewport_size.y - menu_size.y - 24.0, viewport_size.y * 0.56))
	)
	menu.size = menu_size
	menu.add_theme_constant_override("separation", 14)
	menu.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(menu)

	var start_btn: Button = Button.new()
	start_btn.text = "开始游戏"
	start_btn.custom_minimum_size = Vector2(252, 78)
	_apply_menu_button_style(start_btn, 24)
	_apply_button_icon(start_btn, ICON_PLAY)
	start_btn.pressed.connect(_on_start_pressed)
	menu.add_child(start_btn)

	var exit_btn: Button = Button.new()
	exit_btn.text = "退出游戏"
	exit_btn.custom_minimum_size = Vector2(252, 78)
	_apply_menu_button_style(exit_btn, 24)
	exit_btn.pressed.connect(_on_exit_pressed)
	menu.add_child(exit_btn)

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

func _apply_button_icon(button: Button, icon: Texture2D) -> void:
	button.icon = icon
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_constant_override("h_separation", 8)
	button.add_theme_constant_override("icon_max_width", 30)

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
