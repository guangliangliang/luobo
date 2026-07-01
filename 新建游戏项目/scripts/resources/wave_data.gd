class_name WaveData
extends Resource

@export var monster_type: String = "wild_wolf"
@export var count: int = 10
@export var spawn_interval: float = 0.8
@export var path_index: int = 0
@export var is_boss: bool = false
@export_range(0.0, 5.0, 0.01) var reward_multiplier: float = 1.0
@export var support_monster_type: String = ""
@export var support_count: int = 0
@export var support_spawn_interval: float = 0.55
