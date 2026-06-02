extends Control

signal close_pressed

func _ready() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(600, 450)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.96, 0.7, 0.3)
	panel_style.corner_radius_top_left = 24
	panel_style.corner_radius_top_right = 24
	panel_style.corner_radius_bottom_left = 24
	panel_style.corner_radius_bottom_right = 24
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(1, 0.85, 0.2)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	panel.anchors_preset = Control.PRESET_CENTER
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(560, 410)
	panel.add_child(vbox)
	vbox.anchors_preset = Control.PRESET_CENTER
	
	var close_btn = Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(50, 50)
	close_btn.add_theme_font_size_override("font_size", 32)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.9, 0.2, 0.4)
	close_style.corner_radius_top_left = 12
	close_style.corner_radius_top_right = 12
	close_style.corner_radius_bottom_left = 12
	close_style.corner_radius_bottom_right = 12
	close_style.border_width_left = 2
	close_style.border_width_top = 2
	close_style.border_width_right = 2
	close_style.border_width_bottom = 2
	close_style.border_color = Color.WHITE
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.pressed.connect(func(): close_pressed.emit())
	close_btn.anchor_right = 1
	close_btn.anchor_left = 1
	close_btn.offset_left = -60
	close_btn.offset_top = 10
	panel.add_child(close_btn)
	
	var tab_hbox = HBoxContainer.new()
	tab_hbox.add_theme_constant_override("separation", 10)
	tab_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(tab_hbox)
	
	var tower_btn = Button.new()
	tower_btn.text = "炮塔"
	tower_btn.custom_minimum_size = Vector2(150, 50)
	tower_btn.add_theme_font_size_override("font_size", 22)
	tab_hbox.add_child(tower_btn)
	
	var enemy_btn = Button.new()
	enemy_btn.text = "敌人"
	enemy_btn.custom_minimum_size = Vector2(150, 50)
	enemy_btn.add_theme_font_size_override("font_size", 22)
	tab_hbox.add_child(enemy_btn)
	
	var content = VBoxContainer.new()
	content.custom_minimum_size = Vector2(520, 300)
	var content_style = StyleBoxFlat.new()
	content_style.bg_color = Color(0.98, 0.92, 0.82)
	content_style.corner_radius_top_left = 16
	content_style.corner_radius_top_right = 16
	content_style.corner_radius_bottom_left = 16
	content_style.corner_radius_bottom_right = 16
	content_style.border_width_left = 2
	content_style.border_width_top = 2
	content_style.border_width_right = 2
	content_style.border_width_bottom = 2
	content_style.border_color = Color(0.7, 0.45, 0.2)
	content.add_theme_stylebox_override("panel", content_style)
	vbox.add_child(content)
	
	var label1 = Label.new()
	label1.text = "炮塔说明：\n1. 瓶子炮：单体攻击，价格100金币，适合普通小怪\n2. 风扇炮塔：范围攻击，价格150金币，适合群体小怪\n3. 冰冻炮塔：减速效果，价格120金币，适合快速小怪"
	label1.add_theme_font_size_override("font_size", 20)
	label1.add_theme_color_override("font_color", Color(0.4, 0.2, 0.1))
	content.add_child(label1)
