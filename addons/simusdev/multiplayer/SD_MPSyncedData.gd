extends Node
class_name SD_MPSyncedData

@onready var singleton: SD_MultiplayerSingleton

func _ready() -> void:
	singleton = SD_MultiplayerSingleton.get_instance()
