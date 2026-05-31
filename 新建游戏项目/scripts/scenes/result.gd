extends Control

var _result_data: Dictionary = {}

func _ready() -> void:
	_result_data = GameManager.last_result
	_setup_ui()
	_update_display()

func set_result_data(data: Dictionary) -> void:
	_result_data = data
	_update_display()

func _setup_ui() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.08, 0.12, 0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var center: VBoxContainer = VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.offset_left = -180
	center.offset_top = -180
	center.offset_right = 180
	center.offset_bottom = 180
	center.add_theme_constant_override("separation", 20)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(center)
	
	var title: Label = Label.new()
	title.name = "ResultTitle"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)
	
	var stats: Label = Label.new()
	stats.name = "StatsLabel"
	stats.add_theme_font_size_override("font_size", 22)
	stats.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(stats)
	
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	center.add_child(spacer)
	
	var btn_hbox: HBoxContainer = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 20)
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(btn_hbox)
	
	var restart_btn: Button = Button.new()
	restart_btn.text = "重新开始"
	restart_btn.custom_minimum_size = Vector2(140, 50)
	restart_btn.add_theme_font_size_override("font_size", 20)
	restart_btn.pressed.connect(_on_restart)
	btn_hbox.add_child(restart_btn)
	
	var menu_btn: Button = Button.new()
	menu_btn.text = "返回菜单"
	menu_btn.custom_minimum_size = Vector2(140, 50)
	menu_btn.add_theme_font_size_override("font_size", 20)
	menu_btn.pressed.connect(_on_menu)
	btn_hbox.add_child(menu_btn)
	
	var next_btn: Button = Button.new()
	next_btn.name = "NextBtn"
	next_btn.text = "下一关"
	next_btn.custom_minimum_size = Vector2(140, 50)
	next_btn.add_theme_font_size_override("font_size", 20)
	next_btn.pressed.connect(_on_next)
	btn_hbox.add_child(next_btn)

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
			title.text = "胜利!"
			title.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3))
		else:
			title.text = "失败"
			title.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	
	var stats: Label = _find_child_recursive(self, "StatsLabel") as Label
	if stats:
		stats.text = "击杀数量: %d\n获得金币: %d" % [kills, gold]
	
	var next_btn: Button = _find_child_recursive(self, "NextBtn") as Button
	if next_btn:
		var max_level: int = GameManager.level_datas.size()
		if won and level_id < max_level:
			next_btn.visible = true
		else:
			next_btn.visible = false

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
