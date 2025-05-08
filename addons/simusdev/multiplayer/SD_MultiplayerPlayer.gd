extends SD_Object
class_name SD_MultiplayerPlayer

var _singleton: SD_MultiplayerSingleton

var _peer_id: int = 1
var _is_host: bool = true
var _username: String = ""

const HOST_ID: int = 1

func get_username() -> String:
	return _username

func get_peer_id() -> int:
	return _peer_id

func is_host() -> bool:
	return _is_host

func initialize(singleton: SD_MultiplayerSingleton) -> void:
	_singleton = singleton

func deinitialize() -> void:
	pass
