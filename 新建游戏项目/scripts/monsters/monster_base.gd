extends PathFollow2D

signal monster_died(reward: int)
signal monster_reached_end

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
	queue_redraw()

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
	queue_free()

func _draw() -> void:
	if not data:
		return
	
	draw_circle(Vector2.ZERO, data.body_radius, data.body_color)
	
	if slow_timer > 0:
		draw_circle(Vector2.ZERO, data.body_radius + 3, Color(0.5, 0.8, 1.0, 0.4))
	
	var health_pct: float = float(current_health) / float(max_health)
	var bar_width: float = data.body_radius * 2.0
	var bar_height: float = 4.0
	var bar_y: float = -data.body_radius - 10.0
	draw_rect(Rect2(-bar_width / 2.0, bar_y, bar_width, bar_height), Color.RED)
	draw_rect(Rect2(-bar_width / 2.0, bar_y, bar_width * health_pct, bar_height), Color.GREEN)
	
	if data.monster_type == "boss":
		draw_string(ThemeDB.fallback_font, Vector2(-12, 5), "B", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)
	elif data.monster_type == "berserker_goblin":
		draw_string(ThemeDB.fallback_font, Vector2(-6, 4), "!", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.YELLOW)
