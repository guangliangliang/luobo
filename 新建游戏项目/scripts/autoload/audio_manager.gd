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
	"wave_start": "res://assets/audio/sfx/wave_start.wav",
	"victory": "res://assets/audio/sfx/victory.wav",
	"defeat": "res://assets/audio/sfx/defeat.wav",
}

var _bgm_player: AudioStreamPlayer
var _bgm_streams: Dictionary = {}
var _sfx_streams: Dictionary = {}
var _sfx_enabled: bool = true
var _bgm_volume: float = 0.5
var _current_bgm: String = ""

func _ready() -> void:
	_create_bgm_player()
	_prewarm_bgm_streams()
	_prewarm_sfx_streams()

func _create_bgm_player() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	_bgm_player.volume_db = _volume_to_db(_bgm_volume)
	add_child(_bgm_player)

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
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	add_child(player)
	
	var stream: AudioStream = _get_sfx_stream(name)
	if stream:
		player.stream = stream
		player.volume_db = -10.0
		player.play()
		player.finished.connect(player.queue_free)

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
			stream.loop = name == "menu" or name == "battle"
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

func _volume_to_db(volume: float) -> float:
	if volume <= 0.0:
		return -80.0
	return linear_to_db(volume)
