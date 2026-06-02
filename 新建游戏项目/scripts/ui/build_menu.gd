extends Control

signal tower_selected(tower_type: String)
signal cancel_pressed

const MENU_SIZE: Vector2 = Vector2(320, 132)
const TOWER_TYPES: Array[String] = ["arrow", "cannon", "ice"]

var _buttons: Dictionary = {}
var _cost_labels: Dictionary = {}

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	size = MENU_SIZE
	custom_minimum_size = MENU_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.custom_minimum_size = MENU_SIZE
	add_child(panel)
	
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 12
	hbox.offset_top = 12
	hbox.offset_right = -12
	hbox.offset_bottom = -12
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)
	
	for tower_type: String in TOWER_TYPES:
		var td: TowerData = GameManager.get_tower_data(tower_type)
		if not td:
			continue
		var button: Button = _create_tower_button(tower_type, td)
		hbox.add_child(button)
		_buttons[tower_type] = button
	
	_update_button_states()

func _create_tower_button(tower_type: String, td: TowerData) -> Button:
	var button: Button = Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(88, 108)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_on_tower_btn_pressed.bind(tower_type))
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 6
	vbox.offset_top = 6
	vbox.offset_right = -6
	vbox.offset_bottom = -6
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	button.add_child(vbox)
	
	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(56, 58)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _load_tower_icon(tower_type)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon)
	
	var cost_label: Label = Label.new()
	cost_label.text = "%d金币" % td.cost
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 16)
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(cost_label)
	_cost_labels[tower_type] = cost_label
	
	return button

func _load_tower_icon(tower_type: String) -> Texture2D:
	var texture_path: String = ""
	match tower_type:
		"arrow":
			texture_path = "res://assets/towers/tower_lv1_transparent.png"
		"cannon":
			texture_path = "res://assets/towers/cannon_tower_lv1_transparent.png"
		"ice":
			texture_path = "res://assets/towers/ice_tower_lv1.png_transparent.png"
		_:
			return null
	return load(texture_path) as Texture2D

func _on_tower_btn_pressed(tower_type: String) -> void:
	var td: TowerData = GameManager.get_tower_data(tower_type)
	if td and GameManager.current_gold >= td.cost:
		tower_selected.emit(tower_type)
	else:
		_update_button_states()

func _update_button_states() -> void:
	for tower_type: String in _buttons:
		var td: TowerData = GameManager.get_tower_data(tower_type)
		if td:
			var can_afford: bool = GameManager.current_gold >= td.cost
			_buttons[tower_type].disabled = not can_afford
			if _cost_labels.has(tower_type):
				var cost_label: Label = _cost_labels[tower_type]
				cost_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.25) if can_afford else Color(0.55, 0.55, 0.55))

func show_at(pos: Vector2) -> void:
	var screen_size: Vector2 = get_viewport_rect().size
	position = pos
	if position.x + MENU_SIZE.x > screen_size.x:
		position.x = screen_size.x - MENU_SIZE.x - 10
	if position.y + MENU_SIZE.y > screen_size.y:
		position.y = screen_size.y - MENU_SIZE.y - 10
	position.x = maxf(10.0, position.x)
	position.y = maxf(10.0, position.y)
	_update_button_states()
	visible = true

func hide_menu() -> void:
	visible = false
