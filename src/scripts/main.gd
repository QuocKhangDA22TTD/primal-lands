# main.gd
extends Node

@export var main_menu_scene: PackedScene
@export var world_scene: PackedScene
@export var multiplayer_menu_scene: PackedScene

@onready var scene_container: Node = $CurrentSceneNode

var current_scene: Node = null

func _ready() -> void:
	# Lắng nghe các yêu cầu từ EventBus
	EventBus.request_start_singleplayer.connect(_load_singleplayer_game)
	EventBus.request_start_multiplayer_menu.connect(_load_multiplayer_menu)
	EventBus.request_start_multiplayer.connect(_load_multiplayer_game)
	EventBus.request_back_to_menu.connect(_load_main_menu)
	
	# Khởi chạy ban đầu
	_load_main_menu()

func _clear_current_scene() -> void:
	if is_instance_valid(current_scene):
		current_scene.queue_free()
		current_scene = null

func _load_main_menu() -> void:
	_clear_current_scene()
	current_scene = main_menu_scene.instantiate()
	scene_container.add_child(current_scene)

func _load_singleplayer_game() -> void:
	_clear_current_scene()

	# Đảm bảo không dính cấu hình mạng nào khi chơi Offline
	NetworkManager.close_connection()

	current_scene = world_scene.instantiate()
	scene_container.add_child(current_scene)

func _load_multiplayer_menu() -> void:
	_clear_current_scene()
	current_scene = multiplayer_menu_scene.instantiate()
	scene_container.add_child(current_scene)

func _load_multiplayer_game(is_host: bool, ip: String, port: int) -> void:
	_clear_current_scene()

	# Khởi tạo cấu hình mạng ENet thông qua NetworkManager
	if is_host:
		NetworkManager.host_game(port)
	else:
		NetworkManager.join_game(ip, port)
		
	# Nạp chung Scene Gameplay hiện có[cite: 2]
	current_scene = world_scene.instantiate()
	scene_container.add_child(current_scene)
