extends CanvasLayer

@export var map_ui: PackedScene

@onready var players_label: Label = $Panel/Label

@onready var map_container: VBoxContainer = $scrollcontainer/map_container

func _ready() -> void:
	Maps.server_unload_current_map()
	Multiplayer.player_connected.connect(update_player_list)
	Multiplayer.player_disconnected.connect(update_player_list)
	
	update_player_list(null)
	
	if Multiplayer.is_server():
		for map in Maps.get_map_list():
			var ui: Control = map_ui.instantiate()
			ui.resource = map
			map_container.add_child(ui)
	
	if Multiplayer.is_client():
		SyncedData.client_sync_data_from_server()
		await SyncedData.all_data_synchronized
		var server_map_code: String = Maps.get_current_server_map_code()
		if not server_map_code.is_empty():
			Maps.change_map_to(Maps.get_map_by_code(server_map_code))


func update_player_list(player: SD_MultiplayerPlayer) -> void:
	players_label.text = ""
	for connected in Multiplayer.get_connected_players():
		players_label.text += connected.get_username() + "\n"
		
