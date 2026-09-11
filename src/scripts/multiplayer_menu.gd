extends Control

@onready var ip_line_edit: LineEdit = $VBoxContainer/IPLineEdit
@onready var port_line_edit: LineEdit = $VBoxContainer/PortLineEdit
@onready var host_button: Button = $VBoxContainer/HostButton
@onready var join_button: Button = $VBoxContainer/JoinButton
@onready var back_button: Button = $VBoxContainer/BackButton

# Giá trị Port và IP mặc định nếu người dùng không nhập
const DEFAULT_PORT: int = 7000
const DEFAULT_IP: String = "127.0.0.1"

func _on_back_button_pressed() -> void:
	EventBus.request_back_to_menu.emit()

# Hàm hỗ trợ ép kiểu và xử lý Port an toàn
func _get_port_input() -> int:
	var port_text: String = port_line_edit.text.strip_edges()
	if port_text.is_valid_int():
		return port_text.to_int()
	return DEFAULT_PORT

func _on_host_button_pressed() -> void:
	var port: int = _get_port_input()
	var ip: String = ip_line_edit.text.strip_edges()
	if ip.is_empty():
		ip = DEFAULT_IP
	
	# Phát tín hiệu yêu cầu làm Host (is_host = true)
	# Tham số IP có thể truyền chuỗi rỗng "" hoặc default vì Host không dùng IP để kết nối
	EventBus.request_start_multiplayer.emit(true, ip, port)


func _on_join_button_pressed() -> void:
	var port: int = _get_port_input()
	var ip: String = ip_line_edit.text.strip_edges()
	if ip.is_empty():
		ip = DEFAULT_IP
	
	# Phát tín hiệu yêu cầu làm Client Join vào phòng (is_host = false)
	EventBus.request_start_multiplayer.emit(false, ip, port)
