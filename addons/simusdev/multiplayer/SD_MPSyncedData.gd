extends Node
class_name SD_MPSyncedData

@onready var singleton: SD_MultiplayerSingleton
@onready var console: SD_TrunkConsole = SimusDev.console

@export var sync_at_start: bool = true
@export var _data: Dictionary[String, Variant]

var _is_initialized: bool = false

signal initialized()

signal all_data_synchronized()

signal data_changed(key: String, new_value: Variant)

func is_initialized() -> bool:
	return _is_initialized

func local_set_data(data: Dictionary[String, Variant]) -> void:
	_data.clear()
	_data = data

func local_get_data() -> Dictionary[String, Variant]:
	return _data

func local_clear_data() -> void:
	_data.clear()

func local_get_data_value(key: String, default_value = null) -> Variant:
	return _data.get(key, default_value)

func get_data_value(key: String, default_value = null) -> Variant:
	return _data.get(key, default_value)

func set_data_value(key: String, value: Variant) -> void:
	if not is_initialized():
		return
	
	if singleton.is_server():
		_data.set(key, value)
		data_changed.emit(key, value)
		return
	
	_server_recive_data_change_value_rpc.rpc_id(singleton.HOST_ID, get_path(), key, value)


@rpc("any_peer", "reliable")
func _server_recive_data_change_value_rpc(sync_client_path: NodePath, key: String, value: Variant) -> void:
	if singleton.is_server():
		var server_synchronizer: SD_MPSyncedData = get_node_or_null(sync_client_path)
		
		if not server_synchronizer:
			return
		
		server_synchronizer.set_data_value(key, value)
		_client_recieve_data_change_value_rpc.rpc_id(multiplayer.get_remote_sender_id(), key, value)

@rpc("any_peer", "reliable")
func _client_recieve_data_change_value_rpc(key: String, value: Variant) -> void:
	if singleton.is_client():
		_data.set(key, value)
		data_changed.emit(key, value)
	

func _ready() -> void:
	singleton = SD_MultiplayerSingleton.get_instance()
	if not is_instance_valid(singleton):
		console.write_from_object(self, "initialization failed! can't find SD_MultiplayerSingleton instance!", SD_ConsoleCategories.CATEGORY.ERROR)
		return
	
	_initialize()

func _initialize() -> void:
	if _is_initialized:
		return
	
	_is_initialized = true
	
	singleton.connected_to_server.connect(_on_connected_to_server)
	
	if sync_at_start:
		synchronize_all_data()
	
	initialized.emit()

func synchronize_all_data() -> void:
	client_sync_data_from_server()
	if singleton.is_server():
		all_data_synchronized.emit()

func _on_connected_to_server() -> void:
	synchronize_all_data()

func client_sync_data_from_server() -> void:
	if is_initialized() or singleton.is_server():
		return
	
	_client_sync_data_from_server_rpc.rpc_id(singleton.HOST_ID, get_path())


@rpc("any_peer", "reliable")
func _client_sync_data_from_server_rpc(sync_client_path: NodePath) -> void:
	if is_initialized():
		return
	
	var server_synchronizer: SD_MPSyncedData = get_node_or_null(sync_client_path)
	
	if not server_synchronizer:
		return
	
	var server_data: Dictionary[String, Variant] = server_synchronizer.get_data()
	
	if singleton.is_server():
		var client_id: int = multiplayer.get_remote_sender_id()
		
		_client_recive_data_from_server_rpc.rpc_id(client_id, server_data)

@rpc("any_peer", "reliable")
func _client_recive_data_from_server_rpc(server_data: Dictionary[String, Variant]) -> void:
	local_set_data(server_data)
	all_data_synchronized.emit()
