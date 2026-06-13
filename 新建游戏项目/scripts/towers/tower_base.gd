extends Node2D

signal tower_selected(tower: Node2D)

const PROJECTILE_SCRIPT: GDScript = preload("res://scripts/towers/projectile.gd")
const BUILD_SPOT_TEXTURE: Texture2D = preload("res://assets/maps/build_spots/build_spot_base.png")
const CANNON_MOUNT_TEXTURE: Texture2D = preload("res://assets/towers/cannon_mount_base.png")
const BUILD_SPOT_REGION := Rect2(102, 46, 822.5, 490.5)
const TOWER_BASE_ANCHOR_Y := 12.0
const TOWER_VISUAL_SCALE := 1.5
const CANNON_MOUNT_WIDTH := 96.0
const CANNON_TEXTURE_FRAME_SIZE := 512.0
const CANNON_PIVOT_POSITION := Vector2.ZERO
const CANNON_MOUNT_TURNTABLE_CENTER := Vector2(96.0, 57.0)
const CANNON_MOUNT_OFFSET := Vector2.ZERO
const UPGRADE_HINT_SIZE := Vector2(38, 26)
const UPGRADE_HINT_TOP_GAP := 6.0
const INITIAL_ATTACK_STAGGER_MAX := 0.35
const ATTACK_TIMER_JITTER := 0.04
const NO_TARGET_SCAN_INTERVAL_MIN := 0.12
const NO_TARGET_SCAN_INTERVAL_MAX := 0.22

static var _tower_texture_cache: Dictionary = {}
static var _tower_visible_rect_cache: Dictionary = {}

var tower_data: TowerData
var tower_level: int = 1
var tower_type: String = ""
var _attack_timer: float = 0.0
var _target: Node2D = null
var _range_circle_points: PackedVector2Array = []
var _show_range: bool = false
var _total_invested: int = 0
var _battle_root: Node = null
var _spawner: Node = null
var _sprite: Sprite2D = null
var _base_sprite: Sprite2D = null
var _cannon_mount_sprite: Sprite2D = null
var _upgrade_icon: Node2D = null
var _upgrade_label: Label = null
var _entrance_points: PackedVector2Array = []
var _attack_range_squared: float = 0.0

static func prewarm_tower_textures() -> void:
	for type: String in ["arrow", "cannon", "ice"]:
		for level: int in range(1, 4):
			var texture_path: String = _get_tower_texture_path_for(type, level)
			if not texture_path.is_empty() and not _tower_texture_cache.has(texture_path):
				_tower_texture_cache[texture_path] = load(texture_path) as Texture2D

func setup(type: String, data: TowerData) -> void:
	tower_type = type
	tower_data = data
	_total_invested = data.cost
	_attack_timer = _get_initial_attack_delay()
	_battle_root = get_tree().current_scene if is_inside_tree() else null
	_spawner = _find_spawner()
	_setup_base_sprite()
	_setup_cannon_mount_sprite()
	_setup_sprite()
	_setup_upgrade_icon()
	if not GameManager.gold_changed.is_connected(_on_gold_changed):
		GameManager.gold_changed.connect(_on_gold_changed)
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

func _exit_tree() -> void:
	if GameManager.gold_changed.is_connected(_on_gold_changed):
		GameManager.gold_changed.disconnect(_on_gold_changed)

func show_range(show: bool) -> void:
	_show_range = show
	queue_redraw()

func _calculate_range_circle() -> void:
	_range_circle_points.clear()
	var segments: int = 48
	var r: float = get_attack_range()
	_attack_range_squared = r * r
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
			_attack_timer = _get_next_attack_delay()
		else:
			_attack_timer = randf_range(NO_TARGET_SCAN_INTERVAL_MIN, NO_TARGET_SCAN_INTERVAL_MAX)

func _find_target() -> void:
	_target = null
	var spawner: Node = _find_spawner()
	if not spawner:
		return
	var monsters: Array = spawner.get_all_monsters()
	var best_progress: float = -1.0
	var range_squared: float = _attack_range_squared
	if range_squared <= 0.0:
		var attack_range: float = get_attack_range()
		range_squared = attack_range * attack_range
	
	for monster in monsters:
		if not is_instance_valid(monster) or monster.is_dead:
			continue
		var dist_squared: float = global_position.distance_squared_to(monster.global_position)
		if dist_squared <= range_squared:
			if monster.progress_ratio > best_progress:
				best_progress = monster.progress_ratio
				_target = monster

func _get_initial_attack_delay() -> float:
	return randf_range(0.0, minf(get_attack_interval(), INITIAL_ATTACK_STAGGER_MAX))

func _get_next_attack_delay() -> float:
	return maxf(0.05, get_attack_interval() + randf_range(-ATTACK_TIMER_JITTER, ATTACK_TIMER_JITTER))

func _find_spawner() -> Node:
	if _spawner and is_instance_valid(_spawner):
		return _spawner
	if _battle_root and is_instance_valid(_battle_root):
		_spawner = _battle_root.get_node_or_null("MonsterSpawner")
		return _spawner
	return null

func _shoot() -> void:
	if not _target or not is_instance_valid(_target):
		return
	
	var projectile_start: Vector2 = _get_projectile_start_position()
	_aim_sprite_from_position(_target.global_position, _get_cannon_rotation_origin_global_position())
	var projectile: Node2D = Node2D.new()
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
	_aim_sprite_from_position(target_position, _get_cannon_rotation_origin_global_position())

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
	var rotation_origin: Vector2 = _get_cannon_rotation_origin_global_position()
	var dir: Vector2 = (_target.global_position - rotation_origin).normalized()
	return rotation_origin + dir * 51.0

func _get_cannon_rotation_origin_global_position() -> Vector2:
	if tower_type != "cannon":
		return global_position
	return to_global(_get_tower_base_anchor_position())

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

func _setup_base_sprite() -> void:
	_base_sprite = Sprite2D.new()
	_base_sprite.name = "BaseSprite"
	_base_sprite.texture = _make_base_texture()
	_base_sprite.centered = true
	_base_sprite.position = Vector2(0, -4)
	_base_sprite.scale = Vector2.ONE * (93.0 / maxf(_base_sprite.texture.get_width(), _base_sprite.texture.get_height()))
	_base_sprite.z_index = -1
	add_child(_base_sprite)

func _setup_cannon_mount_sprite() -> void:
	if tower_type != "cannon":
		return
	_cannon_mount_sprite = Sprite2D.new()
	_cannon_mount_sprite.name = "CannonMountSprite"
	_cannon_mount_sprite.texture = CANNON_MOUNT_TEXTURE
	_cannon_mount_sprite.centered = true
	_cannon_mount_sprite.scale = Vector2.ONE * _get_cannon_mount_scale()
	_cannon_mount_sprite.position = _get_cannon_mount_position()
	_cannon_mount_sprite.z_index = 0
	add_child(_cannon_mount_sprite)

func _get_cannon_mount_scale() -> float:
	return CANNON_MOUNT_WIDTH / CANNON_MOUNT_TEXTURE.get_width()

func _get_cannon_mount_position() -> Vector2:
	var texture_center: Vector2 = CANNON_MOUNT_TEXTURE.get_size() * 0.5
	var turntable_offset: Vector2 = (CANNON_MOUNT_TURNTABLE_CENTER - texture_center) * _get_cannon_mount_scale()
	return CANNON_PIVOT_POSITION - turntable_offset + CANNON_MOUNT_OFFSET

func _make_base_texture() -> AtlasTexture:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = BUILD_SPOT_TEXTURE
	atlas.region = BUILD_SPOT_REGION
	return atlas

func _update_sprite_texture() -> void:
	if not _sprite:
		return
	
	var texture_path: String = _get_tower_texture_path()
	if texture_path.is_empty():
		_sprite.visible = false
		return
	
	var texture: Texture2D = _get_tower_texture(texture_path)
	if not texture:
		_sprite.visible = false
		return
	
	var visible_rect: Rect2 = _get_tower_visible_rect(texture_path, texture)
	var target_height: float = _get_tower_target_height()
	var source_height: float = CANNON_TEXTURE_FRAME_SIZE if tower_type == "cannon" else float(texture.get_height())
	var scale_factor: float = target_height / source_height
	_sprite.texture = texture
	_sprite.scale = Vector2.ONE * scale_factor * TOWER_VISUAL_SCALE
	if tower_type == "cannon":
		_sprite.centered = false
		_sprite.offset = -_get_cannon_tail_anchor(visible_rect)
	else:
		_sprite.centered = true
		_sprite.offset = _get_tower_bottom_anchor_offset(texture, visible_rect)
	_sprite.position = _get_tower_base_anchor_position()
	_sprite.visible = true
	_update_upgrade_icon_position()

func _get_tower_texture(texture_path: String) -> Texture2D:
	if not _tower_texture_cache.has(texture_path):
		_tower_texture_cache[texture_path] = load(texture_path) as Texture2D
	return _tower_texture_cache[texture_path]

func _get_tower_visible_rect(texture_path: String, texture: Texture2D) -> Rect2:
	if not _tower_visible_rect_cache.has(texture_path):
		_tower_visible_rect_cache[texture_path] = _scan_visible_texture_rect(texture)
	return _tower_visible_rect_cache[texture_path]

func _scan_visible_texture_rect(texture: Texture2D) -> Rect2:
	var image: Image = texture.get_image()
	if image == null or image.is_empty() or image.detect_alpha() == Image.ALPHA_NONE:
		return Rect2(Vector2.ZERO, texture.get_size())
	var width: int = image.get_width()
	var height: int = image.get_height()
	var min_x: int = width
	var min_y: int = height
	var max_x: int = -1
	var max_y: int = -1
	for y in range(height):
		for x in range(width):
			if image.get_pixel(x, y).a > 0.05:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2(Vector2.ZERO, texture.get_size())
	return Rect2(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func _get_tower_bottom_anchor_offset(texture: Texture2D, visible_rect: Rect2) -> Vector2:
	return Vector2(
		texture.get_width() * 0.5 - visible_rect.get_center().x,
		texture.get_height() * 0.5 - visible_rect.end.y
	)

func _get_cannon_tail_anchor(visible_rect: Rect2) -> Vector2:
	return Vector2(visible_rect.get_center().x, visible_rect.end.y)

func _get_tower_texture_path() -> String:
	return _get_tower_texture_path_for(tower_type, tower_level)

static func _get_tower_texture_path_for(type: String, level: int) -> String:
	match type:
		"arrow":
			return "res://assets/towers/tower_lv%d_transparent.png" % level
		"cannon":
			return "res://assets/towers/cannon_tower_lv%d_transparent.png" % level
		"ice":
			return "res://assets/towers/ice_tower_lv%d.png_transparent.png" % level
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

func _get_tower_base_anchor_position() -> Vector2:
	if tower_type == "cannon":
		return CANNON_PIVOT_POSITION
	return Vector2(0, TOWER_BASE_ANCHOR_Y)

func is_click_in_area(click_pos: Vector2) -> bool:
	var local_pos: Vector2 = to_local(click_pos)
	return abs(local_pos.x) <= 38 and local_pos.y >= -82 and local_pos.y <= 18

func _setup_upgrade_icon() -> void:
	_upgrade_icon = Node2D.new()
	_upgrade_icon.name = "UpgradeIcon"
	_update_upgrade_icon_position()
	_upgrade_icon.z_index = 30
	add_child(_upgrade_icon)
	_update_upgrade_icon()

func _update_upgrade_icon_position() -> void:
	if not _upgrade_icon:
		return
	var tower_top_y: float = _get_tower_base_anchor_position().y - _get_tower_target_height() * TOWER_VISUAL_SCALE
	_upgrade_icon.position = Vector2(
		-UPGRADE_HINT_SIZE.x * 0.5,
		tower_top_y - UPGRADE_HINT_SIZE.y - UPGRADE_HINT_TOP_GAP
	)

func _update_upgrade_icon() -> void:
	if not _upgrade_icon:
		return
	var upgrade_cost: int = get_upgrade_cost()
	var should_show := can_upgrade() and GameManager.current_gold >= upgrade_cost
	if not should_show:
		_upgrade_icon.visible = false
		return
	_ensure_upgrade_hint()
	_upgrade_label.text = "↑%d" % (tower_level + 1)
	_upgrade_icon.visible = true

func _ensure_upgrade_hint() -> void:
	if _upgrade_label:
		return
	_upgrade_label = Label.new()
	_upgrade_label.text = "↑%d" % (tower_level + 1)
	_upgrade_label.size = UPGRADE_HINT_SIZE
	_upgrade_label.custom_minimum_size = UPGRADE_HINT_SIZE
	_upgrade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_upgrade_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_upgrade_label.add_theme_font_size_override("font_size", 23)
	_upgrade_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.22))
	_upgrade_label.add_theme_color_override("font_outline_color", Color(0.10, 0.06, 0.02))
	_upgrade_label.add_theme_constant_override("outline_size", 3)
	_upgrade_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_upgrade_icon.add_child(_upgrade_label)

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
