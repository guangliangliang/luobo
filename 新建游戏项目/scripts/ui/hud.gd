extends Control

signal pause_pressed
signal settings_pressed

var _gold_label: Label
var _health_label: Label
var _wave_label: Label
var _monster_label: Label
var _pause_btn: Button
var _settings_btn: Button

func _ready() -> void:
	_setup_ui()
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.village_health_changed.connect(_on_health_changed)

func _setup_ui() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	
	var top_bar: ColorRect = ColorRect.new()
	top_bar.color = Color(0, 0, 0, 0.6)
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size = Vector2(0, 70)
	top_bar.z_index = 100
	add_child(top_bar)
	
	var h_box: HBoxContainer = HBoxContainer.new()
	h_box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	h_box.offset_top = 15
	h_box.offset_left = 20
	h_box.offset_right = -120
	h_box.z_index = 101
	add_child(h_box)
	
	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 26)
	_gold_label.add_theme_color_override("font_color", Color.YELLOW)
	h_box.add_child(_gold_label)
	
	var sep1: Control = _make_spacer(30)
	h_box.add_child(sep1)
	
	_health_label = Label.new()
	_health_label.add_theme_font_size_override("font_size", 26)
	_health_label.add_theme_color_override("font_color", Color.RED)
	h_box.add_child(_health_label)
	
	var sep2: Control = _make_spacer(30)
	h_box.add_child(sep2)
	
	_wave_label = Label.new()
	_wave_label.add_theme_font_size_override("font_size", 26)
	_wave_label.add_theme_color_override("font_color", Color.WHITE)
	h_box.add_child(_wave_label)
	
	var sep3: Control = _make_spacer(30)
	h_box.add_child(sep3)
	
	_monster_label = Label.new()
	_monster_label.add_theme_font_size_override("font_size", 24)
	_monster_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	h_box.add_child(_monster_label)
	
	var buttons_hbox: HBoxContainer = HBoxContainer.new()
	buttons_hbox.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	buttons_hbox.offset_top = 15
	buttons_hbox.offset_right = -20
	buttons_hbox.z_index = 101
	add_child(buttons_hbox)
	
	_pause_btn = Button.new()
	_pause_btn.text = "暂停"
	_pause_btn.custom_minimum_size = Vector2(80, 40)
	_pause_btn.add_theme_font_size_override("font_size", 20)
	_pause_btn.pressed.connect(func(): pause_pressed.emit())
	buttons_hbox.add_child(_pause_btn)
	
	var btn_sep: Control = _make_spacer(10)
	buttons_hbox.add_child(btn_sep)
	
	_settings_btn = Button.new()
	_settings_btn.text = "设置"
	_settings_btn.custom_minimum_size = Vector2(80, 40)
	_settings_btn.add_theme_font_size_override("font_size", 20)
	_settings_btn.pressed.connect(func(): settings_pressed.emit())
	buttons_hbox.add_child(_settings_btn)

func _make_spacer(width: float) -> Control:
	var c: Control = Control.new()
	c.custom_minimum_size = Vector2(width, 0)
	return c

func update_gold(gold: int) -> void:
	if _gold_label:
		_gold_label.text = "金币: %d" % gold

func update_health(health: int) -> void:
	if _health_label:
		_health_label.text = "生命: %d" % health

func update_wave(current: int, total: int) -> void:
	if _wave_label:
		_wave_label.text = "波次: %d/%d" % [current, total]

func update_monster_count(count: int) -> void:
	if _monster_label:
		_monster_label.text = "剩余怪物: %d" % count

func update_pause_button(is_paused: bool) -> void:
	if _pause_btn:
		_pause_btn.text = "继续" if is_paused else "暂停"

func _on_gold_changed(new_gold: int) -> void:
	update_gold(new_gold)

func _on_health_changed(new_health: int) -> void:
	update_health(new_health)
