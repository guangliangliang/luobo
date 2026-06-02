extends Control

signal exit_level_pressed
signal level_info_pressed
signal restart_level_pressed
signal continue_pressed

var _bg: ColorRect
var _panel: Panel
var _bgm_slider: HSlider
var _bgm_label: Label
var _is_paused: bool = false

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.7)
	_bg.anchors_preset = Control.PRESET_FULL_RECT
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg)
	
	_panel = Panel.new()
	_panel.custom_minimum_size = Vector2(400, 450)
	_panel.add_theme_stylebox_override("panel", _create_panel_stylebox())
	add_child(_panel)
	_panel.anchors_preset = Control.PRESET_CENTER
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(360, 410)
	_panel.add_child(vbox)
	vbox.anchors_preset = Control.PRESET_CENTER
	
	var title_label: Label = Label.new()
	title_label.text = "游戏设置"
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	var sep1: HSeparator = HSeparator.new()
	vbox.add_child(sep1)
	
	var bgm_vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_child(bgm_vbox)
	bgm_vbox.add_theme_constant_override("separation", 10)
	
	var bgm_title: Label = Label.new()
	bgm_title.text = "背景音乐"
	bgm_title.add_theme_font_size_override("font_size", 20)
	bgm_vbox.add_child(bgm_title)
	
	_bgm_slider = HSlider.new()
	_bgm_slider.min_value = 0.0
	_bgm_slider.max_value = 1.0
	_bgm_slider.step = 0.01
	_bgm_slider.value = AudioManager.get_bgm_volume() if AudioManager else 0.5
	_bgm_slider.value_changed.connect(_on_bgm_volume_changed)
	bgm_vbox.add_child(_bgm_slider)
	
	_bgm_label = Label.new()
	_bgm_label.text = "音量: %d%%" % int(_bgm_slider.value * 100)
	_bgm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bgm_vbox.add_child(_bgm_label)
	
	var sep2: HSeparator = HSeparator.new()
	vbox.add_child(sep2)
	
	var btn_size: Vector2 = Vector2(300, 50)
	
	var continue_btn: Button = Button.new()
	continue_btn.text = "继续游戏"
	continue_btn.custom_minimum_size = btn_size
	continue_btn.add_theme_font_size_override("font_size", 22)
	continue_btn.pressed.connect(func(): continue_pressed.emit())
	vbox.add_child(continue_btn)
	_align_button_center(continue_btn, vbox)
	
	var info_btn: Button = Button.new()
	info_btn.text = "本关说明"
	info_btn.custom_minimum_size = btn_size
	info_btn.add_theme_font_size_override("font_size", 22)
	info_btn.pressed.connect(func(): level_info_pressed.emit())
	vbox.add_child(info_btn)
	_align_button_center(info_btn, vbox)
	
	var restart_btn: Button = Button.new()
	restart_btn.text = "重新开始"
	restart_btn.custom_minimum_size = btn_size
	restart_btn.add_theme_font_size_override("font_size", 22)
	restart_btn.pressed.connect(func(): restart_level_pressed.emit())
	vbox.add_child(restart_btn)
	_align_button_center(restart_btn, vbox)
	
	var exit_btn: Button = Button.new()
	exit_btn.text = "退出本关"
	exit_btn.custom_minimum_size = btn_size
	exit_btn.add_theme_font_size_override("font_size", 22)
	exit_btn.pressed.connect(func(): exit_level_pressed.emit())
	vbox.add_child(exit_btn)
	_align_button_center(exit_btn, vbox)

func _create_panel_stylebox() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.4)
	return style

func _align_button_center(btn: Button, parent: Container) -> void:
	var center: CenterContainer = CenterContainer.new()
	parent.remove_child(btn)
	center.add_child(btn)
	parent.add_child(center)

func _on_bgm_volume_changed(value: float) -> void:
	_bgm_label.text = "音量: %d%%" % int(value * 100)
	if AudioManager:
		AudioManager.set_bgm_volume(value)

func show_dialog(is_paused_state: bool) -> void:
	_is_paused = is_paused_state
	visible = true

func hide_dialog() -> void:
	visible = false
