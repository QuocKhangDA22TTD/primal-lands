# AudioManager.gd
extends Node

@export var default_pool_size: int = 16

# Trạng thái Pool âm thanh
var _available_sfx_players: Array[AudioStreamPlayer] = []
var _available_sfx_2d_players: Array[AudioStreamPlayer2D] = []

# Music Player
var _music_player: AudioStreamPlayer

func _ready() -> void:
	_setup_audio_pools()
	_setup_music_player()
	_connect_signals()

func _setup_audio_pools() -> void:
	# Khởi tạo Pool cho Global SFX
	for i in default_pool_size:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		p.finished.connect(_on_sfx_finished.bind(p))
		add_child(p)
		_available_sfx_players.append(p)

	# Khởi tạo Pool cho 2D Spatial SFX
	for i in default_pool_size:
		var p2d := AudioStreamPlayer2D.new()
		p2d.bus = "SFX"
		p2d.max_distance = 600.0 # Khoảng cách tối đa nghe được tiếng trong Top-down
		p2d.finished.connect(_on_sfx_2d_finished.bind(p2d))
		add_child(p2d)
		_available_sfx_2d_players.append(p2d)

func _setup_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

func _connect_signals() -> void:
	EventBus.play_sfx.connect(play_sfx)
	EventBus.play_sfx_2d.connect(play_sfx_2d)
	EventBus.play_music.connect(play_music)

# --- XỬ LÝ PLAY SFX ---

func play_sfx(stream: AudioStream, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if not stream: return
	
	var player := _get_available_sfx_player()
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = volume_db
	player.play()

func play_sfx_2d(stream: AudioStream, global_pos: Vector2, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if not stream: return

	var player := _get_available_sfx_2d_player()
	player.stream = stream
	player.global_position = global_pos
	player.pitch_scale = pitch_scale
	player.volume_db = volume_db
	player.play()

func play_music(stream: AudioStream, crossfade_time: float = 1.0) -> void:
	if not stream: return
	if _music_player.stream == stream and _music_player.playing: return
	
	# Đơn giản hóa: Đổi nhạc nền ngay lập tức (Có thể dùng Tween nếu muốn Fade in/out)
	_music_player.stream = stream
	_music_player.play()

# --- POOL MANAGEMENT ---

func _get_available_sfx_player() -> AudioStreamPlayer:
	if _available_sfx_players.is_empty():
		# Mở rộng pool nếu thiếu player
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		p.finished.connect(_on_sfx_finished.bind(p))
		add_child(p)
		return p
	return _available_sfx_players.pop_back()

func _on_sfx_finished(player: AudioStreamPlayer) -> void:
	_available_sfx_players.append(player)

func _get_available_sfx_2d_player() -> AudioStreamPlayer2D:
	if _available_sfx_2d_players.is_empty():
		var p2d := AudioStreamPlayer2D.new()
		p2d.bus = "SFX"
		p2d.finished.connect(_on_sfx_2d_finished.bind(p2d))
		add_child(p2d)
		return p2d
	return _available_sfx_2d_players.pop_back()

func _on_sfx_2d_finished(player: AudioStreamPlayer2D) -> void:
	_available_sfx_2d_players.append(player)