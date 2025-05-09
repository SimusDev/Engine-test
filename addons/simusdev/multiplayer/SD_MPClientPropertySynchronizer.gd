@icon("res://addons/simusdev/icons/MultiplayerSynchronizer.svg")
extends Node
class_name SD_MPClientPropertySynchronizer

@export var sync_node: Node
@export var sync_at_start: bool = true

const HOST_ID: int = 1

signal synchronized()
signal property_synchronized(property: String, synced_value: Variant)



var _synced_data: Dictionary[String, Variant]

func get_synced_data() -> Dictionary[String, Variant]:
	return _synced_data

func _ready() -> void:
	if not sync_node:
		return
	
	if sync_at_start:
		synchronize()

func synchronize() -> void:
	if multiplayer.is_server() or (not sync_node):
		return
	
	_address_and_send_to_server_rpc.rpc_id(HOST_ID, String(sync_node.get_path()))

@rpc("any_peer")
func _address_and_send_to_server_rpc(node_path: String) -> void:
	pass

@rpc("any_peer")
func _client_recieve_data_from_server_rpc() -> void:
	pass
