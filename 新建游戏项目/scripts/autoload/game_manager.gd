extends Node

signal gold_changed(new_gold: int)
signal village_health_changed(new_health: int)
signal game_won
signal game_lost

var config: GameConfig
var tower_datas: Dictionary = {}
var monster_datas: Dictionary = {}
var level_datas: Dictionary = {}

var current_level_id: int = 1
var current_gold: int = 200
var village_health: int = 20
var max_village_health: int = 20
var kill_count: int = 0
var total_gold_earned: int = 0
var is_battle_active: bool = false
var last_result: Dictionary = {}

func _ready() -> void:
	_load_configs()

func _load_configs() -> void:
	config = load("res://config/game_config.tres")
	_load_tower_data("arrow", "res://resources/towers/arrow_tower.tres")
	_load_tower_data("cannon", "res://resources/towers/cannon_tower.tres")
	_load_tower_data("ice", "res://resources/towers/ice_tower.tres")
	_load_monster_data("goblin", "res://resources/monsters/goblin.tres")
	_load_monster_data("berserker_goblin", "res://resources/monsters/berserker_goblin.tres")
	_load_monster_data("boss", "res://resources/monsters/boss.tres")
	_load_level_data(1, "res://resources/levels/level_01.tres")
	_load_level_data(2, "res://resources/levels/level_02.tres")

func _load_tower_data(key: String, path: String) -> void:
	var res: TowerData = load(path)
	if res:
		tower_datas[key] = res

func _load_monster_data(key: String, path: String) -> void:
	var res: MonsterData = load(path)
	if res:
		monster_datas[key] = res

func _load_level_data(id: int, path: String) -> void:
	var res: LevelData = load(path)
	if res:
		level_datas[id] = res

func start_battle(level_id: int) -> void:
	current_level_id = level_id
	var level: LevelData = level_datas.get(level_id) as LevelData
	if not level:
		return
	current_gold = level.starting_gold
	village_health = level.village_health
	max_village_health = level.village_health
	kill_count = 0
	total_gold_earned = 0
	is_battle_active = true
	gold_changed.emit(current_gold)
	village_health_changed.emit(village_health)

func add_gold(amount: int) -> void:
	current_gold += amount
	if amount > 0:
		total_gold_earned += amount
	gold_changed.emit(current_gold)

func spend_gold(amount: int) -> bool:
	if current_gold < amount:
		return false
	current_gold -= amount
	gold_changed.emit(current_gold)
	return true

func take_village_damage(amount: int) -> void:
	village_health = max(0, village_health - amount)
	village_health_changed.emit(village_health)
	if village_health <= 0:
		is_battle_active = false
		game_lost.emit()

func on_monster_killed(reward: int) -> void:
	kill_count += 1
	add_gold(reward)

func get_tower_data(type: String) -> TowerData:
	return tower_datas.get(type) as TowerData

func get_monster_data(type: String) -> MonsterData:
	return monster_datas.get(type) as MonsterData

func get_level_data(id: int) -> LevelData:
	return level_datas.get(id) as LevelData

func set_result(won: bool, level_id: int) -> void:
	last_result = {
		"won": won,
		"kill_count": kill_count,
		"gold_earned": total_gold_earned,
		"level_id": level_id,
	}

func get_upgrade_cost(tower_type: String, current_level: int) -> int:
	var td: TowerData = get_tower_data(tower_type)
	if not td or current_level >= td.upgrade_cost.size():
		return 0
	return td.upgrade_cost[current_level]

func get_sell_value(tower_type: String, current_level: int) -> int:
	var td: TowerData = get_tower_data(tower_type)
	if not td:
		return 0
	var total_invested: int = td.cost
	for i in range(1, current_level):
		if i < td.upgrade_cost.size():
			total_invested += td.upgrade_cost[i]
	return int(total_invested * config.tower_sell_return_rate)
