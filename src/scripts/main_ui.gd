extends Control

const PORT = 8910

@export var player_scene: PackedScene # Kéo file Player.tscn vào đây trong Inspector

@onready var host_button = $VBoxContainer/HostButton
@onready var join_button = $VBoxContainer/JoinButton
@onready var ip_input = $VBoxContainer/IPInput
@onready var menu_container = $VBoxContainer
@onready var spawner = $MultiplayerSpawner

func _ready():
	# 1. Lắng nghe sự kiện bấm nút trên UI
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	
	# 2. Đăng ký sự kiện kết nối mạng
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
	# 3. Cấu hình MultiplayerSpawner
	# Báo cho Spawner biết nó sẽ tự sinh Player vào Node gốc (self)
	spawner.spawn_path = get_path()

# --- XỬ LÝ SỰ KIỆN BẤM NÚT UI ---

func _on_host_button_pressed():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT)
	if error != OK:
		print("Lỗi tạo Server: ", error)
		return
		
	multiplayer.multiplayer_peer = peer
	print("Server đã được khởi tạo thành công!")
	
	# Ẩn UI Menu đi sau khi Host thành công
	menu_container.hide()
	
	# Sinh nhân vật cho chính Host (Host luôn có ID = 1 trong Godot)
	_spawn_player(1)

func _on_join_button_pressed():
	var ip = ip_input.text.strip_edges() # Xóa khoảng trắng 2 đầu
	
	# Kiểm tra xem IP có đúng định dạng IPv4/IPv6 không
	if not ip.is_valid_ip_address():
		print("Địa chỉ IP không hợp lệ!")
		return
		
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, PORT)
	if error != OK:
		print("Không thể khởi tạo Client: ", error)
		return
		
	multiplayer.multiplayer_peer = peer

# --- XỬ LÝ SỰ KIỆN MẠNG (SERVER SIDE) ---

func _on_player_connected(id):
	# Chỉ Server mới có quyền sinh nhân vật khi có Client mới kết nối vào
	if multiplayer.is_server():
		print("Người chơi mới đã vào, cấp ID: ", id)
		_spawn_player(id)

func _on_player_disconnected(id):
	print("Người chơi thoát, xóa ID: ", id)
	var player_node = get_node_or_null(str(id))
	if player_node:
		player_node.queue_free()

# --- HÀM SPAWN PLAYER ---

func _spawn_player(id):
	var player = player_scene.instantiate()
	player.name = str(id) # BẮT BUỘC: Đặt tên Node là ID người chơi để đồng bộ
	add_child(player, true) # true = force_readable_name
