extends Node

const PORT = 8910
const DEFAULT_SERVER_IP = "127.0.0.1"

# Load sẵn Scene nhân vật để sinh ra khi chơi
@export var player_scene: PackedScene

func _ready():
	# Đăng ký sự kiện khi có người chơi tham gia hoặc rời phòng
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

func create_game():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT)
	if error != OK:
		print("Không thể tạo Server: ", error)
		return
	multiplayer.multiplayer_peer = peer
	print("Server đã mở tại cổng: ", PORT)
	
	# Sinh nhân vật cho chính Host (Server)
	_spawn_player(1)

func join_game(address = DEFAULT_SERVER_IP):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	if error != OK:
		print("Không thể kết nối Server: ", error)
		return
	multiplayer.multiplayer_peer = peer
	print("Đang kết nối tới Server...")

func _on_player_connected(id):
	print("Player mới tham gia với ID: ", id)
	# Chỉ Server có quyền điều phối sinh nhân vật
	if multiplayer.is_server():
		_spawn_player(id)

func _on_player_disconnected(id):
	print("Player rời phòng: ", id)
	var player_node = get_node_or_null(str(id))
	if player_node:
		player_node.queue_free()

func _spawn_player(id):
	var player = player_scene.instantiate()
	player.name = str(id) # Đặt tên Node theo ID để đồng bộ hóa
	add_child(player, true) # true = force_readable_name
