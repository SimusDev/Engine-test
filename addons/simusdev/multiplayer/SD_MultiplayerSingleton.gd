extends Node
class_name SD_MultiplayerSingleton

var _peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

signal server_created(port: int)
signal server_closed()

signal client_created(address: String, port: int)
signal client_closed()

signal peer_connected(id: int)
signal peer_disconnected(id: int)

signal connected_to_server()
signal connection_failed()

signal client_players_updated()

signal player_connected(player: SD_MultiplayerPlayer)
signal player_disconnected(player: SD_MultiplayerPlayer)

signal server_disconnected()

const HOST_ID: int = 1

var _is_server_created: bool = false

var _players: Array[SD_MultiplayerPlayer] = []

var _username: String = "user"

@onready var console: SD_TrunkConsole = SimusDev.console

var _is_connected_to_server: bool = false

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	

func _on_server_disconnected() -> void:
	server_disconnected.emit()
	close_client()
	
	console.write_from_object(self, "SERVER DISCONNECTED!", SD_ConsoleCategories.CATEGORY.WARNING)

func _on_connected_to_server() -> void:
	_is_connected_to_server = true
	set_multiplayer_authority(_peer.get_unique_id())
	
	var data: Dictionary = {
		"username": get_username(),
		"host": is_server(),
		"peer_id": multiplayer.get_unique_id(),
	}
	
	_send_player_data_to_server_and_create_player.rpc_id(HOST_ID, data)
	
	connected_to_server.emit()
	console.write_from_object(self, "CONNECTED TO SERVER!", SD_ConsoleCategories.CATEGORY.WARNING)

func update_connected_players() -> void:
	if is_client():
		_players = []
		_server_update_connected_players_rpc.rpc_id(HOST_ID)
		

@rpc("any_peer", "call_local" ,"reliable")
func _send_player_data_to_server_and_create_player(data: Dictionary) -> void:
	if is_server():
		_create_player(data)
		_update_connected_players_rpc.rpc_id(multiplayer.get_remote_sender_id())
		

@rpc("any_peer", "call_local", "reliable")
func _update_connected_players_rpc() -> void:
	if is_client():
		update_connected_players()
		client_players_updated.emit()

@rpc("any_peer", "call_local", "reliable")
func _server_update_connected_players_rpc() -> void:
	if is_client():
		return
	
	for server_player in _players:
		var data: Dictionary = {
			"username": server_player.get_username(),
			"host": server_player.is_host(),
			"peer_id": server_player.get_peer_id()
		}
		
		_server_create_player_for_client(multiplayer.get_remote_sender_id(), data)

func _server_create_player_for_client(peer: int, data: Dictionary) -> void:
	_create_player.rpc_id(peer, data)


@rpc("any_peer", "call_local", "reliable")
func _create_player(data: Dictionary) -> void:
	
	var peer_id: int = data.get("peer_id", -1)
	if peer_id == -1:
		return
	
	var player: SD_MultiplayerPlayer = SD_MultiplayerPlayer.new()
	player._username = data.get("username", "")
	player._is_host = data.get("host", false)
	player._peer_id = peer_id
	
	_players.append(player)
	player.initialize(self)
	player_connected.emit(player)

@rpc("any_peer", "call_local", "reliable")
func _delete_player(peer_id: int) -> void:
	var player: SD_MultiplayerPlayer = get_player_by_peer_id(peer_id)
	if player:
		_players.erase(player)
		player.deinitialize()
		player_disconnected.emit(player)

func get_player_by_peer_id(id: int) -> SD_MultiplayerPlayer:
	for player in _players:
		if player.get_peer_id() == id:
			return player
	return null

func get_connected_players() -> Array[SD_MultiplayerPlayer]:
	return _players

func _on_connection_failed() -> void:
	_is_connected_to_server = false
	_players = []
	connection_failed.emit()

func is_connected_to_server() -> bool:
	return _is_connected_to_server

func get_username() -> String:
	return _username

func set_username(_name: String) -> void:
	_username = _name
	

func get_peer() -> ENetMultiplayerPeer:
	return _peer

func close_server() -> void:
	_players = []
	_peer = ENetMultiplayerPeer.new()
	server_closed.emit()

func create_server(port: int) -> void:
	if _is_server_created:
		return
	
	var err = _peer.create_server(port)
	if err == OK:
		multiplayer.multiplayer_peer = _peer
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		
		set_multiplayer_authority(_peer.get_unique_id())
		
		server_created.emit(port)
		
		console.write_from_object(self, "SERVER created with port: %s" % [str(port)], SD_ConsoleCategories.CATEGORY.WARNING)
		console.write_from_object(self, "USERNAME: %s" % [str(get_username())], SD_ConsoleCategories.CATEGORY.WARNING)
		
		if is_dedicated_server():
			return
		
		var data: Dictionary = {}
		data["username"] = get_username()
		data["peer_id"] = multiplayer.get_unique_id()
		data["host"] = is_server()
		
		_create_player(data)

func create_client(address: String, port: int) -> void:
	var err = _peer.create_client(address, port)
	if err == OK:
		multiplayer.multiplayer_peer = _peer
		set_multiplayer_authority(_peer.get_unique_id())
		client_created.emit(address, port)
		
		console.write_from_object(self, "CLIENT created with port: %s" % [str(port)], SD_ConsoleCategories.CATEGORY.WARNING)
		console.write_from_object(self, "USERNAME: %s" % [str(get_username())], SD_ConsoleCategories.CATEGORY.WARNING)
		

func close_client() -> void:
	_peer = ENetMultiplayerPeer.new()
	client_closed.emit(_peer)

func get_connected_peers() -> PackedInt32Array:
	return multiplayer.get_peers()

func is_server() -> bool:
	return multiplayer.is_server()

func is_client() -> bool:
	return not is_server()

func is_dedicated_server() -> bool:
	return OS.has_feature("dedicated_server")

func _on_peer_connected(id: int) -> void:
	peer_connected.emit(id)
	console.write_from_object(self, "peer %s connected!" % [str(id)], SD_ConsoleCategories.CATEGORY.WARNING)
	

func _on_peer_disconnected(id: int) -> void:
	peer_disconnected.emit(id)
	console.write_from_object(self, "peer %s disconnected!" % [str(id)], SD_ConsoleCategories.CATEGORY.WARNING)
	
	_delete_player(id)
