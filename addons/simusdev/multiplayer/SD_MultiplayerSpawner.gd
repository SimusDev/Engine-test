@icon("res://addons/simusdev/icons/MultiplayerSpawner.svg")
extends Node
class_name SD_MultiplayerSpawner

@export var DEBUG: bool = false
@export var root: Node

@export_file("*tscn") var _spawn_list: Array[String]

@onready var console: SD_TrunkConsole = SimusDev.console

var _singleton: SD_MultiplayerSingleton 

signal will_spawned(node: Node, scene: PackedScene)
signal spawned(node: Node, scene: PackedScene)

signal will_despawned(node: Node)
signal despawned(node: Node)

func debug_write(text, category: int = SD_ConsoleCategories.CATEGORY.WARNING) -> SD_ConsoleMessage:
	if DEBUG:
		return console.write_from_object(self, str(text), category)
	return null

func get_spawn_list() -> Array[String]:
	return _spawn_list

func _ready() -> void:
	_singleton = SD_MultiplayerSingleton.get_instance()
	if not is_instance_valid(_singleton):
		console.write_from_object(self, "initialization failed! can't find SD_MultiplayerSingleton instance!", SD_ConsoleCategories.CATEGORY.ERROR)
		return
	
	if _singleton.is_server():
		get_tree().node_added.connect(_on_server_scenetree_node_added)
		get_tree().node_removed.connect(_on_server_scenetree_node_removed)
	
	client_synchronize_and_spawn()
	

func _on_server_scenetree_node_added(node: Node) -> void:
	if node.get_parent() == root:
		debug_write("SERVER NODE ADDED IN SCENE TREE: %s" % str(node))
		node.name = node.name.validate_node_name()
		var scene_path: String = node.scene_file_path
		if not scene_path.is_empty():
			if _spawn_list.is_empty() or _spawn_list.has(scene_path):
				_client_recieve_node_add.rpc(node.get_path(), scene_path)
			

func _on_server_scenetree_node_removed(node: Node) -> void:
	if node.get_parent() == root:
		var scene_path: String = node.scene_file_path
		if not scene_path.is_empty():
			if _spawn_list.is_empty() or _spawn_list.has(scene_path):
				_client_recieve_node_remove.rpc(node.get_path())
			

@rpc("any_peer", "reliable")
func _client_recieve_node_add(node_path: NodePath, scene_path: String) -> void:
	if _singleton.is_client():
		debug_write("CLIENT RECIEVED NODE ADD IN SCENE TREE: %s (%s)" % [str(node_path), scene_path])
		var parent_path: String = str(node_path).get_base_dir()
		var parent: Node = get_node_or_null(parent_path)
		var scene: PackedScene = load(scene_path)
		var node_name: String = str(node_path).get_file()
		if parent:
			var spawned: Node = local_spawn_from_packed(scene, parent)
			spawned.name = node_name
			
@rpc("any_peer", "reliable")
func _client_recieve_node_remove(node_path: NodePath) -> void:
	if _singleton.is_client():
		debug_write("CLIENT RECIEVED NODE REMOVE FROM SCENE TREE: %s" % [str(node_path)])
		var node: Node = get_node_or_null(node_path)
		if node:
			local_despawn(node)

func client_synchronize_and_spawn() -> void:
	if _singleton.is_client():
		_client_synchronize_and_spawn.rpc_id(_singleton.HOST_ID)

@rpc("any_peer", "reliable")
func _client_synchronize_and_spawn() -> void:
	if _singleton.is_server():
		#////////////////////SCENE FILE PATH, NODE COUNT
		var nodes: Dictionary[String, String] = {}
		
		for child in root.get_children():
			var file_path: String = child.scene_file_path
			if (not _spawn_list.is_empty()) and (not _spawn_list.has(file_path)):
				continue
			
			if !file_path.is_empty():
				var node_path: String = str(child.get_path())
				nodes[node_path] = file_path
		
		debug_write("(to peer: %s) SERVER SENDING NODES: %s" % [str(multiplayer.get_remote_sender_id()), str(nodes)])
		_client_recieve_nodes_from_server.rpc_id(multiplayer.get_remote_sender_id(), nodes)

@rpc("any_peer", "reliable")
func _client_recieve_nodes_from_server(nodes: Dictionary[String, String]) -> void:
	for path in nodes:
		debug_write("CLIENT RECIEVE NODE: %s" % path)
		var scene_path: String = nodes[path]
		
		var node_path: NodePath = NodePath(path)
		var parent_path: NodePath = NodePath(path.get_base_dir())
		
		if has_node(node_path):
			debug_write("CANT SPAWN!, NODE ALREADY EXISTS: %s" % path, SD_ConsoleCategories.CATEGORY.ERROR)
			continue
		
		var parent: Node = get_node_or_null(parent_path)
		if parent:
			var scene: PackedScene = load(scene_path) as PackedScene
			var spawned: Node = local_spawn_from_packed(scene, parent)
			spawned.name = path.get_file()
			continue
		debug_write("CANT SPAWN!, FAILED TO FIND PARENT OF: %s" % path, SD_ConsoleCategories.CATEGORY.ERROR)

func local_spawn_from_packed(packed: PackedScene, at: Node) -> Node:
	var instance: Node = packed.instantiate()
	will_spawned.emit(instance, packed)
	
	at.call_deferred("add_child", instance)
	instance.tree_entered.connect(
		func(): spawned.emit(instance)
	)
	
	return instance

func local_despawn(node: Node) -> void:
	will_despawned.emit(node)
	
	node.tree_exited.connect(
		func(): despawned.emit(node)
	)
	
	node.call_deferred("queue_free")
