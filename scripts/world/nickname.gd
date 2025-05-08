extends Label3D

@export var player: WorldPlayer

func _ready() -> void:
	visible = !player.is_multiplayer_authority()
	text = player.get_multiplayer_player().get_username()
