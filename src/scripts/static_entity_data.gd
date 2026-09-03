class_name StaticEntityData
extends Resource

@export var name: String = "" # Tên của thực thể
@export var scene: PackedScene # Kéo file tscn (chứa Sprite2D / StaticBody2D) vào đây
@export_range(0.0, 1.0) var spawn_chance: float = 0.2 # Tỉ lệ xuất hiện
@export var min_noise: float = -0.1 # Ngưỡng Noise tối thiểu để spawn
@export var max_noise: float = 0.3  # Ngưỡng Noise tối đa
