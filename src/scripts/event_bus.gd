# event_bus.gd
extends Node

# Định nghĩa các tín hiệu yêu cầu chuyển chế độ chơi
signal request_back_to_menu
signal request_start_singleplayer
signal request_start_multiplayer_menu
signal request_start_multiplayer(is_host: bool, host_ip: String, port: int)


# --- AUDIO SIGNALS ---
# Tín hiệu phát âm thanh 2D UI / Global (Không có vị trí không gian)
signal play_sfx(stream: AudioStream, pitch_scale: float, volume_db: float)

# Tín hiệu phát âm thanh 2D Spatial (Có vị trí không gian trong thế giới Top-down)
signal play_sfx_2d(stream: AudioStream, global_pos: Vector2, pitch_scale: float, volume_db: float)

# Tín hiệu điều khiển Nhạc nền (Music)
signal play_music(stream: AudioStream, crossfade_time: float)
signal stop_music