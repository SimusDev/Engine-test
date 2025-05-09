extends SD_Object
class_name SD_MultiplayerPlayer

var _singleton: SD_MultiplayerSingleton

var _peer_id: int = -1

const HOST_ID: int = 1

var _data: SD_MPSyncedData

func get_username() -> String:
	return get_data_value("username", "")

func get_data_value(key: String, default_value: Variant = null) -> Variant:
	if is_instance_valid(_data):
		return _data.get_data_value(key, default_value)
	return default_value

func get_peer_id() -> int:
	return _peer_id

func is_host() -> bool:
	return _peer_id == HOST_ID

func initialize(singleton: SD_MultiplayerSingleton, peer_id: int, username: String) -> void:
	_singleton = singleton
	_peer_id = peer_id
	
	_data = SD_MPSyncedData.new()
	singleton.add_child(_data)
	_data.name = str(peer_id)
	_data.set_data_value("username", username)
	_data.set_multiplayer_authority(peer_id)
	
	

func deinitialize() -> void:
	_data.queue_free()
	_data = null
