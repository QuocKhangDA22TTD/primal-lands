extends Control

func _on_back_button_pressed() -> void:
	EventBus.request_back_to_menu.emit()
