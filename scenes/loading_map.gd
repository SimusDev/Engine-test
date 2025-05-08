extends CanvasLayer

func _ready() -> void:
	var loaded_scene: PackedScene = load(Maps.get_current_map().scene_path)
	Maps.set_current_map_scene(loaded_scene)
	SceneChanger.queue_change_scene_with_base_path("game")
	
