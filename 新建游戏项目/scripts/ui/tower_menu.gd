extends Control

signal upgrade_pressed
signal sell_pressed
signal cancel_pressed

var _tower: Node2D
var _upgrade_btn: Button
var _sell_btn: Button
var _info_label: Label

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(250, 300)
	add_child(panel)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.offset_top = 10
	vbox.offset_left = 10
	vbox.offset_right = 240
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	_info_label = Label.new()
	_info_label.add_theme_font_size_override("font_size", 18)
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_label.custom_minimum_size = Vector2(220, 110)
	vbox.add_child(_info_label)
	
	_upgrade_btn = Button.new()
	_upgrade_btn.custom_minimum_size = Vector2(220, 50)
	_upgrade_btn.add_theme_font_size_override("font_size", 20)
	_upgrade_btn.pressed.connect(func(): upgrade_pressed.emit())
	vbox.add_child(_upgrade_btn)
	
	_sell_btn = Button.new()
	_sell_btn.custom_minimum_size = Vector2(220, 50)
	_sell_btn.add_theme_font_size_override("font_size", 20)
	_sell_btn.pressed.connect(func(): sell_pressed.emit())
	vbox.add_child(_sell_btn)
	
	var cancel_btn: Button = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(220, 45)
	cancel_btn.add_theme_font_size_override("font_size", 20)
	cancel_btn.pressed.connect(func(): cancel_pressed.emit())
	vbox.add_child(cancel_btn)

func show_for_tower(tower: Node2D, pos: Vector2) -> void:
	_tower = tower
	_update_info()
	
	position = pos
	var screen_size: Vector2 = get_viewport_rect().size
	if position.x + 250 > screen_size.x:
		position.x = screen_size.x - 260
	if position.y + 300 > screen_size.y:
		position.y = screen_size.y - 310
	
	visible = true

func _update_info() -> void:
	if not _tower or not is_instance_valid(_tower):
		hide_menu()
		return
	
	var td: TowerData = _tower.tower_data
	var level: int = _tower.tower_level
	
	var info: String = "%s Lv.%d\n" % [td.tower_name, level]
	info += "伤害: %.0f\n" % _tower.get_damage()
	info += "间隔: %.1fs\n" % _tower.get_attack_interval()
	info += "射程: %.0f" % _tower.get_attack_range()
	
	if _tower.tower_type == "cannon":
		info += "\n范围: %.0f" % _tower.get_splash_radius()
	elif _tower.tower_type == "ice":
		info += "\n减速: %.0f%%" % (_tower.get_slow_percent() * 100)
	
	_info_label.text = info
	
	if _tower.can_upgrade():
		var cost: int = _tower.get_upgrade_cost()
		_upgrade_btn.text = "升级 (%d金币)" % cost
		_upgrade_btn.disabled = GameManager.current_gold < cost
	else:
		_upgrade_btn.text = "已满级"
		_upgrade_btn.disabled = true
	
	var sell_value: int = int(_tower._total_invested * GameManager.config.tower_sell_return_rate)
	_sell_btn.text = "出售 (+%d金币)" % sell_value

func get_tower() -> Node2D:
	return _tower

func hide_menu() -> void:
	_tower = null
	visible = false
