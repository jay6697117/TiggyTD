extends Node

# ---------------------------------------------------------------------------
# AudioSystem — 音效系统单例
# GDD：audio.md
# ---------------------------------------------------------------------------

const MAX_SFX_CONCURRENT := 8
const BGM_FADE_DURATION := 1.0

var _sfx_players: Array[AudioStreamPlayer] = []
var _bgm_player: AudioStreamPlayer
var _bgm_tween: Tween

var _master_volume: float = 0.8
var _sfx_volume: float = 0.8
var _bgm_volume: float = 0.6


func _ready() -> void:
	# 初始化 SFX 播放池
	for i in MAX_SFX_CONCURRENT:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_sfx_players.append(player)
	# 初始化 BGM 播放器
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "BGM"
	add_child(_bgm_player)
	_load_volume_settings()


func play_sfx(sfx_id: String, volume_scale: float = 1.0) -> void:
	var stream := _load_stream("res://assets/audio/sfx/" + sfx_id + ".wav")
	if stream == null:
		return
	var player := _get_free_sfx_player()
	if player == null:
		return  # 超过并发上限，低优先级跳过
	player.stream = stream
	player.volume_db = linear_to_db(_master_volume * _sfx_volume * volume_scale)
	player.play()


func play_bgm(bgm_id: String, fade_duration: float = BGM_FADE_DURATION) -> void:
	var stream := _load_stream("res://assets/audio/bgm/" + bgm_id + ".ogg")
	if stream == null:
		return
	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(_bgm_player, "volume_db", -80.0, fade_duration)
	await _bgm_tween.finished
	_bgm_player.stream = stream
	_bgm_player.play()
	var target_db := linear_to_db(_master_volume * _bgm_volume)
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(_bgm_player, "volume_db", target_db, fade_duration)


func stop_bgm(fade_duration: float = 0.5) -> void:
	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(_bgm_player, "volume_db", -80.0, fade_duration)
	await _bgm_tween.finished
	_bgm_player.stop()


func set_master_volume(value: float) -> void:
	_master_volume = clampf(value / 100.0, 0.0, 1.0)
	_apply_bgm_volume()
	_save_audio_settings()


func set_sfx_volume(value: float) -> void:
	_sfx_volume = clampf(value / 100.0, 0.0, 1.0)
	_save_audio_settings()


func set_bgm_volume(value: float) -> void:
	_bgm_volume = clampf(value / 100.0, 0.0, 1.0)
	_apply_bgm_volume()
	_save_audio_settings()


func _save_audio_settings() -> void:
	var settings: Dictionary = SaveLoad.get_value("settings", {})
	settings["audio"] = {
		"master_volume": int(_master_volume * 100),
		"sfx_volume": int(_sfx_volume * 100),
		"bgm_volume": int(_bgm_volume * 100)
	}
	SaveLoad.set_value("settings", settings)
	SaveLoad.save_game()


func _apply_bgm_volume() -> void:
	if _bgm_player and _bgm_player.playing:
		_bgm_player.volume_db = linear_to_db(_master_volume * _bgm_volume)


func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	return null


func _load_stream(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning("AudioSystem: missing audio file %s" % path)
		return null
	return load(path)


func _load_volume_settings() -> void:
	var settings: Dictionary = SaveLoad.get_value("settings", {})
	var audio: Dictionary = settings.get("audio", {})
	set_master_volume(audio.get("master_volume", 80))
	set_sfx_volume(audio.get("sfx_volume", 80))
	set_bgm_volume(audio.get("bgm_volume", 60))
