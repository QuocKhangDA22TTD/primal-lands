extends CharacterBody2D

@export var speed: float = 120.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# Biến lưu hướng nhìn gần nhất (mặc định ban đầu nhìn xuống)
var last_direction: Vector2 = Vector2.DOWN

func _physics_process(_delta: float) -> void:
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
