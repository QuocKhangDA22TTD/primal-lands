extends CharacterBody2D

@export var speed: float = 120.0
@export var sfx_footstep: AudioStream

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var camera: Camera2D = $Camera2D

# Biến lưu hướng nhìn gần nhất (mặc định ban đầu nhìn xuống)
var last_direction: Vector2 = Vector2.DOWN

func _enter_tree() -> void:
	# Gán quyền điều khiển dựa trên Tên Node (chính là peer_id dạng String)
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	# Kiểm tra nếu đây KHÔNG PHẢI là Player của máy hiện tại
	if not is_multiplayer_authority():
		# Tắt Camera của Player khác đi
		if camera:
			camera.enabled = false
	else:
		# Bật Camera lên nếu đây chính là Player của máy này
		if camera:
			camera.enabled = true

func _physics_process(_delta: float) -> void:
	# Nếu không phải chủ sở hữu của Player này thì bỏ qua việc xử lý
	if not is_multiplayer_authority():
		return
	
	handle_movement()
	update_animation()

func handle_movement() -> void:
	# Lấy hướng di chuyển từ bàn phím / tay cầm (WASD / Mũi tên)
	var input_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Cập nhật vận tốc
	velocity = input_direction * speed
	
	# Thực hiện di chuyển và xử lý va chạm
	move_and_slide()

func update_animation() -> void:
	# Trường hợp 1: nhân vật đang di chuyển
	if velocity != Vector2.ZERO:
		# Ưu tiên hướng ngang nếu player đi đường chéo, hoặc lưu hướng đang đi
		if abs(velocity.x) > 0:
			last_direction = Vector2(sign(velocity.x), 0)
		else:
			last_direction = Vector2(0, sign(velocity.y))
			
		# Xử lý lật hình ảnh khi sang trái / phải
		if last_direction.x != 0:
			sprite.flip_h = (last_direction.x < 0) # Lật hình nếu đi sang trái
			anim_player.play("move_side")
		elif last_direction.y < 0:
			anim_player.play("move_up")
		elif last_direction.y > 0:
			anim_player.play("move_down")
			
	# Trường hợp 2: Nhân vật đứng yên (idle)
	else:
		if last_direction.x != 0:
			sprite.flip_h = (last_direction.x < 0)
			anim_player.play("idle_side")
		elif last_direction.y < 0:
			anim_player.play("idle_up")
		elif last_direction.y > 0:
			anim_player.play("idle_down")

func play_footstep_sfx() -> void:
	if velocity != Vector2.ZERO:
		var random_pitch := randf_range(0.9, 1.1)
		EventBus.play_sfx_2d.emit(sfx_footstep, global_position, random_pitch)
