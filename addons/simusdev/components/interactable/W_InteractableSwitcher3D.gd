extends W_Interactable3D
class_name W_InteractableSwitcher3D

@export var status: bool = false : set = set_status, get = get_status

signal status_changed()

func set_status(_status: bool) -> void:
	if status != _status:
		status = _status
		status_changed.emit()

func get_status() -> bool:
	return status

func switch() -> void:
	set_status(not get_status())

func _on_interacted(interactor: W_Interactor3D) -> void:
	switch()
