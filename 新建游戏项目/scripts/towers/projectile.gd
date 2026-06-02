extends CharacterBody2D

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

func _physics_process(_delta: float) -> void:
	if not _is_active:
		return
	
	if not _target or not is_instance_valid(_target):
		_miss()
		return
	
	var direction: Vector2 = (_target.global_position - global_position).normalized()
	velocity = direction * _speed
	if _sprite:
		_sprite.rotation = direction.angle()
	
	var dist: float = global_position.distance_to(_target.global_position)
	if dist < _speed * get_physics_process_delta_time() + 15.0:
		_hit()
		return
	
	move_and_slide()
	queue_redraw()

func _find_spawner() -> Node:
	var root: Node = get_tree().current_scene
	if root:
		return root.get_node_or_null("MonsterSpawner")
	return null

func _hit() -> void:
	_is_active = false
	
	var spawner: Node = _find_spawner()
	
	if _splash_radius > 0:
		if spawner:
			for monster in spawner.get_all_monsters():
				if is_instance_valid(monster) and not monster.is_dead:
					if _target and is_instance_valid(_target) and monster.global_position.distance_to(_target.global_position) <= _splash_radius:
						monster.take_damage(_damage)
	else:
		if _target and is_instance_valid(_target) and not _target.is_dead:
			_target.take_damage(_damage)
	
	if _slow_percent > 0:
		if _target and is_instance_valid(_target) and not _target.is_dead:
			_target.apply_slow(_slow_percent, _slow_duration)
		if _splash_radius > 0 and spawner:
			for monster in spawner.get_all_monsters():
				if is_instance_valid(monster) and not monster.is_dead and monster != _target:
					if _target and is_instance_valid(_target) and monster.global_position.distance_to(_target.global_position) <= _splash_radius:
						monster.apply_slow(_slow_percent, _slow_duration)
	
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
	_sprite.texture = _make_atlas_texture(PROJECTILE_TEXTURES[_tower_type], PROJECTILE_REGIONS[_tower_type])
	_sprite.scale = Vector2.ONE * (_get_projectile_target_width() / _sprite.texture.get_width())
	_sprite.visible = true
	add_child(_sprite)

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
	var effect: AnimatedSprite2D = AnimatedSprite2D.new()
	effect.sprite_frames = _create_effect_frames(HIT_EFFECT_TEXTURES[_tower_type])
	effect.animation = "hit"
	effect.global_position = _target.global_position if (_target and is_instance_valid(_target)) else global_position
	effect.scale = Vector2.ONE * _get_hit_effect_scale()
	effect.z_index = 5
	var root: Node = get_tree().current_scene
	if root:
		root.add_child(effect)
		effect.play("hit")
		effect.animation_finished.connect(effect.queue_free)

func _create_effect_frames(texture: Texture2D) -> SpriteFrames:
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

func _make_atlas_texture(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas
