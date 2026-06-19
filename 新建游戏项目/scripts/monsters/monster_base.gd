extends PathFollow2D

signal monster_died(reward: int)
signal monster_reached_end

const DEATH_SMOKE_SHEET: Texture2D = preload("res://assets/effects/新建文件夹/death_smoke_sheet.png")
const WALK_FRAME_COUNT: int = 4
const DEATH_EFFECT_OFFSET := Vector2(0, -18)
const MAX_DEATH_SMOKE_EFFECTS := 2
const DEATH_SMOKE_LIFETIME := 0.7
const SHOW_GOLD_POPUPS := true
const VISUAL_OFFSET := Vector2(0, -8)
const SPRITE_SCALE_MULTIPLIER := 1.2


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

# 血条动画相关
var target_health: float = 0.0
var health_animation_timer: float = 0.0
var is_health_animating: bool = false
var damage_flash_timer: float = 0.0
var low_health_pulse_timer: float = 0.0

# 血条视觉参数
const HEALTH_BAR_HEIGHT = 6.0
const HEALTH_BAR_CORNER_RADIUS = 2.0
const HEALTH_ANIMATION_DURATION = 0.25

func setup(monster_data: MonsterData, _path_points: PackedVector2Array) -> void:
	data = monster_data
	max_health = data.max_health
	current_health = max_health
	target_health = float(max_health)
	health_animation_timer = 0.0
	is_health_animating = false
	damage_flash_timer = 0.0
	low_health_pulse_timer = 0.0
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
	sprite.scale = Vector2.ONE * (_get_sprite_target_size(data.monster_type) * SPRITE_SCALE_MULTIPLIER / max_size)

	sprite.position = VISUAL_OFFSET
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
	for i in range(WALK_FRAME_COUNT):
		var path: String = "res://assets/monsters/%s/%s_walk_%02d.png" % [monster_type, monster_type, i + 1]
		if not ResourceLoader.exists(path):
			return false
		var texture: Texture2D = load(path) as Texture2D
		if not texture:
			return false
		textures.append(texture)

	for i in range(WALK_FRAME_COUNT):
		var frame_texture: Texture2D = textures[i]
		var frame: AtlasTexture = AtlasTexture.new()
		frame.atlas = frame_texture
		frame.region = Rect2(0, 0, frame_texture.get_width(), frame_texture.get_height())
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

	for i in range(WALK_FRAME_COUNT):
		var frame: AtlasTexture = AtlasTexture.new()
		frame.atlas = sheet
		frame.region = _get_sheet_frame_region(sheet, i)
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

static func _get_sheet_frame_region(sheet: Texture2D, frame_index: int) -> Rect2:
	var frame_width: float = sheet.get_width() / float(WALK_FRAME_COUNT)
	return Rect2(frame_width * frame_index, 0, frame_width, sheet.get_height())

func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_health -= int(amount)
	if current_health <= 0:
		die()
	is_health_animating = true
	health_animation_timer = 0.0
	damage_flash_timer = 0.1
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

	_update_health_animation(delta)
	
	if is_health_animating or damage_flash_timer > 0:
		queue_redraw()
	
	var health_pct = float(current_health) / float(max_health)
	if health_pct < 0.3:
		queue_redraw()

	progress += current_speed * delta

	if progress_ratio >= 1.0:
		_reached_end()

func _reached_end() -> void:
	if is_dead:
		return
	is_dead = true
	
	AudioManager.play_sfx("monster_reach_end")
	monster_reached_end.emit()
	GameManager.take_village_damage(GameManager.config.monster_reach_penalty)
	
	_spawn_reach_end_effect()
	_play_reach_end_animation()

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
	effect.scale = Vector2.ONE * 0.2
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
		draw_circle(VISUAL_OFFSET, data.body_radius, data.body_color)

	var health_pct: float = float(current_health) / float(max_health)
	var display_health_pct: float = target_health / float(max_health)
	var bar_width: float = data.body_radius * 2.0
	var bar_height: float = HEALTH_BAR_HEIGHT
	var bar_y: float = VISUAL_OFFSET.y - data.body_radius - 10.0
	if uses_sprite:
		var sprite_size: float = _get_sprite_target_size(data.monster_type) * SPRITE_SCALE_MULTIPLIER
		bar_width = sprite_size * 0.8
		bar_y = VISUAL_OFFSET.y - sprite_size * 0.65

	var bar_x = -bar_width / 2.0
	var bar_rect = Rect2(bar_x, bar_y, bar_width, bar_height)

	# 低血量脉动效果
	var pulse_intensity = 0.0
	if health_pct < 0.3 and not is_dead:
		pulse_intensity = 0.5 + 0.5 * sin(low_health_pulse_timer * 4.0)

	# 绘制阴影
	_draw_rounded_rect(Rect2(bar_x, bar_y + 1, bar_width, bar_height), Color(0, 0, 0, 0.3), HEALTH_BAR_CORNER_RADIUS)

	# 绘制血条背景
	_draw_rounded_rect(bar_rect, Color(0.12, 0.12, 0.12), HEALTH_BAR_CORNER_RADIUS)

	# 绘制边框
	var border_rect = Rect2(bar_x - 0.5, bar_y - 0.5, bar_width + 1, bar_height + 1)
	_draw_rounded_rect(border_rect, Color(0.45, 0.45, 0.45, 0.8), HEALTH_BAR_CORNER_RADIUS + 0.5)
	_draw_rounded_rect(bar_rect, Color(0.12, 0.12, 0.12), HEALTH_BAR_CORNER_RADIUS)

	# 绘制血量条
	if display_health_pct > 0.01:
		var fill_width = bar_width * display_health_pct
		var fill_rect = Rect2(bar_x, bar_y, fill_width, bar_height)
		
		var health_color = _get_health_color(health_pct)
		var health_color_dark = _get_health_color_dark(health_pct)
		
		# 受伤闪烁效果
		if damage_flash_timer > 0:
			var flash_factor = damage_flash_timer / 0.1
			health_color = health_color.lerp(Color.WHITE, flash_factor * 0.5)
			health_color_dark = health_color_dark.lerp(Color.WHITE, flash_factor * 0.5)
		
		# 低血量脉动效果
		if pulse_intensity > 0:
			health_color = health_color.lerp(Color.WHITE, pulse_intensity * 0.3)
		
		# 绘制渐变血量条（上半部分亮色，下半部分暗色）
		var top_rect = Rect2(bar_x, bar_y, fill_width, bar_height / 2.0)
		var bottom_rect = Rect2(bar_x, bar_y + bar_height / 2.0, fill_width, bar_height / 2.0)
		
		# 使用圆角绘制血量填充
		if fill_width > HEALTH_BAR_CORNER_RADIUS * 2:
			_draw_rounded_rect(fill_rect, health_color, HEALTH_BAR_CORNER_RADIUS)
			# 稍微叠加一点暗色在底部增加立体感
			_draw_rounded_rect(bottom_rect, health_color_dark, HEALTH_BAR_CORNER_RADIUS)
		else:
			# 血量很少时直接画矩形
			draw_rect(fill_rect, health_color)


func _draw_slow_trails(uses_sprite: bool) -> void:
	var body_size: float = _get_sprite_target_size(data.monster_type) if uses_sprite else data.body_radius * 2.0
	var trail_alpha: float = clampf(0.35 + slow_timer * 0.12, 0.35, 0.75)
	var trail_color := Color(0.55, 0.88, 1.0, trail_alpha)
	var shadow_color := Color(0.05, 0.22, 0.35, trail_alpha * 0.45)
	var base_y: float = VISUAL_OFFSET.y + body_size * 0.32
	var point_a := Vector2(-body_size * 0.46, base_y)
	var point_b := Vector2(-body_size * 0.30, base_y - 4.0)

	draw_circle(point_a, 4.0, shadow_color)
	draw_circle(point_b, 4.0, shadow_color)
	draw_circle(point_a, 2.6, trail_color)
	draw_circle(point_b, 2.6, trail_color)

func _get_health_color(health_pct: float) -> Color:
	if health_pct >= 0.6:
		return Color(0.2, 0.9, 0.3)
	elif health_pct >= 0.3:
		return Color(1.0, 0.7, 0.2)
	else:
		return Color(0.95, 0.2, 0.15)

func _get_health_color_dark(health_pct: float) -> Color:
	if health_pct >= 0.6:
		return Color(0.15, 0.75, 0.25)
	elif health_pct >= 0.3:
		return Color(0.85, 0.55, 0.15)
	else:
		return Color(0.8, 0.15, 0.1)

func _draw_rounded_rect(rect: Rect2, color: Color, corner_radius: float) -> void:
	var points = PackedVector2Array()
	
	# 左上角
	points.append(Vector2(rect.position.x + corner_radius, rect.position.y))
	points.append(Vector2(rect.position.x + rect.size.x - corner_radius, rect.position.y))
	
	# 右上角圆弧
	for i in range(9):
		var angle = -PI / 2 + (PI / 2) * (i / 8.0)
		points.append(Vector2(
			rect.position.x + rect.size.x - corner_radius + cos(angle) * corner_radius,
			rect.position.y + corner_radius + sin(angle) * corner_radius
		))
	
	# 右边
	points.append(Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y - corner_radius))
	
	# 右下角圆弧
	for i in range(9):
		var angle = 0 + (PI / 2) * (i / 8.0)
		points.append(Vector2(
			rect.position.x + rect.size.x - corner_radius + cos(angle) * corner_radius,
			rect.position.y + rect.size.y - corner_radius + sin(angle) * corner_radius
		))
	
	# 下边
	points.append(Vector2(rect.position.x + corner_radius, rect.position.y + rect.size.y))
	
	# 左下角圆弧
	for i in range(9):
		var angle = PI / 2 + (PI / 2) * (i / 8.0)
		points.append(Vector2(
			rect.position.x + corner_radius + cos(angle) * corner_radius,
			rect.position.y + rect.size.y - corner_radius + sin(angle) * corner_radius
		))
	
	# 左边
	points.append(Vector2(rect.position.x, rect.position.y + corner_radius))
	
	# 左上角圆弧
	for i in range(9):
		var angle = PI + (PI / 2) * (i / 8.0)
		points.append(Vector2(
			rect.position.x + corner_radius + cos(angle) * corner_radius,
			rect.position.y + corner_radius + sin(angle) * corner_radius
		))
	
	draw_colored_polygon(points, color)

func _update_health_animation(delta: float) -> void:
	if is_health_animating:
		health_animation_timer += delta
		var t = clampf(health_animation_timer / HEALTH_ANIMATION_DURATION, 0.0, 1.0)
		var eased_t = 1.0 - pow(1.0 - t, 3.0)
		target_health = lerp(target_health, float(current_health), eased_t)
		
		if t >= 1.0:
			is_health_animating = false
			target_health = float(current_health)
	
	if damage_flash_timer > 0:
		damage_flash_timer -= delta
	
	var health_pct = float(current_health) / float(max_health)
	if health_pct < 0.3 and not is_dead:
		low_health_pulse_timer += delta

func _spawn_reach_end_effect() -> void:
	var effect: AnimatedSprite2D = AnimatedSprite2D.new()
	effect.sprite_frames = _get_death_smoke_frames()
	effect.animation = "smoke"
	effect.global_position = global_position + DEATH_EFFECT_OFFSET
	effect.scale = Vector2.ONE * 0.25
	effect.modulate = Color(1.0, 0.4, 0.4, 1.0)
	effect.z_index = 5
	var root: Node = get_tree().current_scene
	if root:
		root.add_child(effect)
		effect.play("smoke")
		effect.animation_finished.connect(func(): _release_reach_end_effect(effect), CONNECT_ONE_SHOT)
		root.get_tree().create_timer(DEATH_SMOKE_LIFETIME).timeout.connect(func(): _release_reach_end_effect(effect), CONNECT_ONE_SHOT)

static func _release_reach_end_effect(effect: AnimatedSprite2D) -> void:
	if not is_instance_valid(effect):
		return
	if bool(effect.get_meta("released", false)):
		return
	effect.set_meta("released", true)
	effect.queue_free()

func _play_reach_end_animation() -> void:
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_property(self, "scale", scale * 0.3, 0.4)
	tween.finished.connect(queue_free)
	
	_add_reach_end_trails()

func _add_reach_end_trails() -> void:
	var uses_sprite: bool = $MonsterSprite and $MonsterSprite.visible
	var trail_count: int = 3
	for i in range(trail_count):
		var delay: float = float(i) * 0.08
		get_tree().create_timer(delay).timeout.connect(func(idx = i): _draw_single_trail(idx, trail_count, uses_sprite))

func _draw_single_trail(idx: int, total: int, uses_sprite: bool) -> void:
	if not is_instance_valid(self):
		return
	
	var body_size: float = _get_sprite_target_size(data.monster_type) if uses_sprite else data.body_radius * 2.0
	var trail_alpha: float = 0.6 - float(idx) / float(total) * 0.5
	var trail_color := Color(1.0, 0.3, 0.3, trail_alpha)
	
	var trail: Node2D = Node2D.new()
	trail.global_position = global_position
	trail.z_index = z_index - 1
	
	var circle: ColorRect = ColorRect.new()
	circle.size = Vector2(body_size * 0.6, body_size * 0.6)
	circle.position = -circle.size / 2.0 + VISUAL_OFFSET
	circle.color = trail_color
	
	var root: Node = get_tree().current_scene
	if root:
		root.add_child(trail)
		trail.add_child(circle)
		
		var tween: Tween = trail.create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(circle, "modulate:a", 0.0, 0.4)
		tween.tween_property(trail, "scale", trail.scale * 0.5, 0.4)
		tween.finished.connect(trail.queue_free)
