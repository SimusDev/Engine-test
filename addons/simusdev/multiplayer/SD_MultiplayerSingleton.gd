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

signal data_from_peer_recieved(data: SD_MPRecievedDBData)

const HOST_ID: int = 1

var _is_server_created: bool = false

var _players: Array[SD_MultiplayerPlayer] = []

var _username: String = "user"

@onready var console: SD_TrunkConsole = SimusDev.console

var _is_connected_to_server: bool = false

var _database: Dictionary[String, Variant] = {}

var callables: SD_MPSyncedCallables

static var _instance: SD_MultiplayerSingleton = null

static func get_instance() -> SD_MultiplayerSingleton:
	return _instance

func _exit_tree() -> void:
	_instance = null

func _ready() -> void:
	if _instance == null:
		_instance = self
	
	callables = SD_MPSyncedCallables.new()
	add_child(callables)
	callables.name = "sc"
	
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
	var username: String =  data.get("username", "")
	player.initialize(self, peer_id, username)
	
	_players.append(player)
	player_connected.emit(player)
	
	console.write_from_object(self, "(id: %s) %s connected!" % [peer_id, username], SD_ConsoleCategories.CATEGORY.SUCCESS)

@rpc("any_peer", "call_local", "reliable")
func _delete_player(peer_id: int) -> void:
	var player: SD_MultiplayerPlayer = get_player_by_peer_id(peer_id)
	var username: String = player.get_username()
	if player:
		_players.erase(player)
		player.deinitialize()
		player_disconnected.emit(player)
		
		console.write_from_object(self, "(id: %s) %s disconnected!" % [peer_id, username], SD_ConsoleCategories.CATEGORY.ERROR)

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
		
		_is_server_created = true
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
	if _is_server_created or _is_connected_to_server:
		return
	
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
	#console.write_from_object(self, "peer %s connected!" % [str(id)], SD_ConsoleCategories.CATEGORY.WARNING)
	

func _on_peer_disconnected(id: int) -> void:
	peer_disconnected.emit(id)
	#console.write_from_object(self, "peer %s disconnected!" % [str(id)], SD_ConsoleCategories.CATEGORY.WARNING)
	
	_delete_player(id)

func get_database() -> Dictionary[String, Variant]:
	return _database

func set_database_value(key: String, value: Variant) -> void:
	_database[key] = value

func get_database_value(key: String, default_value: Variant = null) -> Variant:
	return _database.get(key, default_value)

func has_database_key(key: String) -> bool:
	return _database.has(key)

func request_data_from_peer_db(from_peer: int, callable: Callable, key: String, default_value: Variant = null) -> void:
	var request_data: Dictionary = {
		"from_peer": from_peer,
		"object_id": callable.get_object().get_instance_id(),
		"callable": callable.get_method(),
		"key": key,
		"default_value": default_value,
	}
	_request_data_from_db_rpc.rpc_id(from_peer, request_data)

func request_data_from_server_db(callable: Callable, key: String, default_value: Variant) -> void:
	request_data_from_peer_db(HOST_ID, callable, key, default_value)

@rpc("any_peer", "reliable")
func _request_data_from_db_rpc(request_data: Dictionary) -> void:
	var requester_id: int = multiplayer.get_remote_sender_id()
	var key: String = request_data.get("key", "")
	var default_value = request_data.get("default_value", "")
	var requested_value: Variant = _database.get(key, default_value)
	
	var recieve_data: Dictionary = {
		"key": key,
		"value": requested_value,
		"object_id": request_data["object_id"],
		"callable": request_data["callable"],
	}
	_recieve_data_from_db_rpc.rpc_id(requester_id, recieve_data)

@rpc("any_peer", "reliable")
func _recieve_data_from_db_rpc(data: Dictionary) -> void:
	var from_peer: int = multiplayer.get_remote_sender_id()
	
	var db_data: SD_MPRecievedDBData = SD_MPRecievedDBData.new()
	db_data._peer_id = from_peer
	db_data._key = data.get("key", "")
	db_data._value = data.get("value", null)
	data_from_peer_recieved.emit(db_data)
	
	var method_name: String = data.get("callable", "")
	var object_id: int = data.get("object_id")
	var object: Object = instance_from_id(object_id)
	if is_instance_valid(object):
		var callable: Callable = Callable(object, method_name)
		if callable:
			callable.call(db_data)
