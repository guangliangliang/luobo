extends Control

var _level_buttons: Dictionary = {}

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.1, 0.2, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var center: VBoxContainer = VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.offset_left = -220
	center.offset_top = -160
	center.offset_right = 220
	center.offset_bottom = 160
	center.add_theme_constant_override("separation", 20)
	add_child(center)
	
	var title: Label = Label.new()
	title.text = "选择关卡"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)
	
	var levels_hbox: HBoxContainer = HBoxContainer.new()
	levels_hbox.add_theme_constant_override("separation", 30)
	levels_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(levels_hbox)
	
	var level_configs: Array = [
		{"id": 1, "name": "第一关\n村口防线"},
		{"id": 2, "name": "第二关\n十字交叉"},
	]
	
	for cfg: Dictionary in level_configs:
		var btn: Button = Button.new()
		btn.text = cfg.name
		btn.custom_minimum_size = Vector2(180, 110)
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(_on_level_pressed.bind(cfg.id))
		levels_hbox.add_child(btn)
		_level_buttons[cfg.id] = btn
	
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	center.add_child(spacer)
	
	var back_btn: Button = Button.new()
	back_btn.text = "返回菜单"
	back_btn.custom_minimum_size = Vector2(180, 50)
	back_btn.add_theme_font_size_override("font_size", 22)
	back_btn.pressed.connect(_on_back_pressed)
	center.add_child(back_btn)
	
	_update_buttons()

func _update_buttons() -> void:
	for id: int in _level_buttons:
		var btn: Button = _level_buttons[id]
		if id <= SaveManager.unlock_level:
			btn.disabled = false
			btn.modulate = Color.WHITE
		else:
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5, 1.0)

func _on_level_pressed(level_id: int) -> void:
	GameManager.current_level_id = level_id
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
