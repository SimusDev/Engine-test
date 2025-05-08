extends CanvasLayer

@export var scene_loader: SD_NodeSceneLoader

func _ready() -> void:
	scene_loader.try_load_scene(Maps.get_current_map().scene_path)

func _on_sd_node_scene_loader_loading_finished(packed_scene: PackedScene) -> void:
	Maps.set_current_map_scene(packed_scene)
	SceneChanger.queue_change_scene_with_base_path("game", true)
