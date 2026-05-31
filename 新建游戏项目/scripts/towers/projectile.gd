extends CharacterBody2D

var _start_pos: Vector2
var _target: Node2D
var _damage: float
var _speed: float
var _tower_type: String
var _splash_radius: float
var _slow_percent: float
var _slow_duration: float
var _is_active: bool = true

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

func _physics_process(_delta: float) -> void:
	if not _is_active:
		return
	
	if not _target or not is_instance_valid(_target):
		_miss()
		return
	
	var direction: Vector2 = (_target.global_position - global_position).normalized()
	velocity = direction * _speed
	
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
	
	queue_free()

func _miss() -> void:
	_is_active = false
	queue_free()

func _draw() -> void:
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
