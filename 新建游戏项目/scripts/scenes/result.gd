extends Control

const MENU_BG: Texture2D = preload("res://assets/ui/menu/menu_bg_village.png")
const LOGO_TEXTURE: Texture2D = preload("res://assets/ui/menu/logo_village_defense.png")
const BUTTON_NORMAL: Texture2D = preload("res://assets/ui/buttons/button_menu_normal.png")
const BUTTON_HOVER: Texture2D = preload("res://assets/ui/buttons/button_menu_hover.png")
const BUTTON_PRESSED: Texture2D = preload("res://assets/ui/buttons/button_menu_pressed.png")
const BUTTON_REGION: Rect2 = Rect2(145, 350, 1245, 289)

var _result_data: Dictionary = {}

func _ready() -> void:
	_result_data = GameManager.last_result
	_setup_ui()
	_update_display()

func set_result_data(data: Dictionary) -> void:
	_result_data = data
	_update_display()

func _setup_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg: TextureRect = TextureRect.new()
	bg.texture = MENU_BG
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0, 0, 0, 0.28)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var center: VBoxContainer = VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.offset_left = -360
	center.offset_top = -315
	center.offset_right = 360
	center.offset_bottom = 315
	center.add_theme_constant_override("separation", 8)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(center)

	var logo: TextureRect = TextureRect.new()
	logo.texture = LOGO_TEXTURE
	logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(350, 160)
	center.add_child(logo)

	var title: Label = Label.new()
	title.name = "ResultTitle"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_shadow_color", Color(0.18, 0.08, 0.02, 0.95))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)

	var stats: Label = Label.new()
	stats.name = "StatsLabel"
	stats.add_theme_font_size_override("font_size", 24)
	stats.add_theme_color_override("font_color", Color(1.0, 0.9, 0.48))
	stats.add_theme_color_override("font_shadow_color", Color(0.2, 0.08, 0.02, 0.95))
	stats.add_theme_constant_override("shadow_offset_x", 2)
	stats.add_theme_constant_override("shadow_offset_y", 2)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(stats)

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	center.add_child(spacer)

	var btn_vbox: VBoxContainer = VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 10)
	btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(btn_vbox)

	var next_btn: Button = Button.new()
	next_btn.name = "NextBtn"
	next_btn.text = "下一关"
	_apply_result_button_style(next_btn)
	next_btn.pressed.connect(_on_next)
	btn_vbox.add_child(next_btn)

	var restart_btn: Button = Button.new()
	restart_btn.text = "重新开始"
	_apply_result_button_style(restart_btn)
	restart_btn.pressed.connect(_on_restart)
	btn_vbox.add_child(restart_btn)

	var menu_btn: Button = Button.new()
	menu_btn.text = "返回菜单"
	_apply_result_button_style(menu_btn)
	menu_btn.pressed.connect(_on_menu)
	btn_vbox.add_child(menu_btn)

func _apply_result_button_style(button: Button) -> void:
	button.custom_minimum_size = Vector2(228, 68)
	_apply_menu_button_style(button, 23)

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
	style.set_content_margin(SIDE_LEFT, 54)
	style.set_content_margin(SIDE_RIGHT, 54)
	style.set_content_margin(SIDE_TOP, 14)
	style.set_content_margin(SIDE_BOTTOM, 18)
	return style

func _update_display() -> void:
	var won: bool = _result_data.get("won", false)
	var kills: int = _result_data.get("kill_count", 0)
	var gold: int = _result_data.get("gold_earned", 0)
	var level_id: int = _result_data.get("level_id", 1)

	var title: Label = get_node_or_null("ResultTitle") as Label
	if not title:
		title = _find_child_recursive(self, "ResultTitle") as Label
	if title:
		if won:
			title.text = "胜利！"
			title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.36))
		else:
			title.text = "失败"
			title.add_theme_color_override("font_color", Color(1.0, 0.42, 0.32))

	var stats: Label = _find_child_recursive(self, "StatsLabel") as Label
	if stats:
		stats.text = "击杀数量: %d\n获得金币: %d" % [kills, gold]

	var next_btn: Button = _find_child_recursive(self, "NextBtn") as Button
	if next_btn:
		var max_level: int = GameManager.level_datas.size()
		next_btn.visible = won and level_id < max_level

func _find_child_recursive(node: Node, name: String) -> Node:
	if node.name == name:
		return node
	for child in node.get_children():
		var found: Node = _find_child_recursive(child, name)
		if found:
			return found
	return null

func _on_restart() -> void:
	GameManager.current_level_id = _result_data.get("level_id", 1)
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")

func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_next() -> void:
	var next_id: int = _result_data.get("level_id", 1) + 1
	var max_level: int = GameManager.level_datas.size()
	if next_id <= max_level:
		GameManager.current_level_id = next_id
		get_tree().change_scene_to_file("res://scenes/Battle.tscn")
