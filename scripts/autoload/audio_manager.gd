extends Node
## AudioManager: Centralized audio playback with bus management and crossfading.

# =============================================================================
# AUDIO PLAYERS
# =============================================================================

var _music_player: AudioStreamPlayer
var _music_player_crossfade: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _voice_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer

const SFX_POOL_SIZE: int = 16

# =============================================================================
# STATE
# =============================================================================

var current_music_track: String = ""
var current_ambience_track: String = ""
var is_crossfading: bool = false
var _crossfade_tween: Tween

# Audio caches
var _music_cache: Dictionary = {}
var _sfx_cache: Dictionary = {}
var _voice_cache: Dictionary = {}

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_setup_audio_buses()
	_setup_audio_players()
	_connect_signals()
	EventBus.emit_debug("AudioManager initialized")

func _setup_audio_buses() -> void:
	# Ensure audio buses exist - they should be set up in project settings
	# This is a fallback check
	if AudioServer.get_bus_index("Music") == -1:
		EventBus.emit_warning("Music audio bus not found")
	if AudioServer.get_bus_index("SFX") == -1:
		EventBus.emit_warning("SFX audio bus not found")
	if AudioServer.get_bus_index("Voice") == -1:
		EventBus.emit_warning("Voice audio bus not found")

func _setup_audio_players() -> void:
	# Main music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

	# Crossfade music player
	_music_player_crossfade = AudioStreamPlayer.new()
	_music_player_crossfade.bus = "Music"
	_music_player_crossfade.volume_db = -80.0
	add_child(_music_player_crossfade)

	# SFX pool
	for i in range(SFX_POOL_SIZE):
		var sfx_player := AudioStreamPlayer.new()
		sfx_player.bus = "SFX"
		add_child(sfx_player)
		_sfx_pool.append(sfx_player)

	# Voice player
	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = "Voice"
	add_child(_voice_player)

	# Ambience player
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = "Music"
	_ambience_player.volume_db = -6.0  # Slightly quieter than music
	add_child(_ambience_player)

func _connect_signals() -> void:
	EventBus.music_change_requested.connect(play_music)
	EventBus.sfx_play_requested.connect(play_sfx)
	EventBus.voice_play_requested.connect(play_voice)
	EventBus.audio_settings_changed.connect(_on_audio_settings_changed)

# =============================================================================
# MUSIC
# =============================================================================

func play_music(track_id: String, fade_duration: float = 1.0) -> void:
	if track_id == current_music_track:
		return

	if track_id.is_empty():
		stop_music(fade_duration)
		return

	var stream := _load_music(track_id)
	if not stream:
		push_error("Failed to load music track: %s" % track_id)
		return

	if fade_duration > 0 and _music_player.playing:
		_crossfade_music(stream, fade_duration)
	else:
		_music_player.stream = stream
		_music_player.volume_db = 0.0
		_music_player.play()

	current_music_track = track_id
	EventBus.emit_debug("Playing music: %s" % track_id)

func _crossfade_music(new_stream: AudioStream, duration: float) -> void:
	if is_crossfading:
		if _crossfade_tween:
			_crossfade_tween.kill()

	is_crossfading = true

	# Set up crossfade player
	_music_player_crossfade.stream = new_stream
	_music_player_crossfade.volume_db = -80.0
	_music_player_crossfade.play()

	# Crossfade tween
	_crossfade_tween = create_tween()
	_crossfade_tween.set_parallel(true)
	_crossfade_tween.tween_property(_music_player, "volume_db", -80.0, duration)
	_crossfade_tween.tween_property(_music_player_crossfade, "volume_db", 0.0, duration)
	_crossfade_tween.chain().tween_callback(_finish_crossfade)

func _finish_crossfade() -> void:
	# Swap players
	var temp := _music_player
	_music_player = _music_player_crossfade
	_music_player_crossfade = temp

	# Stop old player
	_music_player_crossfade.stop()
	_music_player_crossfade.volume_db = -80.0

	is_crossfading = false

func stop_music(fade_duration: float = 1.0) -> void:
	if fade_duration > 0 and _music_player.playing:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -80.0, fade_duration)
		tween.tween_callback(_music_player.stop)
	else:
		_music_player.stop()

	current_music_track = ""

func pause_music() -> void:
	_music_player.stream_paused = true

func resume_music() -> void:
	_music_player.stream_paused = false

func is_music_playing() -> bool:
	return _music_player.playing and not _music_player.stream_paused

func _load_music(track_id: String) -> AudioStream:
	if _music_cache.has(track_id):
		return _music_cache[track_id]

	var path := "res://assets/audio/music/%s.ogg" % track_id
	if not ResourceLoader.exists(path):
		path = "res://assets/audio/music/%s.mp3" % track_id
	if not ResourceLoader.exists(path):
		path = "res://assets/audio/music/%s.wav" % track_id

	if ResourceLoader.exists(path):
		var stream: AudioStream = load(path)
		_music_cache[track_id] = stream
		return stream

	return null

# =============================================================================
# SOUND EFFECTS
# =============================================================================

func play_sfx(sfx_id: String, _position: Vector2 = Vector2.ZERO) -> void:
	var stream := _load_sfx(sfx_id)
	if not stream:
		push_error("Failed to load SFX: %s" % sfx_id)
		return

	var player := _get_available_sfx_player()
	if player:
		player.stream = stream
		player.play()

func play_sfx_pitched(sfx_id: String, pitch_scale: float = 1.0) -> void:
	var stream := _load_sfx(sfx_id)
	if not stream:
		return

	var player := _get_available_sfx_player()
	if player:
		player.stream = stream
		player.pitch_scale = pitch_scale
		player.play()

func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			player.pitch_scale = 1.0  # Reset pitch
			return player

	# All players busy, use the first one (oldest sound)
	_sfx_pool[0].pitch_scale = 1.0
	return _sfx_pool[0]

func _load_sfx(sfx_id: String) -> AudioStream:
	if _sfx_cache.has(sfx_id):
		return _sfx_cache[sfx_id]

	var path := "res://assets/audio/sfx/%s.wav" % sfx_id
	if not ResourceLoader.exists(path):
		path = "res://assets/audio/sfx/%s.ogg" % sfx_id

	if ResourceLoader.exists(path):
		var stream: AudioStream = load(path)
		_sfx_cache[sfx_id] = stream
		return stream

	return null

# =============================================================================
# VOICE
# =============================================================================

func play_voice(voice_id: String) -> void:
	var stream := _load_voice(voice_id)
	if not stream:
		push_error("Failed to load voice: %s" % voice_id)
		return

	_voice_player.stream = stream
	_voice_player.play()

func stop_voice() -> void:
	_voice_player.stop()

func is_voice_playing() -> bool:
	return _voice_player.playing

func _load_voice(voice_id: String) -> AudioStream:
	if _voice_cache.has(voice_id):
		return _voice_cache[voice_id]

	var path := "res://assets/audio/voice/%s.wav" % voice_id
	if not ResourceLoader.exists(path):
		path = "res://assets/audio/voice/%s.ogg" % voice_id

	if ResourceLoader.exists(path):
		var stream: AudioStream = load(path)
		_voice_cache[voice_id] = stream
		return stream

	return null

# =============================================================================
# AMBIENCE
# =============================================================================

func play_ambience(track_id: String, fade_duration: float = 2.0) -> void:
	if track_id == current_ambience_track:
		return

	var path := "res://assets/audio/music/ambience_%s.ogg" % track_id
	if not ResourceLoader.exists(path):
		path = "res://assets/audio/music/ambience_%s.wav" % track_id

	if not ResourceLoader.exists(path):
		return

	var stream: AudioStream = load(path)

	if _ambience_player.playing and fade_duration > 0:
		var tween := create_tween()
		tween.tween_property(_ambience_player, "volume_db", -80.0, fade_duration / 2)
		await tween.finished

	_ambience_player.stream = stream
	_ambience_player.volume_db = -80.0
	_ambience_player.play()

	var tween := create_tween()
	tween.tween_property(_ambience_player, "volume_db", -6.0, fade_duration / 2)

	current_ambience_track = track_id

func stop_ambience(fade_duration: float = 2.0) -> void:
	if fade_duration > 0:
		var tween := create_tween()
		tween.tween_property(_ambience_player, "volume_db", -80.0, fade_duration)
		tween.tween_callback(_ambience_player.stop)
	else:
		_ambience_player.stop()

	current_ambience_track = ""

# =============================================================================
# BUS CONTROL
# =============================================================================

func set_bus_volume(bus_name: String, linear_volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_error("Audio bus not found: %s" % bus_name)
		return

	var db_volume := linear_to_db(clampf(linear_volume, 0.0, 1.0))
	AudioServer.set_bus_volume_db(bus_index, db_volume)

func get_bus_volume(bus_name: String) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return 0.0

	return db_to_linear(AudioServer.get_bus_volume_db(bus_index))

func set_bus_muted(bus_name: String, muted: bool) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return

	AudioServer.set_bus_mute(bus_index, muted)

func is_bus_muted(bus_name: String) -> bool:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return false
	return AudioServer.is_bus_mute(bus_index)

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_audio_settings_changed() -> void:
	# Reload volume settings from SettingsManager
	set_bus_volume("Master", SettingsManager.get_setting("audio/master_volume"))
	set_bus_volume("Music", SettingsManager.get_setting("audio/music_volume"))
	set_bus_volume("SFX", SettingsManager.get_setting("audio/sfx_volume"))
	set_bus_volume("Voice", SettingsManager.get_setting("audio/voice_volume"))

# =============================================================================
# UTILITY
# =============================================================================

func preload_music(track_ids: Array[String]) -> void:
	for track_id in track_ids:
		_load_music(track_id)

func preload_sfx(sfx_ids: Array[String]) -> void:
	for sfx_id in sfx_ids:
		_load_sfx(sfx_id)

func clear_cache() -> void:
	_music_cache.clear()
	_sfx_cache.clear()
	_voice_cache.clear()
