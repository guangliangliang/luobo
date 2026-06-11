extends Control

const MENU_BG: Texture2D = preload("res://assets/ui/menu/menu_bg_village.png")
const LOGO_TEXTURE: Texture2D = preload("res://assets/ui/menu/logo_village_defense.png")
const BUTTON_NORMAL: Texture2D = preload("res://assets/ui/buttons/button_menu_normal.png")
const BUTTON_HOVER: Texture2D = preload("res://assets/ui/buttons/button_menu_hover.png")
const BUTTON_PRESSED: Texture2D = preload("res://assets/ui/buttons/button_menu_pressed.png")
const LEVEL_CARD_NORMAL: Texture2D = preload("res://assets/ui/level_select/level_card_normal.png")
const LEVEL_CARD_HOVER: Texture2D = preload("res://assets/ui/level_select/level_card_hover.png")
const LEVEL_CARD_LOCKED: Texture2D = preload("res://assets/ui/level_select/level_card_locked.png")
const BATTLE_SCENE: PackedScene = preload("res://scenes/Battle.tscn")
const BUTTON_REGION: Rect2 = Rect2(145, 350, 1245, 289)
const LEVEL_TEXT_NORMAL: Color = Color(0.28, 0.12, 0.02)
const LEVEL_TEXT_HOVER: Color = Color(0.18, 0.08, 0.01)
const LEVEL_TEXT_SELECTED: Color = Color(0.72, 0.26, 0.02)
const DRAG_THRESHOLD: float = 8.0

var _level_buttons: Dictionary = {}
var _level_scroll: ScrollContainer
var _dragging_levels: bool = false
var _drag_start_x: float = 0.0
var _drag_start_scroll: int = 0
var _drag_moved: bool = false
var _suppress_press_until_ms: int = 0

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
	shade.color = Color(0, 0, 0, 0.2)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var center: VBoxContainer = VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.offset_left = -520
	center.offset_top = -285
	center.offset_right = 520
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

	_level_scroll = ScrollContainer.new()
	_level_scroll.custom_minimum_size = Vector2(980, 172)
	_level_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_level_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_level_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(_level_scroll)

	var levels_hbox: HBoxContainer = HBoxContainer.new()
	levels_hbox.custom_minimum_size = Vector2(0, 158)
	levels_hbox.add_theme_constant_override("separation", 26)
	levels_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_level_scroll.add_child(levels_hbox)

	var level_configs: Array = [
		{"id": 1, "name": "第一关\n村口防线"},
		{"id": 2, "name": "第二关\n分兵两路"},
		{"id": 3, "name": "第三关\n林间岔口"},
		{"id": 4, "name": "第四关\n盗匪急袭"},
		{"id": 5, "name": "第五关\n环村小路"},
		{"id": 6, "name": "第六关\n南北夹击"},
		{"id": 7, "name": "第七关\n三面围攻"},
		{"id": 8, "name": "第八关\n最后防线"},
	]

	for cfg: Dictionary in level_configs:
		var btn: Button = Button.new()
		btn.text = cfg.name
		btn.custom_minimum_size = Vector2(246, 150)
		_apply_level_button_style(btn)
		btn.pressed.connect(_on_level_pressed.bind(cfg.id))
		levels_hbox.add_child(btn)
		_level_buttons[cfg.id] = btn

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 14)
	center.add_child(spacer)

	var back_btn: Button = Button.new()
	back_btn.text = "返回菜单"
	back_btn.custom_minimum_size = Vector2(252, 78)
	_apply_menu_button_style(back_btn, 22)
	back_btn.pressed.connect(_on_back_pressed)
	center.add_child(back_btn)

	_update_buttons()

func _apply_menu_button_style(button: Button, font_size: int) -> void:
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _make_menu_button_style(BUTTON_NORMAL))
	button.add_theme_stylebox_override("hover", _make_menu_button_style(BUTTON_HOVER))
	button.add_theme_stylebox_override("pressed", _make_menu_button_style(BUTTON_PRESSED))
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(1.0, 0.9, 0.48))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.62))
	button.add_theme_color_override("font_pressed_color", Color(0.95, 0.76, 0.35))
	button.add_theme_color_override("font_outline_color", Color(0.36, 0.12, 0.02, 0.95))
	button.add_theme_color_override("font_shadow_color", Color(0.2, 0.08, 0.02, 0.95))
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)

func _apply_level_button_style(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _make_level_card_style(LEVEL_CARD_NORMAL))
	button.add_theme_stylebox_override("hover", _make_level_card_style(LEVEL_CARD_HOVER))
	button.add_theme_stylebox_override("pressed", _make_level_card_style(LEVEL_CARD_HOVER))
	button.add_theme_stylebox_override("disabled", _make_level_card_style(LEVEL_CARD_LOCKED))
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_color_override("font_color", LEVEL_TEXT_NORMAL)
	button.add_theme_color_override("font_hover_color", LEVEL_TEXT_HOVER)
	button.add_theme_color_override("font_pressed_color", LEVEL_TEXT_SELECTED)
	button.add_theme_color_override("font_hover_pressed_color", LEVEL_TEXT_SELECTED)
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
	style.set_content_margin(SIDE_LEFT, 58)
	style.set_content_margin(SIDE_RIGHT, 58)
	style.set_content_margin(SIDE_TOP, 16)
	style.set_content_margin(SIDE_BOTTOM, 20)
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

func _input(event: InputEvent) -> void:
	if not _level_scroll:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and _level_scroll.get_global_rect().has_point(mouse_event.position):
			_dragging_levels = true
			_drag_moved = false
			_drag_start_x = mouse_event.position.x
			_drag_start_scroll = _level_scroll.scroll_horizontal
		elif not mouse_event.pressed and _dragging_levels:
			if _drag_moved:
				_suppress_press_until_ms = Time.get_ticks_msec() + 160
			_dragging_levels = false
	elif event is InputEventMouseMotion and _dragging_levels:
		var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		var delta_x: float = motion_event.position.x - _drag_start_x
		if absf(delta_x) > DRAG_THRESHOLD:
			_drag_moved = true
		if _drag_moved:
			_level_scroll.scroll_horizontal = max(0, _drag_start_scroll - int(delta_x))
			accept_event()
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		if touch_event.pressed and _level_scroll.get_global_rect().has_point(touch_event.position):
			_dragging_levels = true
			_drag_moved = false
			_drag_start_x = touch_event.position.x
			_drag_start_scroll = _level_scroll.scroll_horizontal
		elif not touch_event.pressed and _dragging_levels:
			if _drag_moved:
				_suppress_press_until_ms = Time.get_ticks_msec() + 160
			_dragging_levels = false
	elif event is InputEventScreenDrag and _dragging_levels:
		var drag_event: InputEventScreenDrag = event as InputEventScreenDrag
		var delta_touch_x: float = drag_event.position.x - _drag_start_x
		if absf(delta_touch_x) > DRAG_THRESHOLD:
			_drag_moved = true
		if _drag_moved:
			_level_scroll.scroll_horizontal = max(0, _drag_start_scroll - int(delta_touch_x))
			accept_event()

func _on_level_pressed(level_id: int) -> void:
	if Time.get_ticks_msec() < _suppress_press_until_ms:
		return
	GameManager.current_level_id = level_id
	get_tree().change_scene_to_packed(BATTLE_SCENE)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
