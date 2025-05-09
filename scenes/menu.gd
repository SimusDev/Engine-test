extends Node

@export var PORT: int = 7856

func _on_button_host_pressed() -> void:
	Multiplayer.set_username($VBoxContainer/name.text)
	Multiplayer.create_server(PORT)
	start_lobby()

func _on_button_client_pressed() -> void:
	Multiplayer.set_username($VBoxContainer/name.text)
	Multiplayer.create_client($VBoxContainer/ip.text, PORT)
	await Multiplayer.connected_to_server
	start_lobby()

func start_lobby() -> void:
	$VBoxContainer/button_host.disabled = false
	$VBoxContainer/button_client.disabled = false
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")
