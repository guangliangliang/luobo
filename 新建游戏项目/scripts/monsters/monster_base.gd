extends PathFollow2D

signal monster_died(reward: int)
signal monster_reached_end

const DEATH_SMOKE_SHEET: Texture2D = preload("res://assets/effects/新建文件夹/death_smoke_sheet.png")
const WOLF_FRAME_COUNT: int = 4
const DEATH_EFFECT_OFFSET := Vector2(0, -18)
const MAX_DEATH_SMOKE_EFFECTS := 2
const DEATH_SMOKE_LIFETIME := 0.7
const SHOW_GOLD_POPUPS := false

static var _death_smoke_frames_cache: SpriteFrames = null
static var _walk_frames_cache: Dictionary = {}
static var _visible_frame_size_cache: Dictionary = {}
static var _active_death_smoke_effects: int = 0

var data: MonsterData
var current_health: int
var max_health: int
var base_speed: float
var current_speed: float
var slow_timer: float = 0.0
var slow_percent: float = 0.0
var is_dead: bool = false

func setup(monster_data: MonsterData, _path_points: PackedVector2Array) -> void:
	data = monster_data
	max_health = data.max_health
	current_health = max_health
	base_speed = data.move_speed
	current_speed = base_speed
	progress_ratio = 0.0
	set_process(true)

	if $MonsterSprite:
		_setup_sprite()
	queue_redraw()

func _setup_sprite() -> void:
	var sprite: AnimatedSprite2D = $MonsterSprite
	var frames: SpriteFrames = _get_walk_frames(data.monster_type)

	sprite.visible = frames.get_frame_count("walk") > 0
	if not sprite.visible:
		sprite.sprite_frames = null
		return

	sprite.sprite_frames = frames
	var first_frame: Texture2D = frames.get_frame_texture("walk", 0)
	var max_size: float = _get_visible_frame_max_size(data.monster_type, first_frame)
	sprite.scale = Vector2.ONE * (_get_sprite_target_size(data.monster_type) / max_size)
	sprite.play("walk")

static func prewarm_monster_types(monster_types: Array) -> void:
	for monster_type in monster_types:
		var type_name := str(monster_type)
		if not type_name.is_empty():
			_get_walk_frames(type_name)

static func prewarm_combat_effects() -> void:
	_get_death_smoke_frames()

static func _get_walk_frames(monster_type: String) -> SpriteFrames:
	if _walk_frames_cache.has(monster_type):
		return _walk_frames_cache[monster_type]

	var frames: SpriteFrames = SpriteFrames.new()
	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", 6.0)

	var loaded_single_frames: bool = _load_single_frame_animation(frames, monster_type)
	if not loaded_single_frames:
		_load_sheet_animation(frames, monster_type)
	_walk_frames_cache[monster_type] = frames
	return frames

static func _load_single_frame_animation(frames: SpriteFrames, monster_type: String) -> bool:
	var textures: Array[Texture2D] = []
	for i in range(WOLF_FRAME_COUNT):
		var path: String = "res://assets/monsters/%s/%s_walk_%02d.png" % [monster_type, monster_type, i + 1]
		if not ResourceLoader.exists(path):
			return false
		var texture: Texture2D = load(path) as Texture2D
		if not texture:
			return false
		textures.append(texture)

	for i in range(WOLF_FRAME_COUNT):
		var frame: AtlasTexture = AtlasTexture.new()
		frame.atlas = textures[i]
		frame.region = _get_frame_region(monster_type, i)
		frame.filter_clip = true
		frames.add_frame("walk", frame)
	return true

static func _load_sheet_animation(frames: SpriteFrames, monster_type: String) -> bool:
	var sheet_path: String = "res://assets/monsters/%s/%s_sheet.png" % [monster_type, monster_type]
	if not ResourceLoader.exists(sheet_path):
		return false
	var sheet: Texture2D = load(sheet_path) as Texture2D
	if not sheet:
		return false

	for i in range(WOLF_FRAME_COUNT):
		var frame: AtlasTexture = AtlasTexture.new()
		frame.atlas = sheet
		frame.region = _get_sheet_frame_region(monster_type, sheet, i)
		frame.filter_clip = true
		frames.add_frame("walk", frame)
	return true

static func _get_sprite_target_size(monster_type: String) -> float:
	match monster_type:
		"thief", "robber":
			return 42.0
		"wild_wolf", "boar":
			return 46.0
		"mountain_bandit", "shield_bandit":
			return 48.0
		"tiger", "bandit_leader":
			return 54.0
		"brown_bear", "black_bear":
			return 58.0
		_:
			return 46.0

static func _get_visible_frame_max_size(monster_type: String, frame_texture: Texture2D) -> float:
	if _visible_frame_size_cache.has(monster_type):
		return float(_visible_frame_size_cache[monster_type])

	var fallback_size: float = maxf(frame_texture.get_width(), frame_texture.get_height())
	var atlas_texture := frame_texture as AtlasTexture
	if atlas_texture == null or atlas_texture.atlas == null:
		_visible_frame_size_cache[monster_type] = fallback_size
		return fallback_size

	var image: Image = atlas_texture.atlas.get_image()
	if image == null:
		_visible_frame_size_cache[monster_type] = fallback_size
		return fallback_size

	var region: Rect2 = atlas_texture.region
	var start_x: int = clampi(int(floor(region.position.x)), 0, image.get_width())
	var start_y: int = clampi(int(floor(region.position.y)), 0, image.get_height())
	var end_x: int = clampi(int(ceil(region.position.x + region.size.x)), 0, image.get_width())
	var end_y: int = clampi(int(ceil(region.position.y + region.size.y)), 0, image.get_height())
	var min_x: int = end_x
	var min_y: int = end_y
	var max_x: int = start_x
	var max_y: int = start_y
	var found_pixel: bool = false

	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			if image.get_pixel(x, y).a > 0.05:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
				found_pixel = true

	var visible_size: float = fallback_size
	if found_pixel:
		visible_size = maxf(float(max_x - min_x + 1), float(max_y - min_y + 1))
	_visible_frame_size_cache[monster_type] = maxf(1.0, visible_size)
	return float(_visible_frame_size_cache[monster_type])

static func _get_sheet_frame_region(monster_type: String, sheet: Texture2D, frame_index: int) -> Rect2:
	var frame_width: float = sheet.get_width() / float(WOLF_FRAME_COUNT)
	return Rect2(Vector2(frame_width * frame_index, 0), Vector2(frame_width, sheet.get_height()))

static func _get_frame_region(monster_type: String, frame_index: int) -> Rect2:
	var regions: Dictionary = {
		"wolf": [
			Rect2(360, 188, 1308, 784),
			Rect2(344, 200, 1212, 844),
			Rect2(348, 164, 1176, 796),
			Rect2(300, 224, 1312, 840),
		],
		"bandit": [
			Rect2(720, 140, 728, 828),
			Rect2(520, 180, 840, 824),
			Rect2(728, 100, 680, 940),
			Rect2(500, 172, 832, 864),
		],
		"bear": [
			Rect2(556, 60, 916, 1024),
			Rect2(456, 140, 1160, 968),
			Rect2(496, 132, 1040, 968),
			Rect2(448, 40, 1152, 1056),
		],
	}
	if regions.has(monster_type):
		return regions[monster_type][frame_index]
	return Rect2(0, 0, 2048, 1152)

func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_health -= int(amount)
	if current_health <= 0:
		die()
	queue_redraw()

func apply_slow(percent: float, duration: float) -> void:
	if percent > slow_percent:
		slow_percent = percent
	slow_timer = duration
	current_speed = base_speed * (1.0 - slow_percent)
	queue_redraw()

func _process(delta: float) -> void:
	if is_dead:
		return

	if slow_timer > 0:
		slow_timer -= delta
		if slow_timer <= 0:
			slow_percent = 0.0
			current_speed = base_speed
			queue_redraw()

	progress += current_speed * delta

	if progress_ratio >= 1.0:
		_reached_end()

func _reached_end() -> void:
	if is_dead:
		return
	is_dead = true
	monster_reached_end.emit()
	GameManager.take_village_damage(GameManager.config.monster_reach_penalty)
	queue_free()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	AudioManager.play_sfx("monster_die")
	GameManager.on_monster_killed(data.reward)
	monster_died.emit(data.reward)
	_spawn_death_smoke()
	if SHOW_GOLD_POPUPS:
		_spawn_gold_popup(data.reward)
	queue_free()

func _spawn_death_smoke() -> void:
	if _active_death_smoke_effects >= MAX_DEATH_SMOKE_EFFECTS:
		return
	var effect: AnimatedSprite2D = AnimatedSprite2D.new()
	effect.sprite_frames = _get_death_smoke_frames()
	effect.animation = "smoke"
	effect.global_position = global_position + DEATH_EFFECT_OFFSET
	effect.scale = Vector2.ONE * 0.1
	effect.z_index = 5
	var root: Node = get_tree().current_scene
	if root:
		_active_death_smoke_effects += 1
		root.add_child(effect)
		effect.play("smoke")
		effect.animation_finished.connect(func(): _release_death_smoke_effect(effect), CONNECT_ONE_SHOT)
		effect.tree_exiting.connect(func(): _release_death_smoke_effect(effect, false), CONNECT_ONE_SHOT)
		root.get_tree().create_timer(DEATH_SMOKE_LIFETIME).timeout.connect(func(): _release_death_smoke_effect(effect), CONNECT_ONE_SHOT)

static func _release_death_smoke_effect(effect: AnimatedSprite2D, should_free: bool = true) -> void:
	if not is_instance_valid(effect):
		return
	if bool(effect.get_meta("released", false)):
		return
	effect.set_meta("released", true)
	_active_death_smoke_effects = maxi(0, _active_death_smoke_effects - 1)
	if should_free:
		effect.queue_free()

static func _get_death_smoke_frames() -> SpriteFrames:
	if not _death_smoke_frames_cache:
		_death_smoke_frames_cache = _create_death_smoke_frames()
	return _death_smoke_frames_cache

static func _create_death_smoke_frames() -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.add_animation("smoke")
	frames.set_animation_loop("smoke", false)
	frames.set_animation_speed("smoke", 12.0)
	var frame_width: float = DEATH_SMOKE_SHEET.get_width() / 4.0
	for i in range(4):
		var frame: AtlasTexture = AtlasTexture.new()
		frame.atlas = DEATH_SMOKE_SHEET
		frame.region = Rect2(frame_width * i, 0, frame_width, DEATH_SMOKE_SHEET.get_height())
		frames.add_frame("smoke", frame)
	return frames

func _spawn_gold_popup(reward: int) -> void:
	var popup: Label = Label.new()
	popup.text = "+%d" % reward
	popup.global_position = global_position + Vector2(0, -20)
	popup.z_index = 10
	popup.add_theme_font_size_override("font_size", 16)
	popup.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	popup.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0))
	popup.add_theme_constant_override("outline_size", 2)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var root: Node = get_tree().current_scene
	if root:
		root.add_child(popup)
		var tween: Tween = popup.create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(popup, "position:y", popup.position.y - 40, 0.6)
		tween.tween_property(popup, "modulate:a", 0, 0.2)
		tween.finished.connect(popup.queue_free)

func _draw() -> void:
	if not data:
		return

	var uses_sprite: bool = $MonsterSprite and $MonsterSprite.visible
	if slow_timer > 0:
		_draw_slow_trails(uses_sprite)

	if not uses_sprite:
		draw_circle(Vector2.ZERO, data.body_radius, data.body_color)

	var health_pct: float = float(current_health) / float(max_health)
	var bar_width: float = data.body_radius * 2.0
	var bar_height: float = 4.0
	var bar_y: float = -data.body_radius - 10.0
	if uses_sprite:
		bar_width = _get_sprite_target_size(data.monster_type) * 0.8
		bar_y = -_get_sprite_target_size(data.monster_type) * 0.65
	draw_rect(Rect2(-bar_width / 2.0, bar_y, bar_width, bar_height), Color.RED)
	draw_rect(Rect2(-bar_width / 2.0, bar_y, bar_width * health_pct, bar_height), Color.GREEN)

	if not uses_sprite and data.monster_type == "bear":
		draw_string(ThemeDB.fallback_font, Vector2(-12, 5), "B", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)
	elif not uses_sprite and data.monster_type == "bandit":
		draw_string(ThemeDB.fallback_font, Vector2(-6, 4), "!", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.YELLOW)

func _draw_slow_trails(uses_sprite: bool) -> void:
	var body_size: float = _get_sprite_target_size(data.monster_type) if uses_sprite else data.body_radius * 2.0
	var trail_alpha: float = clampf(0.35 + slow_timer * 0.12, 0.35, 0.75)
	var trail_color := Color(1.0, 0.84, 0.18, trail_alpha)
	var shadow_color := Color(0.35, 0.22, 0.02, trail_alpha * 0.45)
	var base_y: float = body_size * 0.32
	var point_a := Vector2(-body_size * 0.46, base_y)
	var point_b := Vector2(-body_size * 0.30, base_y - 4.0)

	draw_circle(point_a, 4.0, shadow_color)
	draw_circle(point_b, 4.0, shadow_color)
	draw_circle(point_a, 2.6, trail_color)
	draw_circle(point_b, 2.6, trail_color)
