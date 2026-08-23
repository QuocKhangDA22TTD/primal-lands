# main.gd
extends Node

@export var main_menu_scene: PackedScene
@export var singleplayer_game_scene: PackedScene
# @export var multiplayer_game_scene: PackedScene

@onready var scene_container: Node = $CurrentSceneNode

var current_scene: Node = null

func _ready() -> void:
	# Lắng nghe các yêu cầu từ EventBus
	EventBus.request_start_singleplayer.connect(_load_singleplayer_game)
	# EventBus.request_start_multiplayer.connect(_load_multiplayer_game)
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
	current_scene = singleplayer_game_scene.instantiate()
	scene_container.add_child(current_scene)

# func _load_multiplayer_game(ip: String, port: int) -> void:
# 	_clear_current_scene()
# 	var mp_scene = multiplayer_game_scene.instantiate()
# 	# Có thể truyền dữ liệu khởi tạo mạng vào scene multiplayer ở đây
# 	if mp_scene.has_method("setup_network"):
# 		mp_scene.setup_network(ip, port)
		
# 	current_scene = mp_scene
# 	scene_container.add_child(current_scene)
