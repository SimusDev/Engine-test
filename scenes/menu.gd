extends Node

@export var PORT: int = 7856

func _on_button_host_pressed() -> void:
	Multiplayer.set_username($VBoxContainer/name.text)
	Multiplayer.create_server(PORT)
	start_game()

func _on_button_client_pressed() -> void:
	Multiplayer.set_username($VBoxContainer/name.text)
	Multiplayer.create_client($VBoxContainer/ip.text, PORT)
	await Multiplayer.connected_to_server
	start_game()

func start_game() -> void:
	$VBoxContainer/button_host.disabled = false
	$VBoxContainer/button_client.disabled = false
	Maps.change_map_to(Maps.get_map_by_code("test_map"))
