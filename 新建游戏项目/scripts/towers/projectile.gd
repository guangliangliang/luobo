extends Node2D

const PROJECTILE_TEXTURES: Dictionary = {
	"arrow": preload("res://assets/effects/projectiles/arrow_projectile.png"),
	"cannon": preload("res://assets/effects/projectiles/cannon_projectile.png"),
	"ice": preload("res://assets/effects/projectiles/ice_projectile.png"),
}

const PROJECTILE_REGIONS: Dictionary = {
	"arrow": Rect2(148, 340, 1641, 557),
	"cannon": Rect2(628, 248, 789, 661),
	"ice": Rect2(700, 196, 845, 797),
}

const HIT_EFFECT_TEXTURES: Dictionary = {
	"cannon": preload("res://assets/effects/新建文件夹/explosion_sheet.png"),
	"ice": preload("res://assets/effects/新建文件夹/freeze_hit_sheet.png"),
}
const HIT_EFFECT_OFFSET := Vector2(0, -18)
const MAX_ACTIVE_HIT_EFFECTS := 4
const HIT_EFFECT_LIFETIME := 0.5

static var _projectile_texture_cache: Dictionary = {}
static var _hit_effect_frames_cache: Dictionary = {}
static var _active_hit_effects: int = 0

var _start_pos: Vector2
var _target: Node2D
var _damage: float
var _speed: float
var _tower_type: String
var _splash_radius: float
var _slow_percent: float
var _slow_duration: float
var _is_active: bool = true
var _sprite: Sprite2D = null
var _spawner: Node = null

static func prewarm_projectile_assets() -> void:
	for tower_type: String in PROJECTILE_TEXTURES:
		_get_projectile_texture(tower_type)
	for tower_type: String in HIT_EFFECT_TEXTURES:
		_get_effect_frames(tower_type)

func setup(start: Vector2, target: Node2D, damage: float, speed: float, tower_type: String, splash_radius: float = 0.0, slow_percent: float = 0.0, slow_duration: float = 0.0) -> void:
	global_position = start
	_start_pos = start
	_target = target
	_damage = damage
	_speed = speed
	_tower_type = tower_type
	_splash_radius = splash_radius
	_slow_percent = slow_percent
	_slow_duration = slow_duration
	_setup_sprite()

func _ready() -> void:
	_spawner = _find_spawner()

func _physics_process(delta: float) -> void:
	if not _is_active:
		return
	
	if not _target or not is_instance_valid(_target):
		_miss()
		return
	
	var direction: Vector2 = (_target.global_position - global_position).normalized()
	if _sprite:
		_sprite.rotation = direction.angle()
	
	var hit_distance: float = _speed * delta + 15.0
	if global_position.distance_squared_to(_target.global_position) < hit_distance * hit_distance:
		_hit()
		return
	
	global_position += direction * _speed * delta

func _find_spawner() -> Node:
	if not is_inside_tree():
		return null
	var root: Node = get_tree().current_scene
	if root:
		return root.get_node_or_null("MonsterSpawner")
	return null

func _hit() -> void:
	_is_active = false
	
	var spawner: Node = _spawner if (_spawner and is_instance_valid(_spawner)) else _find_spawner()
	var splash_radius_squared: float = _splash_radius * _splash_radius
	
	if _splash_radius > 0:
		if spawner and _target and is_instance_valid(_target):
			var impact_position: Vector2 = _target.global_position
			for monster in spawner.get_all_monsters():
				if is_instance_valid(monster) and not monster.is_dead:
					if monster.global_position.distance_squared_to(impact_position) <= splash_radius_squared:
						monster.take_damage(_damage)
						if _slow_percent > 0 and not monster.is_dead:
							monster.apply_slow(_slow_percent, _slow_duration)
	else:
		if _target and is_instance_valid(_target) and not _target.is_dead:
			_target.take_damage(_damage)
			if _slow_percent > 0 and not _target.is_dead:
				_target.apply_slow(_slow_percent, _slow_duration)
	
	_spawn_hit_effect()
	queue_free()

func _miss() -> void:
	_is_active = false
	queue_free()

func _draw() -> void:
	if _sprite and _sprite.visible:
		return
	var color: Color
	var radius: float
	match _tower_type:
		"arrow":
			color = Color(0.6, 0.4, 0.1)
			radius = 3.0
		"cannon":
			color = Color(0.3, 0.3, 0.3)
			radius = 5.0
		"ice":
			color = Color(0.5, 0.8, 1.0)
			radius = 4.0
		_:
			color = Color.WHITE
			radius = 3.0
	draw_circle(Vector2.ZERO, radius, color)

func _setup_sprite() -> void:
	if not PROJECTILE_TEXTURES.has(_tower_type):
		return
	_sprite = Sprite2D.new()
	_sprite.texture = _get_projectile_texture(_tower_type)
	_sprite.scale = Vector2.ONE * (_get_projectile_target_width() / _sprite.texture.get_width())
	_sprite.visible = true
	add_child(_sprite)

static func _get_projectile_texture(tower_type: String) -> AtlasTexture:
	if not _projectile_texture_cache.has(tower_type):
		_projectile_texture_cache[tower_type] = _make_atlas_texture(PROJECTILE_TEXTURES[tower_type], PROJECTILE_REGIONS[tower_type])
	return _projectile_texture_cache[tower_type]

func _get_projectile_target_width() -> float:
	match _tower_type:
		"arrow":
			return 38.0
		"cannon":
			return 22.0
		"ice":
			return 28.0
		_:
			return 18.0

func _spawn_hit_effect() -> void:
	if not HIT_EFFECT_TEXTURES.has(_tower_type):
		return
	if _active_hit_effects >= MAX_ACTIVE_HIT_EFFECTS:
		return
	var effect: AnimatedSprite2D = AnimatedSprite2D.new()
	effect.sprite_frames = _get_effect_frames(_tower_type)
	effect.animation = "hit"
	var effect_position: Vector2 = _target.global_position if (_target and is_instance_valid(_target)) else global_position
	effect.global_position = effect_position + HIT_EFFECT_OFFSET
	effect.scale = Vector2.ONE * _get_hit_effect_scale()
	effect.z_index = 5
	var root: Node = get_tree().current_scene
	if root:
		_active_hit_effects += 1
		root.add_child(effect)
		effect.play("hit")
		effect.animation_finished.connect(func(): _release_hit_effect(effect), CONNECT_ONE_SHOT)
		effect.tree_exiting.connect(func(): _release_hit_effect(effect, false), CONNECT_ONE_SHOT)
		root.get_tree().create_timer(HIT_EFFECT_LIFETIME).timeout.connect(func(): _release_hit_effect(effect), CONNECT_ONE_SHOT)

static func _release_hit_effect(effect: AnimatedSprite2D, should_free: bool = true) -> void:
	if not is_instance_valid(effect):
		return
	if bool(effect.get_meta("released", false)):
		return
	effect.set_meta("released", true)
	_active_hit_effects = maxi(0, _active_hit_effects - 1)
	if should_free:
		effect.queue_free()

static func _get_effect_frames(tower_type: String) -> SpriteFrames:
	if not _hit_effect_frames_cache.has(tower_type):
		_hit_effect_frames_cache[tower_type] = _create_effect_frames(HIT_EFFECT_TEXTURES[tower_type])
	return _hit_effect_frames_cache[tower_type]

static func _create_effect_frames(texture: Texture2D) -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.add_animation("hit")
	frames.set_animation_loop("hit", false)
	frames.set_animation_speed("hit", 12.0)
	var frame_width: float = texture.get_width() / 4.0
	for i in range(4):
		var frame: AtlasTexture = _make_atlas_texture(texture, Rect2(frame_width * i, 0, frame_width, texture.get_height()))
		frames.add_frame("hit", frame)
	return frames

func _get_hit_effect_scale() -> float:
	match _tower_type:
		"cannon":
			return 0.11
		"ice":
			return 0.10
		_:
			return 0.1

static func _make_atlas_texture(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas
