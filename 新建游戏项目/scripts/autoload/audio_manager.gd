extends Node

var _audio_players: Dictionary = {}
var _sfx_streams: Dictionary = {}
var _sfx_enabled: bool = true
var _bgm_volume: float = 0.5

func _ready() -> void:
	_create_placeholder_streams()
	_prewarm_sfx_streams()

func _create_placeholder_streams() -> void:
	pass

func _prewarm_sfx_streams() -> void:
	for sfx_name: String in ["build", "upgrade", "attack_arrow", "attack_cannon", "attack_ice", "victory", "defeat", "monster_die", "sell", "wave_start"]:
		_get_sfx_stream(sfx_name)

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

func _get_sfx_stream(name: String) -> AudioStream:
	if not _sfx_streams.has(name):
		_sfx_streams[name] = _generate_tone(name)
	return _sfx_streams[name]

func _generate_tone(name: String) -> AudioStream:
	var sample: AudioStreamWAV = AudioStreamWAV.new()
	sample.mix_rate = 22050
	sample.format = AudioStreamWAV.FORMAT_8_BITS
	
	var freq: float = 440.0
	var duration: float = 0.1
	
	match name:
		"build":
			freq = 523.25
			duration = 0.15
		"upgrade":
			freq = 659.25
			duration = 0.15
		"attack_arrow":
			freq = 880.0
			duration = 0.05
		"attack_cannon":
			freq = 220.0
			duration = 0.1
		"attack_ice":
			freq = 1200.0
			duration = 0.06
		"victory":
			freq = 784.0
			duration = 0.3
		"defeat":
			freq = 196.0
			duration = 0.4
		"monster_die":
			freq = 350.0
			duration = 0.08
		"sell":
			freq = 440.0
			duration = 0.1
		"wave_start":
			freq = 698.0
			duration = 0.2
		_:
			freq = 440.0
			duration = 0.1
	
	var sample_count: int = int(22050 * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count)
	for i in range(sample_count):
		var t: float = float(i) / 22050.0
		var envelope: float = max(0.0, 1.0 - t / duration)
		var val: float = sin(t * freq * TAU) * envelope * 50.0 + 50.0
		data[i] = int(val) as int
	
	sample.data = data
	return sample

func set_bgm_volume(volume: float) -> void:
	_bgm_volume = clamp(volume, 0.0, 1.0)

func get_bgm_volume() -> float:
	return _bgm_volume
