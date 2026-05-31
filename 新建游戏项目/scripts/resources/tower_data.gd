class_name TowerData
extends Resource

@export var tower_name: String = ""
@export var tower_type: String = ""
@export var cost: int = 100
@export var damage: Array[float] = [20.0]
@export var attack_interval: Array[float] = [1.0]
@export var attack_range: Array[float] = [200.0]
@export var splash_radius: Array[float] = [0.0]
@export var slow_percent: Array[float] = [0.0]
@export var slow_duration: Array[float] = [0.0]
@export var projectile_speed: float = 300.0
@export var upgrade_cost: Array[int] = [0, 100, 200]
@export var colors: Array[Color] = [Color.GREEN]
