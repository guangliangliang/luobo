extends Control

signal upgrade_pressed
signal sell_pressed
signal cancel_pressed

const MENU_SIZE: Vector2 = Vector2(112, 212)

var _tower: Node2D
var _upgrade_btn: Button
var _sell_btn: Button

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	size = MENU_SIZE
	custom_minimum_size = MENU_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.custom_minimum_size = MENU_SIZE
	add_child(panel)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 10
	vbox.offset_top = 10
	vbox.offset_right = -10
	vbox.offset_bottom = -10
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	_upgrade_btn = _create_action_button()
	_upgrade_btn.pressed.connect(func(): upgrade_pressed.emit())
	vbox.add_child(_upgrade_btn)
	
	_sell_btn = _create_action_button()
	_sell_btn.pressed.connect(func(): sell_pressed.emit())
	vbox.add_child(_sell_btn)

func _create_action_button() -> Button:
	var button: Button = Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(92, 92)
	button.focus_mode = Control.FOCUS_NONE
	return button

func _set_button_content(button: Button, icon_text: String, state_text: String, color: Color) -> void:
	for child in button.get_children():
		button.remove_child(child)
		child.queue_free()
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_top = 8
	vbox.offset_bottom = -8
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	button.add_child(vbox)
	
	var icon_label: Label = Label.new()
	icon_label.text = icon_text
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 34)
	icon_label.add_theme_color_override("font_color", color)
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_label)
	
	var state_label: Label = Label.new()
	state_label.text = state_text
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.add_theme_font_size_override("font_size", 15)
	state_label.add_theme_color_override("font_color", color)
	state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(state_label)
	
func show_for_tower(tower: Node2D, pos: Vector2) -> void:
	_tower = tower
	_update_info()
	
	position = pos
	var screen_size: Vector2 = get_viewport_rect().size
	if position.x + MENU_SIZE.x > screen_size.x:
		position.x = screen_size.x - MENU_SIZE.x - 10
	if position.y + MENU_SIZE.y > screen_size.y:
		position.y = screen_size.y - MENU_SIZE.y - 10
	position.x = maxf(10.0, position.x)
	position.y = maxf(10.0, position.y)
	
	visible = true

func _update_info() -> void:
	if not _tower or not is_instance_valid(_tower):
		hide_menu()
		return
	
	if _tower.can_upgrade():
		var cost: int = _tower.get_upgrade_cost()
		var can_afford: bool = GameManager.current_gold >= cost
		var upgrade_color: Color = Color(1.0, 0.86, 0.25) if can_afford else Color(0.55, 0.55, 0.55)
		_upgrade_btn.disabled = not can_afford
		_set_button_content(_upgrade_btn, "↑", "%d金币" % cost, upgrade_color)
	else:
		_upgrade_btn.disabled = true
		_set_button_content(_upgrade_btn, "↑", "已满级", Color(0.55, 0.55, 0.55))
	
	_sell_btn.disabled = false
	_set_button_content(_sell_btn, "×", "移除", Color(1.0, 0.45, 0.35))

func get_tower() -> Node2D:
	return _tower

func hide_menu() -> void:
	_tower = null
	visible = false
