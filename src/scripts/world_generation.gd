extends Node2D

@export var player: Node2D
@export var tilemap_layer: TileMapLayer

const CHUNK_SIZE := 8 # Kich thước của mỗi Chunk
const RENDER_DIST := 2 # Khoảng cách hiển thị (số Chunk) từ vị trí của người chơi
const MAX_GEN_PER_FRAME := 2 # Giữ nguyên cơ chế mượt FPS của bạn

var loaded_chunks := {} # Lưu trữ các Chunk đã được sinh ra, key là Vector2i(chunk_x, chunk_y), value là true
var noise := FastNoiseLite.new() # Sử dụng FastNoiseLite để tạo ra các giá trị noise cho việc sinh địa hình
var last_player_chunk := Vector2i(999999, 999999) # Biến này lưu trữ Chunk cuối cùng mà người chơi đứng, để tránh việc sinh lại các Chunk không cần thiết
var is_updating := false # Biến này giúp tránh việc sinh nhiều Chunk cùng lúc, gây lag hoặc treo game

func _ready() -> void:
	noise.seed = randi() # Sinh ra một seed ngẫu nhiên để tạo ra các giá trị noise khác nhau mỗi lần chạy game
	noise.frequency = 0.05 # Tần số của noise, giá trị này ảnh hưởng đến độ chi tiết của địa hình

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
				process_chunk_tiles(chunk, 0)
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