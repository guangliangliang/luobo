extends Control

const MENU_BG: Texture2D = preload("res://assets/ui/menu/menu_bg_village.png")
const LOGO_TEXTURE: Texture2D = preload("res://assets/ui/menu/logo_village_defense.png")
const BUTTON_NORMAL: Texture2D = preload("res://assets/ui/buttons/button_menu_normal.png")
const BUTTON_HOVER: Texture2D = preload("res://assets/ui/buttons/button_menu_hover.png")
const BUTTON_PRESSED: Texture2D = preload("res://assets/ui/buttons/button_menu_pressed.png")
const LEVEL_CARD_NORMAL: Texture2D = preload("res://assets/ui/level_select/level_card_normal.png")
const LEVEL_CARD_HOVER: Texture2D = preload("res://assets/ui/level_select/level_card_hover.png")
const LEVEL_CARD_LOCKED: Texture2D = preload("res://assets/ui/level_select/level_card_locked.png")
const LEVEL_PREVIEW_SCENE: PackedScene = preload("res://scenes/LevelPreview.tscn")
const BACK_BUTTON_TEXTURE: Texture2D = preload("res://assets/ui/icons/icon_back_turn.svg")
const BUTTON_REGION: Rect2 = Rect2(72.5, 175, 622.5, 144.5)
const LEVEL_TEXT_NORMAL: Color = Color(0.28, 0.12, 0.02)
const LEVEL_TEXT_HOVER: Color = Color(0.18, 0.08, 0.01)
const LEVEL_TEXT_SELECTED: Color = Color(0.72, 0.26, 0.02)
const DRAG_THRESHOLD: float = 8.0
const CONTENT_MAX_WIDTH: float = 1040.0
const CONTENT_MARGIN: float = 24.0
const BACK_BUTTON_SIZE: Vector2 = Vector2(68, 68)
const BACK_BUTTON_MARGIN: float = 22.0

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
	var viewport_size: Vector2 = get_viewport_rect().size
	var horizontal_margin: float = maxf(CONTENT_MARGIN, (viewport_size.x - CONTENT_MAX_WIDTH) * 0.5)

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
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = horizontal_margin
	center.offset_top = 20
	center.offset_right = -horizontal_margin
	center.offset_bottom = -20
	center.add_theme_constant_override("separation", 10)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(center)

	var logo: TextureRect = TextureRect.new()
	logo.texture = LOGO_TEXTURE
	logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(0, 140)
	logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_child(logo)

	_level_scroll = ScrollContainer.new()
	_level_scroll.custom_minimum_size = Vector2(0, 320)
	_level_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_level_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_level_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_level_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(_level_scroll)

	var levels_hbox: HBoxContainer = HBoxContainer.new()
	levels_hbox.custom_minimum_size = Vector2(0, 280)
	levels_hbox.add_theme_constant_override("separation", 18)
	levels_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_level_scroll.add_child(levels_hbox)

	var level_ids: Array = GameManager.level_datas.keys()
	level_ids.sort()
	for level_id: int in level_ids:
		var level_data: LevelData = GameManager.get_level_data(level_id)
		if not level_data:
			continue
		var btn: Button = Button.new()
		btn.text = ""
		btn.custom_minimum_size = Vector2(340, 260)
		_apply_level_button_style(btn)
		btn.pressed.connect(_on_level_pressed.bind(level_id))
		
		var card_container: Control = Control.new()
		card_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(card_container)
		
		var thumbnail: Control = _generate_level_thumbnail(level_data)
		thumbnail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		thumbnail.offset_left = 40
		thumbnail.offset_top = 30
		thumbnail.offset_right = -40
		thumbnail.offset_bottom = -70
		card_container.add_child(thumbnail)
		
		var level_name_label: Label = Label.new()
		level_name_label.text = "第%d关\n%s" % [level_id, level_data.level_name]
		level_name_label.add_theme_font_size_override("font_size", 24)
		level_name_label.add_theme_color_override("font_color", Color(0.3, 0.12, 0.02))
		level_name_label.add_theme_color_override("font_outline_color", Color(1.0, 0.9, 0.6))
		level_name_label.add_theme_constant_override("outline_size", 4)
		level_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_name_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		level_name_label.offset_top = 160
		level_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_container.add_child(level_name_label)
		
		levels_hbox.add_child(btn)
		_level_buttons[level_id] = btn

	add_child(_create_back_icon_button("返回菜单"))
	_update_buttons()

func _create_back_icon_button(tooltip: String) -> Button:
	var button: Button = Button.new()
	button.text = ""
	button.tooltip_text = ""
	button.custom_minimum_size = BACK_BUTTON_SIZE
	button.size = BACK_BUTTON_SIZE
	button.position = Vector2(BACK_BUTTON_MARGIN, BACK_BUTTON_MARGIN)
	button.focus_mode = Control.FOCUS_NONE
	_apply_back_icon_button_style(button)
	button.pressed.connect(_on_back_pressed)

	var icon: TextureRect = TextureRect.new()
	icon.texture = BACK_BUTTON_TEXTURE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	button.add_child(icon)
	return button

func _apply_back_icon_button_style(button: Button) -> void:
	var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", empty_style)
	button.add_theme_stylebox_override("pressed", empty_style)
	button.add_theme_stylebox_override("focus", empty_style)

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
	style.set_texture_margin(SIDE_LEFT, 28)
	style.set_texture_margin(SIDE_RIGHT, 28)
	style.set_texture_margin(SIDE_TOP, 10)
	style.set_texture_margin(SIDE_BOTTOM, 10)
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
	get_tree().change_scene_to_packed(LEVEL_PREVIEW_SCENE)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _generate_level_thumbnail(level_data: LevelData) -> Control:
	var container: Control = Control.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var padding_left: float = 20.0
	var padding_top: float = 15.0
	var padding_right: float = 20.0
	var padding_bottom: float = 15.0
	var map_width: float = 260.0 - padding_left - padding_right
	var map_height: float = 160.0 - padding_top - padding_bottom
	
	var original_width: float = 1280.0
	var original_height: float = 720.0
	var scale_x: float = map_width / original_width
	var scale_y: float = map_height / original_height
	var scale: float = min(scale_x, scale_y)
	
	for path_points: PackedVector2Array in level_data.path_points:
		if path_points.size() < 2:
			continue
		var line: Line2D = Line2D.new()
		line.width = level_data.path_width * scale
		line.default_color = level_data.path_color
		for point in path_points:
			var scaled_x: float = padding_left + point.x * scale
			var scaled_y: float = padding_top + point.y * scale
			line.add_point(Vector2(scaled_x, scaled_y))
		container.add_child(line)
	
	var village_icon: ColorRect = ColorRect.new()
	village_icon.color = Color(0.9, 0.3, 0.25, 1.0)
	village_icon.custom_minimum_size = Vector2(16, 16)
	var village_scaled_x: float = padding_left + level_data.village_position.x * scale
	var village_scaled_y: float = padding_top + level_data.village_position.y * scale
	village_icon.position = Vector2(village_scaled_x - 8, village_scaled_y - 8)
	container.add_child(village_icon)
	
	var village_icon_inner: ColorRect = ColorRect.new()
	village_icon_inner.color = Color(1.0, 0.8, 0.25, 1.0)
	village_icon_inner.custom_minimum_size = Vector2(8, 8)
	village_icon_inner.position = Vector2(village_scaled_x - 4, village_scaled_y - 4)
	container.add_child(village_icon_inner)
	
	return container
