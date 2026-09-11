# NetworkManager.gd
extends Node

const DEFAULT_PORT = 7000
const MAX_CLIENTS = 4

var peer: ENetMultiplayerPeer

func host_game(port: int = DEFAULT_PORT) -> Error:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_CLIENTS)
	if error != OK:
		print("Lỗi tạo Server LAN: ", error)
		return error
		
	multiplayer.multiplayer_peer = peer
	print("Đã khởi tạo Host LAN tại port: ", port)
	return OK

func join_game(ip: String, port: int = DEFAULT_PORT) -> Error:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, port)
	if error != OK:
		print("Lỗi kết nối tới Host LAN: ", error)
		return error
		
	multiplayer.multiplayer_peer = peer
	print("Đang kết nối tới LAN Host: ", ip, ":", port)
	return OK

func close_connection() -> void:
	if peer:
		peer.close()
		multiplayer.multiplayer_peer = null