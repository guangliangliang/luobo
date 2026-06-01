extends Control

signal start_wave_pressed
signal back_pressed

var _gold_label: Label
var _health_label: Label
var _wave_label: Label
var _monster_label: Label
var _start_wave_btn: Button
var _back_btn: Button

func _ready() -> void:
	_setup_ui()
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.village_health_changed.connect(_on_health_changed)

func _setup_ui() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	
	var top_bar: ColorRect = ColorRect.new()
	top_bar.color = Color(0, 0, 0, 0.6)
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size = Vector2(0, 60)
	add_child(top_bar)
	
	var h_box: HBoxContainer = HBoxContainer.new()
	h_box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	h_box.offset_top = 12
	h_box.offset_left = 20
	h_box.offset_right = -20
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
	
	_start_wave_btn = Button.new()
	_start_wave_btn.text = "开始波次"
	_start_wave_btn.anchor_left = 1.0
	_start_wave_btn.anchor_top = 1.0
	_start_wave_btn.anchor_right = 1.0
	_start_wave_btn.anchor_bottom = 1.0
	_start_wave_btn.offset_left = -200
	_start_wave_btn.offset_top = -75
	_start_wave_btn.offset_right = -15
	_start_wave_btn.offset_bottom = -15
	_start_wave_btn.add_theme_font_size_override("font_size", 24)
	_start_wave_btn.pressed.connect(func(): start_wave_pressed.emit())
	add_child(_start_wave_btn)
	
	_back_btn = Button.new()
	_back_btn.text = "返回"
	_back_btn.anchor_left = 0.0
	_back_btn.anchor_top = 1.0
	_back_btn.anchor_right = 0.0
	_back_btn.anchor_bottom = 1.0
	_back_btn.offset_left = 15
	_back_btn.offset_top = -75
	_back_btn.offset_right = 145
	_back_btn.offset_bottom = -15
	_back_btn.add_theme_font_size_override("font_size", 24)
	_back_btn.pressed.connect(func(): back_pressed.emit())
	add_child(_back_btn)

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

func update_start_button(can_start: bool, all_done: bool) -> void:
	if not _start_wave_btn:
		return
	if all_done:
		_start_wave_btn.text = "已完成"
		_start_wave_btn.disabled = true
	elif can_start:
		_start_wave_btn.text = "开始波次"
		_start_wave_btn.disabled = false
	else:
		_start_wave_btn.text = "进行中..."
		_start_wave_btn.disabled = true

func _on_gold_changed(new_gold: int) -> void:
	update_gold(new_gold)

func _on_health_changed(new_health: int) -> void:
	update_health(new_health)
