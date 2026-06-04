extends PathFollow2D

signal monster_died(reward: int)
signal monster_reached_end

const WOLF_SHEET: Texture2D = preload("res://assets/monsters/wolf/wolf_sheet.png")
const DEATH_SMOKE_SHEET: Texture2D = preload("res://assets/effects/新建文件夹/death_smoke_sheet.png")
const WOLF_FRAME_COUNT: int = 4
const WOLF_FRAME_SIZE: Vector2 = Vector2(640, 1440)
const DEATH_EFFECT_OFFSET := Vector2(0, -18)

static var _death_smoke_frames_cache: SpriteFrames = null
static var _walk_frames_cache: Dictionary = {}

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
	var max_size: float = maxf(first_frame.get_width(), first_frame.get_height())
	sprite.scale = Vector2.ONE * (_get_sprite_target_size(data.monster_type) / max_size)
	sprite.play("walk")

func _get_walk_frames(monster_type: String) -> SpriteFrames:
	if _walk_frames_cache.has(monster_type):
		return _walk_frames_cache[monster_type]

	var frames: SpriteFrames = SpriteFrames.new()
	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", 6.0)

	var loaded_single_frames: bool = _load_single_frame_animation(frames, monster_type)
	if not loaded_single_frames and monster_type == "wolf":
		_load_wolf_sheet_animation(frames)

	_walk_frames_cache[monster_type] = frames
	return frames

func _load_single_frame_animation(frames: SpriteFrames, monster_type: String) -> bool:
	var textures: Array[Texture2D] = []
	for i in range(WOLF_FRAME_COUNT):
		var path: String = "res://assets/monsters/%s/%s_walk_%02d.png" % [monster_type, monster_type, i + 1]
		var texture: Texture2D = load(path) as Texture2D
		if not texture:
			return false
		textures.append(texture)

	for i in range(WOLF_FRAME_COUNT):
		var frame: AtlasTexture = AtlasTexture.new()
		frame.atlas = textures[i]
		frame.region = _get_frame_region(monster_type, i)
		frames.add_frame("walk", frame)
	return true

func _load_wolf_sheet_animation(frames: SpriteFrames) -> void:
	for i in range(WOLF_FRAME_COUNT):
		var frame: AtlasTexture = AtlasTexture.new()
		frame.atlas = WOLF_SHEET
		frame.region = Rect2(Vector2(WOLF_FRAME_SIZE.x * i, 0), WOLF_FRAME_SIZE)
		frames.add_frame("walk", frame)

func _get_sprite_target_size(monster_type: String) -> float:
	match monster_type:
		"bear":
			return 58.0
		"bandit":
			return 42.0
		_:
			return 46.0

func _get_frame_region(monster_type: String, frame_index: int) -> Rect2:
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

func _process(delta: float) -> void:
	if is_dead:
		return

	if slow_timer > 0:
		slow_timer -= delta
		if slow_timer <= 0:
			slow_percent = 0.0
			current_speed = base_speed

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
	_spawn_gold_popup(data.reward)
	queue_free()

func _spawn_death_smoke() -> void:
	var effect: AnimatedSprite2D = AnimatedSprite2D.new()
	effect.sprite_frames = _get_death_smoke_frames()
	effect.animation = "smoke"
	effect.global_position = global_position + DEATH_EFFECT_OFFSET
	effect.scale = Vector2.ONE * 0.1
	effect.z_index = 5
	var root: Node = get_tree().current_scene
	if root:
		root.add_child(effect)
		effect.play("smoke")
		effect.animation_finished.connect(effect.queue_free)

func _get_death_smoke_frames() -> SpriteFrames:
	if not _death_smoke_frames_cache:
		_death_smoke_frames_cache = _create_death_smoke_frames()
	return _death_smoke_frames_cache

func _create_death_smoke_frames() -> SpriteFrames:
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
	if not uses_sprite:
		draw_circle(Vector2.ZERO, data.body_radius, data.body_color)

	if slow_timer > 0:
		draw_circle(Vector2.ZERO, data.body_radius + 3, Color(0.5, 0.8, 1.0, 0.4))

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
