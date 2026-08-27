extends Node

const DEFAULT_MUSIC := "res://audio/music/immune_pulse.ogg"
const DEFAULT_MUSIC_STREAM: AudioStream = preload("res://audio/music/immune_pulse.ogg")
const SFX_STREAMS := {
	&"shot": preload("res://audio/sfx/shot.wav"),
	&"hit": preload("res://audio/sfx/hit.wav"),
	&"core_hit": preload("res://audio/sfx/core_hit.wav"),
	&"phase": preload("res://audio/sfx/phase.wav"),
	&"duty": preload("res://audio/sfx/duty.wav"),
	&"victory": preload("res://audio/sfx/victory.wav"),
	&"defeat": preload("res://audio/sfx/defeat.wav"),
	&"ui": preload("res://audio/sfx/ui.wav"),
}

var _music_players: Array[AudioStreamPlayer] = []
var _sfx_pool: Array[AudioStreamPlayer] = []
var _active_music_index: int = 0
var _music_path: String = ""


func _ready() -> void:
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.name = "Music%d" % i
		player.bus = &"Music"
		player.volume_db = -80.0
		add_child(player)
		_music_players.append(player)
	for i in 10:
		var player := AudioStreamPlayer.new()
		player.name = "Sfx%d" % i
		player.bus = &"SFX"
		add_child(player)
		_sfx_pool.append(player)


func play_music(path: String = DEFAULT_MUSIC, fade_seconds: float = 0.7) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if path == _music_path and _music_players[_active_music_index].playing:
		return
	var stream: AudioStream = DEFAULT_MUSIC_STREAM if path == DEFAULT_MUSIC else load(path) as AudioStream
	if stream == null:
		push_warning("AudioDirector: missing music %s" % path)
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	var previous := _music_players[_active_music_index]
	_active_music_index = 1 - _active_music_index
	var next := _music_players[_active_music_index]
	next.stream = stream
	next.volume_db = -40.0
	next.play()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(next, "volume_db", 0.0, fade_seconds)
	if previous.playing:
		tween.tween_property(previous, "volume_db", -40.0, fade_seconds)
		tween.chain().tween_callback(previous.stop)
	_music_path = path


func play_sfx(id: StringName, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var stream := SFX_STREAMS.get(id) as AudioStream
	if stream == null:
		return
	var player := _next_sfx_player()
	player.stream = stream
	player.pitch_scale = clampf(pitch, 0.5, 2.0)
	player.volume_db = volume_db
	player.play()


func stop_all() -> void:
	for player in _music_players:
		player.stop()
		player.stream = null
	for player in _sfx_pool:
		player.stop()
		player.stream = null
	_music_path = ""


func _next_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	return _sfx_pool[0]
