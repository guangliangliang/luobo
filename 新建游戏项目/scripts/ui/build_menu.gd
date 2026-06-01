extends Control

signal tower_selected(tower_type: String)
signal cancel_pressed

var _buttons: Dictionary = {}

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(0, 0)
	panel.custom_minimum_size = Vector2(250, 260)
	add_child(panel)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.offset_top = 10
	vbox.offset_left = 10
	vbox.offset_right = 240
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	var title: Label = Label.new()
	title.text = "建造防御塔"
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var tower_types: Array = ["arrow", "cannon", "ice"]
	var tower_names: Array = ["箭塔", "炮塔", "冰冻塔"]
	
	for i in range(tower_types.size()):
		var type: String = tower_types[i]
		var td: TowerData = GameManager.get_tower_data(type)
		if not td:
			continue
		var btn: Button = Button.new()
		btn.text = "%s (%d金币)" % [tower_names[i], td.cost]
		btn.custom_minimum_size = Vector2(220, 50)
		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(_on_tower_btn_pressed.bind(type))
		vbox.add_child(btn)
		_buttons[type] = btn
	
	var cancel_btn: Button = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(220, 45)
	cancel_btn.add_theme_font_size_override("font_size", 20)
	cancel_btn.pressed.connect(func(): cancel_pressed.emit())
	vbox.add_child(cancel_btn)
	
	_update_button_states()

func _on_tower_btn_pressed(type: String) -> void:
	var td: TowerData = GameManager.get_tower_data(type)
	if td and GameManager.current_gold >= td.cost:
		tower_selected.emit(type)
	else:
		_update_button_states()

func _update_button_states() -> void:
	for type: String in _buttons:
		var td: TowerData = GameManager.get_tower_data(type)
		if td:
			_buttons[type].disabled = GameManager.current_gold < td.cost

func show_at(pos: Vector2) -> void:
	var screen_size: Vector2 = get_viewport_rect().size
	position = pos
	if position.x + 250 > screen_size.x:
		position.x = screen_size.x - 260
	if position.y + 260 > screen_size.y:
		position.y = screen_size.y - 270
	_update_button_states()
	visible = true

func hide_menu() -> void:
	visible = false
