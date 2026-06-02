extends Node2D

signal tower_selected(tower: Node2D)

const PROJECTILE_SCRIPT: GDScript = preload("res://scripts/towers/projectile.gd")

static var _tower_texture_cache: Dictionary = {}

var tower_data: TowerData
var tower_level: int = 1
var tower_type: String = ""
var _attack_timer: float = 0.0
var _target: Node2D = null
var _range_circle_points: PackedVector2Array = []
var _show_range: bool = false
var _total_invested: int = 0
var _battle_root: Node = null
var _sprite: Sprite2D = null
var _upgrade_icon: Node2D = null
var _entrance_points: PackedVector2Array = []

func setup(type: String, data: TowerData) -> void:
	tower_type = type
	tower_data = data
	_total_invested = data.cost
	_attack_timer = 0.0
	_battle_root = get_tree().current_scene
	_setup_sprite()
	_setup_upgrade_icon()
	_get_entrance_points()
	_calculate_range_circle()
	set_process(true)
	queue_redraw()
	call_deferred("_set_initial_rotation")

func get_damage() -> float:
	var idx: int = mini(tower_level - 1, tower_data.damage.size() - 1)
	return tower_data.damage[idx]

func get_attack_interval() -> float:
	var idx: int = mini(tower_level - 1, tower_data.attack_interval.size() - 1)
	return tower_data.attack_interval[idx]

func get_attack_range() -> float:
	var idx: int = mini(tower_level - 1, tower_data.attack_range.size() - 1)
	return tower_data.attack_range[idx]

func get_splash_radius() -> float:
	var idx: int = mini(tower_level - 1, tower_data.splash_radius.size() - 1)
	return tower_data.splash_radius[idx]

func get_slow_percent() -> float:
	var idx: int = mini(tower_level - 1, tower_data.slow_percent.size() - 1)
	return tower_data.slow_percent[idx]

func get_slow_duration() -> float:
	var idx: int = mini(tower_level - 1, tower_data.slow_duration.size() - 1)
	return tower_data.slow_duration[idx]

func get_color() -> Color:
	var idx: int = mini(tower_level - 1, tower_data.colors.size() - 1)
	return tower_data.colors[idx]

func can_upgrade() -> bool:
	return tower_level < 3

func get_upgrade_cost() -> int:
	if tower_level >= tower_data.upgrade_cost.size():
		return 0
	return tower_data.upgrade_cost[tower_level]

func upgrade() -> void:
	if not can_upgrade():
		return
	var cost: int = get_upgrade_cost()
	if GameManager.spend_gold(cost):
		tower_level += 1
		_total_invested += cost
		AudioManager.play_sfx("upgrade")
		_update_sprite_texture()
		_update_upgrade_icon()
		_calculate_range_circle()
		queue_redraw()

func sell() -> void:
	var sell_value: int = int(_total_invested * GameManager.config.tower_sell_return_rate)
	GameManager.add_gold(sell_value)
	AudioManager.play_sfx("sell")
	queue_free()

func show_range(show: bool) -> void:
	_show_range = show
	queue_redraw()

func _calculate_range_circle() -> void:
	_range_circle_points.clear()
	var segments: int = 48
	var r: float = get_attack_range()
	for i in range(segments + 1):
		var angle: float = TAU * float(i) / float(segments)
		_range_circle_points.append(Vector2(cos(angle), sin(angle)) * r)

func _process(delta: float) -> void:
	if not GameManager.is_battle_active:
		return
	
	_attack_timer -= delta
	if _attack_timer <= 0:
		_find_target()
		if _target and is_instance_valid(_target):
			_shoot()
			_attack_timer = get_attack_interval()
		else:
			_attack_timer = 0.1

func _find_target() -> void:
	_target = null
	var spawner: Node = _find_spawner()
	if not spawner:
		return
	var monsters: Array = spawner.get_all_monsters()
	var best_progress: float = -1.0
	var range: float = get_attack_range()
	
	for monster in monsters:
		if not is_instance_valid(monster) or monster.is_dead:
			continue
		var dist: float = global_position.distance_to(monster.global_position)
		if dist <= range:
			if monster.progress_ratio > best_progress:
				best_progress = monster.progress_ratio
				_target = monster

func _find_spawner() -> Node:
	if _battle_root and is_instance_valid(_battle_root):
		return _battle_root.get_node_or_null("MonsterSpawner")
	return null

func _shoot() -> void:
	if not _target or not is_instance_valid(_target):
		return
	
	var projectile_start: Vector2 = _get_projectile_start_position()
	_aim_sprite_from_position(_target.global_position, projectile_start)
	var projectile: CharacterBody2D = CharacterBody2D.new()
	projectile.process_mode = Node.PROCESS_MODE_PAUSABLE
	projectile.set_script(PROJECTILE_SCRIPT)
	projectile.setup(
		projectile_start,
		_target,
		get_damage(),
		tower_data.projectile_speed,
		tower_type,
		get_splash_radius(),
		get_slow_percent(),
		get_slow_duration()
	)
	var battle: Node = _battle_root if (_battle_root and is_instance_valid(_battle_root)) else get_tree().current_scene
	battle.add_child(projectile)
	
	AudioManager.play_sfx("attack_" + tower_type)

func _aim_sprite_at_position(target_position: Vector2) -> void:
	_aim_sprite_from_position(target_position, global_position)

func _aim_sprite_from_position(target_position: Vector2, from_position: Vector2) -> void:
	if not _sprite or tower_type != "cannon":
		return
	var dir: Vector2 = target_position - from_position
	if dir.length_squared() <= 0.0001:
		return
	_sprite.rotation = _get_up_facing_rotation(dir.normalized())

func _get_up_facing_rotation(dir: Vector2) -> float:
	return dir.angle() + PI * 0.5

func _get_projectile_start_position() -> Vector2:
	if tower_type != "cannon" or not _target or not is_instance_valid(_target):
		return global_position
	var dir: Vector2 = (_target.global_position - global_position).normalized()
	return global_position + dir * 34.0

func _draw() -> void:
	if _show_range:
		draw_colored_polygon(_range_circle_points, Color(1, 1, 1, 0.1))
		draw_polyline(_range_circle_points, Color(1, 1, 1, 0.3), 1.0)
	
	if _sprite and _sprite.visible:
		return
	
	var color: Color = get_color()
	var base_size: float = 20.0
	
	draw_rect(Rect2(-base_size, -base_size * 1.5, base_size * 2, base_size * 1.5), color)
	
	var roof_color: Color = Color(color.r * 0.7, color.g * 0.7, color.b * 0.7)
	var roof_points: PackedVector2Array = [
		Vector2(-base_size - 5, -base_size * 1.5),
		Vector2(0, -base_size * 2.5),
		Vector2(base_size + 5, -base_size * 1.5)
	]
	draw_colored_polygon(roof_points, roof_color)
	
	draw_rect(Rect2(-base_size * 0.3, -base_size * 0.5, base_size * 0.6, base_size * 0.5), Color(0.2, 0.2, 0.2))
	
	if tower_type == "cannon":
		draw_circle(Vector2(0, -base_size * 0.8), 6, Color.DARK_GRAY)
	elif tower_type == "ice":
		draw_circle(Vector2(0, -base_size * 0.8), 5, Color.LIGHT_BLUE)
	
	for i in range(1, mini(tower_level, 3)):
		draw_string(ThemeDB.fallback_font, Vector2(-3, -base_size * 2.6 - i * 2), "★", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.YELLOW)
	
func _setup_sprite() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "TowerSprite"
	_sprite.centered = true
	add_child(_sprite)
	_update_sprite_texture()

func _update_sprite_texture() -> void:
	if not _sprite:
		return
	
	var texture_path: String = _get_tower_texture_path()
	if texture_path.is_empty() or not FileAccess.file_exists(texture_path):
		_sprite.visible = false
		return
	
	var texture: Texture2D = _get_tower_texture(texture_path)
	if not texture:
		_sprite.visible = false
		return
	
	var target_height: float = _get_tower_target_height()
	var scale_factor: float = target_height / float(texture.get_height())
	_sprite.texture = texture
	_sprite.scale = Vector2.ONE * scale_factor
	_sprite.position = Vector2(0, -texture.get_height() * scale_factor * 0.5 + 8.0)
	_sprite.visible = true

func _get_tower_texture(texture_path: String) -> Texture2D:
	if not _tower_texture_cache.has(texture_path):
		_tower_texture_cache[texture_path] = load(texture_path) as Texture2D
	return _tower_texture_cache[texture_path]

func _get_tower_texture_path() -> String:
	match tower_type:
		"arrow":
			return "res://assets/towers/tower_lv%d_transparent.png" % tower_level
		"cannon":
			return "res://assets/towers/cannon_tower_lv%d_transparent.png" % tower_level
		"ice":
			return "res://assets/towers/ice_tower_lv%d.png_transparent.png" % tower_level
		_:
			return ""

func _get_tower_target_height() -> float:
	match tower_type:
		"cannon":
			return 52.0
		"ice":
			return 56.0
		_:
			return 58.0

func is_click_in_area(click_pos: Vector2) -> bool:
	var local_pos: Vector2 = to_local(click_pos)
	return abs(local_pos.x) <= 25 and local_pos.y >= -55 and local_pos.y <= 10

func _setup_upgrade_icon() -> void:
	_upgrade_icon = Node2D.new()
	_upgrade_icon.name = "UpgradeIcon"
	_upgrade_icon.position = Vector2(0, -70)
	add_child(_upgrade_icon)
	_update_upgrade_icon()

func _update_upgrade_icon() -> void:
	if not _upgrade_icon:
		return
	for child in _upgrade_icon.get_children():
		child.queue_free()
	if can_upgrade() and GameManager.current_gold >= get_upgrade_cost():
		var label: Label = Label.new()
		label.text = "↑"
		label.position = Vector2(-8, -5)
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color.YELLOW)
		_upgrade_icon.add_child(label)

func _on_gold_changed(_new_gold: int) -> void:
	_update_upgrade_icon()

func _get_entrance_points() -> void:
	_entrance_points.clear()
	if _battle_root and is_instance_valid(_battle_root):
		var level_data: LevelData = GameManager.get_level_data(GameManager.current_level_id)
		if not level_data:
			return
		for path_points: PackedVector2Array in level_data.path_points:
			if path_points.size() > 0:
				_entrance_points.append(path_points[0])

func _set_initial_rotation() -> void:
	if not _sprite or tower_type != "cannon" or _entrance_points.size() == 0:
		return
	var entrance: Vector2 = _entrance_points[0]
	var closest_dist: float = global_position.distance_to(entrance)
	for i in range(1, _entrance_points.size()):
		var dist: float = global_position.distance_to(_entrance_points[i])
		if dist < closest_dist:
			closest_dist = dist
			entrance = _entrance_points[i]
	_aim_sprite_at_position(entrance)
