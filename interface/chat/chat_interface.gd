extends ingame_interface

@export var message_scene: PackedScene
@export var line_edit: LineEdit
@export var history: RichTextLabel
@export var container: VBoxContainer

func _on_messager_draw() -> void:
	line_edit.grab_click_focus()
	line_edit.grab_focus()

func _on_line_edit_text_submitted(new_text: String) -> void:
	line_edit.text = ""
	send_message_from_player(WorldPlayer.instance, new_text)

func send_message_from_player(player: WorldPlayer, msg: String) -> void:
	if not is_instance_valid(player):
		return
	
	var message: String = "[%s]: %s" % [player.get_multiplayer_player().get_username(), msg]
	send_message(message)

func send_message(msg: String) -> void:
	_send_message_rpc.rpc(msg)

@rpc("any_peer", "call_local")
func _send_message_rpc(msg: String) -> void:
	history.text += msg
	history.text += "\n"
	
	var message: Label = message_scene.instantiate()
	message.text = msg
	container.add_child(message)
