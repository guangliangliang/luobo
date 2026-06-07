class_name LevelData
extends Resource

@export var level_name: String = ""
@export var level_id: int = 1
@export var starting_gold: int = 200
@export var village_health: int = 20
@export var village_position: Vector2 = Vector2(960, 540)
@export var background_texture: Texture2D
@export var village_texture: Texture2D
@export var path_points: Array[PackedVector2Array] = []
@export var build_spots: PackedVector2Array = []
@export var waves: Array[WaveData] = []
@export var bg_color: Color = Color(0.2, 0.35, 0.15)
@export var path_color: Color = Color(0.55, 0.4, 0.25)
@export var path_width: float = 50.0
