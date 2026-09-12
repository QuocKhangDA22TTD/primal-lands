# world.gd
extends Node2D

@export var player_scene: PackedScene

@onready var entity_container: Node2D = $EntityContainer
@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner
@onready var world_generation: Node2D = $WorldGeneration

# Biến lưu Seed chung của Host
var current_world_seed: int = 0

func _ready() -> void:	
	if multiplayer.has_multiplayer_peer():
		# Đăng ký sự kiện kết nối/ngắt kết nối từ Multiplayer API của Godot
		multiplayer.peer_connected.connect(_spawn_player)
		multiplayer.peer_disconnected.connect(_despawn_player)
		
		# Nếu là Host (Server), tự tạo Player cho chính mình
		if multiplayer.is_server():
			current_world_seed = randi() # Host tự tạo 1 Seed duy nhất
			_spawn_player(1) # Peer ID của Host luôn là 1
	else:
		# Chế độ Chơi Đơn (Singleplayer Offline)
		current_world_seed = randi()
		_spawn_player(1)

func _spawn_player(peer_id: int) -> void:
	# Chỉ Host/Server mới có quyền tạo Node đồng bộ xuống Client
	if not multiplayer.is_server() and multiplayer.has_multiplayer_peer():
		return
		
	var player_instance = player_scene.instantiate()
	
	# ĐẶT TÊN NODE TRÙNG VỚI PEER ID -> Rất quan trọng để gán authority
	player_instance.name = str(peer_id) 
	
	entity_container.add_child(player_instance)
	
	# Nếu là Host (Peer ID 1) -> Khởi tạo Map cho Host luôn
	if peer_id == multiplayer.get_unique_id():
		world_generation.setup_world_data(current_world_seed, player_instance)
	else:
		# Nếu là Client mới join vào -> Host gửi RPC Seed xuống cho Client đó
		rpc_id(peer_id, "sync_world_to_client", current_world_seed)

func _despawn_player(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	var p_node = entity_container.get_node_or_null(str(peer_id))
	if p_node:
		p_node.queue_free()

# RPC gửi từ Host xuống Client cụ thể
@rpc("authority", "call_remote", "reliable")
func sync_world_to_client(p_seed: int) -> void:
	var my_id = multiplayer.get_unique_id()
	# Tìm Node Player của chính máy Client này dựa theo ID
	var my_player = entity_container.get_node_or_null(str(my_id))
	
	if my_player:
		# Gọi khởi tạo Map trên máy Client với Seed nhận từ Host
		world_generation.setup_world_data(p_seed, my_player)
	else:
		# Trường hợp Node Player chưa kịp spawn xong trên Client, chờ 0.1s rồi thử lại
		await get_tree().create_timer(0.1).timeout
		sync_world_to_client(p_seed)
