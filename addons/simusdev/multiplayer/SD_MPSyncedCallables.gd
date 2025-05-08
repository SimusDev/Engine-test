extends Node
class_name SD_MPSyncedCallables

signal sync_called(node: Node, method: String, returned_value: Variant)

func node_sync_call(node: Node, method: String, args: Array = []) -> void:
	if not node.is_inside_tree():
		return
	
	if multiplayer.is_server():
		_local_node_sync_call(node, method, args)
		return
	
	var data: Dictionary[String, Variant] = {
		"m": method,
		"np": str(node.get_path()),
		"a": args,
	}
	
	_client_send_node_sync_call_to_server.rpc(data)

@rpc("any_peer")
func _client_send_node_sync_call_to_server(data: Dictionary[String, Variant]) -> void:
	var method: String = data.get("m", "")
	var node_path: String = data.get("np", "")
	var args: Array = data.get("a", [])
	
	var node
	

func _local_node_sync_call(node: Node, method: String, args: Array = []) -> void:
	var returned: Variant = await node.callv(method, args)
	sync_called.emit(node, method, returned)
