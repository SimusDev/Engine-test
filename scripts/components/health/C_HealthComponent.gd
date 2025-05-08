extends W_ComponentHealth
class_name C_HealthComponent

@export var synchronizer: SD_MultiplayerSynchronizer

func _ready() -> void:
	synchronizer.set_authority_node(target)

func _on_health_changed() -> void:
	synchronizer.sync()
