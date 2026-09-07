extends Node2D

@export var player: Node2D
@export var tilemap_layer: TileMapLayer
@export var entity_container: Node2D
@export var entity_types: Array[StaticEntityData] = [] # Kéo thả các Resource thực thể vào đây từ Inspector

const CHUNK_SIZE := 8 # Kich thước của mỗi Chunk
const RENDER_DIST := 2 # Khoảng cách hiển thị (số Chunk) từ vị trí của người chơi
const MAX_GEN_PER_FRAME := 2 # Giữ nguyên cơ chế mượt FPS của bạn

var loaded_chunks := {} # Lưu trữ các Chunk đã được sinh ra, key là Vector2i(chunk_x, chunk_y), value là true
var chunk_entities := {} # Lưu trữ các Node2D chứa thực thể tĩnh của từng Chunk, key là Vector2i(chunk_x, chunk_y), value là Node2D

var noise := FastNoiseLite.new() # Sử dụng FastNoiseLite để tạo ra các giá trị noise cho việc sinh địa hình
var entity_noise := FastNoiseLite.new() # Noise phụ dùng riêng cho thực thể
var last_player_chunk := Vector2i(999999, 999999) # Biến này lưu trữ Chunk cuối cùng mà người chơi đứng, để tránh việc sinh lại các Chunk không cần thiết
var is_updating := false # Biến này giúp tránh việc sinh nhiều Chunk cùng lúc, gây lag hoặc treo game

func _ready() -> void:
	var base_seed := randi()
	noise.seed = base_seed # Sinh ra một seed ngẫu nhiên để tạo ra các giá trị noise khác nhau mỗi lần chạy game
	noise.frequency = 0.05 # Tần số của noise, giá trị này ảnh hưởng đến độ chi tiết của địa hình

	# Seed riêng cho entity_noise để không phụ thuộc hoàn toàn vào cấu trúc địa hình
	entity_noise.seed = base_seed + 1000
	entity_noise.frequency = 0.15 # Tần số cao hơn để tạo mật độ phân bổ ngẫu nhiên dày hơn

func _process(_delta: float) -> void:
	if not player or is_updating: return # Nếu không có người chơi hoặc đang trong quá trình cập nhật Chunk, không làm gì cả
	
	# Lấy vị trí tile hiện tại của người chơi trong TileMap
	var player_tile := tilemap_layer.local_to_map(player.global_position)

	# Tính toán Chunk hiện tại mà người chơi đang đứng dựa trên vị trí tile của họ
	var current_chunk := Vector2i(floori(float(player_tile.x) / CHUNK_SIZE), floori(float(player_tile.y) / CHUNK_SIZE))
	
	# Kiểm tra xem người chơi có di chuyển sang Chunk mới hay không, nếu có thì cập nhật các Chunk xung quanh
	if current_chunk != last_player_chunk:
		last_player_chunk = current_chunk
		update_chunks(current_chunk)

func update_chunks(center: Vector2i) -> void:
	is_updating = true
	var op_count := 0

	# Unload các Chunk ở quá xa (Rút gọn logic lọc bằng phép trừ Vector)
	for chunk in loaded_chunks.keys():
		if abs(chunk.x - center.x) > RENDER_DIST or abs(chunk.y - center.y) > RENDER_DIST:
			process_chunk_tiles(chunk, -1) # Xóa tile
			clear_chunk_entities(chunk) # xóa thực thể tĩnh của chunk
			loaded_chunks.erase(chunk)
			
			op_count += 1
			if op_count >= MAX_GEN_PER_FRAME:
				op_count = 0
				await get_tree().process_frame

	# Sinh các Chunk mới trong tầm RENDER_DIST
	for x in range(center.x - RENDER_DIST, center.x + RENDER_DIST + 1):
		for y in range(center.y - RENDER_DIST, center.y + RENDER_DIST + 1):
			var chunk := Vector2i(x, y)

			# Nếu Chunk chưa được sinh ra, tiến hành sinh tile cho Chunk đó
			if not loaded_chunks.has(chunk):
				process_chunk_tiles(chunk, 0) # Sinh tile cho chunk
				generate_chunk_entities(chunk) # Sinh thực thể tĩnh cho chunk
				loaded_chunks[chunk] = true
				
				op_count += 1

				# Nếu số lượng thao tác sinh tile vượt quá MAX_GEN_PER_FRAME, tạm dừng để tránh lag
				if op_count >= MAX_GEN_PER_FRAME:
					op_count = 0
					await get_tree().process_frame

	is_updating = false

# Hàm này xử lý việc sinh hoặc xóa các tile trong một Chunk cụ thể dựa trên source_id
func process_chunk_tiles(chunk_pos: Vector2i, source_id: int) -> void:
	for x in CHUNK_SIZE:
		for y in CHUNK_SIZE:
			var global_tile := chunk_pos * CHUNK_SIZE + Vector2i(x, y)

			# Nếu source_id là -1, xóa tile tại vị trí global_tile, ngược lại, sinh tile dựa trên giá trị noise
			if source_id == -1:
				tilemap_layer.set_cell(global_tile, -1)
			else:
				var val := noise.get_noise_2d(global_tile.x, global_tile.y)
				var tile := Vector2i(2, 1) if (val > -0.2 and val <= 0.4) else Vector2i(0, 3)
				tilemap_layer.set_cell(global_tile, 0, tile)

# LOGIC XỬ LÝ SPAWN VÀ UNLOAD THỰC THỂ TĨNH

func generate_chunk_entities(chunk_pos: Vector2i) -> void:
	# Tạo 1 Node2D cha gom nhóm các Cây/Thực thể thuộc Chunk này
	var container := Node2D.new()
	container.name = "Entities_Chunk_%d_%d" % [chunk_pos.x, chunk_pos.y]
	container.y_sort_enabled = true
	entity_container.add_child(container)
	chunk_entities[chunk_pos] = container

	for x in CHUNK_SIZE:
		for y in CHUNK_SIZE:
			var global_tile := chunk_pos * CHUNK_SIZE + Vector2i(x, y)
			var terrain_val := noise.get_noise_2d(global_tile.x, global_tile.y)
			
			# Kiểm tra điều kiện địa hình (Chỉ sinh cây ở vùng Cỏ: -0.2 < val <= 0.4)
			if terrain_val <= -0.2 or terrain_val > 0.4:
				continue

			var ent_val := entity_noise.get_noise_2d(global_tile.x, global_tile.y)
			
			for entity_data in entity_types:
				# Tạo tỉ lệ ngẫu nhiên giả (Deterministic PRNG) dựa trên tọa độ Tile
				var pseudo_rand := fmod(abs(sin(global_tile.x * 12.9898 + global_tile.y * 78.233) * 43758.5453), 1.0)
				
				# Bắt điều kiện Noise và Ngưỡng xuất hiện
				if ent_val >= entity_data.min_noise and ent_val <= entity_data.max_noise:
					if pseudo_rand < entity_data.spawn_chance:
						_spawn_entity(entity_data.scene, global_tile, container)
						break # Mỗi ô Tile chỉ chứa tối đa 1 thực thể

func _spawn_entity(scene: PackedScene, tile_pos: Vector2i, parent: Node2D) -> void:
	if not scene: return
	var instance := scene.instantiate() as Node2D
	
	# Chuyển đổi tọa độ Tile sang vị trí Global Pixel
	var local_pos := tilemap_layer.map_to_local(tile_pos)
	instance.global_position = local_pos
	
	parent.add_child(instance)

func clear_chunk_entities(chunk_pos: Vector2i) -> void:
	if chunk_entities.has(chunk_pos):
		var container: Node2D = chunk_entities[chunk_pos]
		if is_instance_valid(container):
			container.queue_free() # Dọn sạch toàn bộ Node Cây/Đá thuộc Chunk này khỏi RAM
		chunk_entities.erase(chunk_pos)
