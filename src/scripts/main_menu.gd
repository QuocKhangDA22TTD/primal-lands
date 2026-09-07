# MainMenu.gd
extends Control

@onready var btn_start: Button = $VBoxContainer/StartButton
@onready var btn_quit: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	btn_start.pressed.connect(_on_start_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	# Chỉ phát tín hiệu, không quan tâm ai sẽ xử lý
	EventBus.request_start_singleplayer.emit()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_multiplayer_button_pressed() -> void:
	EventBus.request_start_multiplayer_menu.emit()
