extends Node

const BGM_STREAM_PATHS: Dictionary = {
	"menu": "res://assets/audio/bgm/menu.ogg",
	"battle": "res://assets/audio/bgm/battle.ogg",
	"victory": "res://assets/audio/bgm/victory.ogg",
	"defeat": "res://assets/audio/bgm/defeat.ogg",
}
const SFX_STREAM_PATHS: Dictionary = {
	"build": "res://assets/audio/sfx/build.wav",
	"upgrade": "res://assets/audio/sfx/upgrade.wav",
	"sell": "res://assets/audio/sfx/sell.wav",
	"attack_arrow": "res://assets/audio/sfx/attack_arrow.wav",
	"attack_cannon": "res://assets/audio/sfx/attack_cannon.wav",
	"attack_ice": "res://assets/audio/sfx/attack_ice.wav",
	"monster_die": "res://assets/audio/sfx/monster_die.wav",
	"monster_reach_end": "res://assets/audio/sfx/monster_reach_end.wav",
	"wave_start": "res://assets/audio/sfx/wave_start.wav",
	"victory": "res://assets/audio/sfx/victory.wav",
	"defeat": "res://assets/audio/sfx/defeat.wav",
}
const SFX_POOL_SIZE: int = 16
const SFX_MIN_INTERVALS: Dictionary = {
	"attack_arrow": 45,
	"attack_cannon": 60,
	"attack_ice": 55,
	"monster_die": 45,
}

var _bgm_player: AudioStreamPlayer
var _bgm_streams: Dictionary = {}
var _sfx_streams: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0
var _last_sfx_play_msec: Dictionary = {}
var _sfx_enabled: bool = true
var _bgm_volume: float = 0.5
var _sfx_volume: float = 0.5
var _current_bgm: String = ""

func _ready() -> void:
	_create_bgm_player()
	_create_sfx_pool()
	_prewarm_bgm_streams()
	_prewarm_sfx_streams()

func _create_bgm_player() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	_bgm_player.volume_db = _volume_to_db(_bgm_volume)
	add_child(_bgm_player)

func _create_sfx_pool() -> void:
	for i in range(SFX_POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % i
		player.volume_db = _volume_to_db(_sfx_volume)
		add_child(player)
		_sfx_players.append(player)

func _prewarm_bgm_streams() -> void:
	for bgm_name: String in BGM_STREAM_PATHS:
		_get_bgm_stream(bgm_name)

func _prewarm_sfx_streams() -> void:
	for sfx_name: String in SFX_STREAM_PATHS:
		_get_sfx_stream(sfx_name)

func play_bgm(name: String, restart: bool = false) -> void:
	var stream: AudioStream = _get_bgm_stream(name)
	if not stream:
		return
	if _current_bgm == name and _bgm_player.playing and not restart:
		return
	if _bgm_player.stream != stream:
		_bgm_player.stream = stream
	_current_bgm = name
	_bgm_player.play()

func stop_bgm() -> void:
	if _bgm_player and _bgm_player.playing:
		_bgm_player.stop()
	_current_bgm = ""

func play_sfx(name: String) -> void:
	if not _sfx_enabled:
		return
	if not _can_play_sfx_now(name):
		return
	var stream: AudioStream = _get_sfx_stream(name)
	if stream:
		var player: AudioStreamPlayer = _get_available_sfx_player()
		player.stream = stream
		player.volume_db = _volume_to_db(_sfx_volume)
		player.play()

func _can_play_sfx_now(name: String) -> bool:
	var min_interval_msec: int = int(SFX_MIN_INTERVALS.get(name, 0))
	if min_interval_msec <= 0:
		return true
	var now_msec: int = Time.get_ticks_msec()
	var last_msec: int = int(_last_sfx_play_msec.get(name, -min_interval_msec))
	if now_msec - last_msec < min_interval_msec:
		return false
	_last_sfx_play_msec[name] = now_msec
	return true

func _get_available_sfx_player() -> AudioStreamPlayer:
	if _sfx_players.is_empty():
		_create_sfx_pool()
	for player: AudioStreamPlayer in _sfx_players:
		if not player.playing:
			return player
	var player: AudioStreamPlayer = _sfx_players[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % _sfx_players.size()
	player.stop()
	return player

func _get_bgm_stream(name: String) -> AudioStream:
	if not _bgm_streams.has(name):
		var path: String = BGM_STREAM_PATHS.get(name, "")
		if path.is_empty():
			return null
		var stream: AudioStream = load(path)
		if stream == null:
			push_warning("Missing BGM stream: %s" % path)
			return null
		if stream is AudioStreamOggVorbis:
			stream.loop = name in ["menu", "battle", "victory", "defeat"]
		_bgm_streams[name] = stream
	return _bgm_streams[name]

func _get_sfx_stream(name: String) -> AudioStream:
	if not _sfx_streams.has(name):
		var path: String = SFX_STREAM_PATHS.get(name, "")
		if path.is_empty():
			return null
		var stream: AudioStream = load(path)
		if stream == null:
			push_warning("Missing SFX stream: %s" % path)
			return null
		_sfx_streams[name] = stream
	return _sfx_streams[name]

func set_bgm_volume(volume: float) -> void:
	_bgm_volume = clamp(volume, 0.0, 1.0)
	if _bgm_player:
		_bgm_player.volume_db = _volume_to_db(_bgm_volume)

func get_bgm_volume() -> float:
	return _bgm_volume

func set_sfx_volume(volume: float) -> void:
	_sfx_volume = clamp(volume, 0.0, 1.0)
	for player in _sfx_players:
		player.volume_db = _volume_to_db(_sfx_volume)

func get_sfx_volume() -> float:
	return _sfx_volume

func _volume_to_db(volume: float) -> float:
	if volume <= 0.0:
		return -80.0
	return linear_to_db(volume)
