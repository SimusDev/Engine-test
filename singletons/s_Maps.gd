extends Node

@export var PATH_TO_MAPS: String = "res://maps"

var _map_list: Array[R_GameMap] = []

var _current_map: R_GameMap
var _current_map_scene: PackedScene

func _ready() -> void:
	for path in SD_FileSystem.get_all_files_with_extension_from_directory(PATH_TO_MAPS, SD_FileExtensions.EC_RESOURCE):
		var resource: Resource = load(path)
		if resource is R_GameMap:
			_map_list.append(resource)

func set_current_map_scene(scene: PackedScene) -> void:
	_current_map_scene = scene

func get_current_map_scene() -> PackedScene:
	return _current_map_scene

func get_map_list() -> Array[R_GameMap]:
	return _map_list

func get_current_map() -> R_GameMap:
	return _current_map

func change_map_to(map: R_GameMap) -> void:
	_change_map_for_all_players(map)

#@rpc("any_peer", "call_local", "reliable")
func _change_map_for_all_players(map: R_GameMap) -> void:
	_current_map = map
	SceneChanger.queue_change_scene_with_base_path("loading_map", false)

func get_map_by_code(code: String) -> R_GameMap:
	for map in get_map_list():
		if map.code == code:
			return map
	return null

func _on_sd_node_console_commands_on_executed(command: SD_ConsoleCommand) -> void:
	match command.get_code():
		"map.change":
			change_map_to(get_map_by_code(command.get_value_as_string()))
