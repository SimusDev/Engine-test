extends Node

@export var player: WorldPlayer

func _on_character_sync_data_created(data: Dictionary) -> void:
	var character: W_ComponentCharacterBody3D = player.character_component
	data["is_sprinting"] = character.is_sprinting
	data["move_direction"] = character.get_move_direction()
