extends W_FPControllerCamera
class_name C_PlayerCamera

@export var player: WorldPlayer

func _ready() -> void:
	super()
	set_multiplayer_authority(player.get_multiplayer_authority())
	update_camera_status()
	UI.interface_opened.connect(_interface_opened_or_closed)
	UI.interface_closed.connect(_interface_opened_or_closed)

func _interface_opened_or_closed(node: Node) -> void:
	update_camera_status()

func update_camera_status() -> void:
	can_update_mouse = is_multiplayer_authority()
	enabled = is_multiplayer_authority() and !UI.has_active_interface()
	player.movement_controller.enabled = enabled
	update_mouse()
