extends Node2D

const MENU_BG: Texture2D = preload("res://assets/ui/menu/menu_bg_village.png")
const LOGO_TEXTURE: Texture2D = preload("res://assets/ui/menu/logo_village_defense.png")
const LOADING_TEXTURE: Texture2D = preload("res://assets/ui/menu/loading_icon_sheet.png")
const BUTTON_NORMAL: Texture2D = preload("res://assets/ui/buttons/button_menu_normal.png")
const BUTTON_HOVER: Texture2D = preload("res://assets/ui/buttons/button_menu_hover.png")
const BUTTON_PRESSED: Texture2D = preload("res://assets/ui/buttons/button_menu_pressed.png")
const BUTTON_REGION: Rect2 = Rect2(145, 350, 1245, 289)

var _loading_icon: Sprite2D
var _loading_label: Label
var _loading_timer: Timer
var _loading_text_timer: Timer
var _loading_frame: int = 0
var _loading_dot_count: int = 1

func _ready() -> void:
	_setup_base_ui()
	_setup_loading_ui()
	await get_tree().create_timer(1.5).timeout
	_show_main_menu_ui()

func _setup_base_ui() -> void:
	for child in get_children():
		child.queue_free()

	var bg: Sprite2D = Sprite2D.new()
	bg.texture = MENU_BG
	bg.centered = false
	bg.position = Vector2.ZERO
	bg.scale = Vector2(1280.0 / MENU_BG.get_width(), 720.0 / MENU_BG.get_height())
	add_child(bg)

	var shade: ColorRect = ColorRect.new()
	shade.size = Vector2(1280, 720)
	shade.color = Color(0, 0, 0, 0.18)
	add_child(shade)

	var logo: Sprite2D = Sprite2D.new()
	logo.texture = LOGO_TEXTURE
	logo.position = Vector2(640, 230)
	logo.scale = Vector2(0.215, 0.215)
	add_child(logo)

func _setup_loading_ui() -> void:
	_loading_icon = Sprite2D.new()
	_loading_icon.texture = LOADING_TEXTURE
	_loading_icon.region_enabled = true
	_loading_icon.region_rect = Rect2(0, 0, 128, 128)
	_loading_icon.position = Vector2(640, 470)
	_loading_icon.scale = Vector2(0.7, 0.7)
	add_child(_loading_icon)

	_loading_label = Label.new()
	_loading_label.text = "Loading."
	_loading_label.position = Vector2(540, 540)
	_loading_label.size = Vector2(200, 36)
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.add_theme_font_size_override("font_size", 24)
	_loading_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	_loading_label.add_theme_color_override("font_shadow_color", Color(0.18, 0.1, 0.03, 0.9))
	_loading_label.add_theme_constant_override("shadow_offset_x", 2)
	_loading_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_loading_label)

	_loading_timer = Timer.new()
	_loading_timer.wait_time = 0.18
	_loading_timer.autostart = true
	_loading_timer.timeout.connect(_on_loading_frame_timeout)
	add_child(_loading_timer)

	_loading_text_timer = Timer.new()
	_loading_text_timer.wait_time = 0.35
	_loading_text_timer.autostart = true
	_loading_text_timer.timeout.connect(_on_loading_text_timeout)
	add_child(_loading_text_timer)

func _show_main_menu_ui() -> void:
	_loading_timer.queue_free()
	_loading_text_timer.queue_free()
	_loading_icon.queue_free()
	_loading_label.queue_free()

	var menu: VBoxContainer = VBoxContainer.new()
	menu.position = Vector2(475, 400)
	menu.size = Vector2(330, 180)
	menu.add_theme_constant_override("separation", 14)
	menu.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(menu)

	var start_btn: Button = Button.new()
	start_btn.text = "开始游戏"
	start_btn.custom_minimum_size = Vector2(330, 78)
	_apply_menu_button_style(start_btn, 28)
	start_btn.pressed.connect(_on_start_pressed)
	menu.add_child(start_btn)

	var exit_btn: Button = Button.new()
	exit_btn.text = "退出游戏"
	exit_btn.custom_minimum_size = Vector2(330, 78)
	_apply_menu_button_style(exit_btn, 28)
	exit_btn.pressed.connect(_on_exit_pressed)
	menu.add_child(exit_btn)

func _apply_menu_button_style(button: Button, font_size: int) -> void:
	button.add_theme_stylebox_override("normal", _make_button_style(BUTTON_NORMAL))
	button.add_theme_stylebox_override("hover", _make_button_style(BUTTON_HOVER))
	button.add_theme_stylebox_override("pressed", _make_button_style(BUTTON_PRESSED))
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(1.0, 0.9, 0.48))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.62))
	button.add_theme_color_override("font_pressed_color", Color(0.95, 0.76, 0.35))
	button.add_theme_color_override("font_shadow_color", Color(0.2, 0.08, 0.02, 0.95))
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
	return style

func _on_loading_frame_timeout() -> void:
	_loading_frame = (_loading_frame + 1) % 4
	_loading_icon.region_rect = Rect2(_loading_frame * 128, 0, 128, 128)

func _on_loading_text_timeout() -> void:
	_loading_dot_count = _loading_dot_count % 3 + 1
	_loading_label.text = "Loading" + ".".repeat(_loading_dot_count)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
