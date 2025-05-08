extends Area3D
class_name W_Interactable3D

signal interacted(interactor: W_Interactor3D)
signal selected(interactor: W_Interactor3D)

func interact(interactor: W_Interactor3D = null) -> void:
	_on_interacted_placeholder(interactor)
	interacted.emit(interactor)

func select(interactor: W_Interactor3D) -> void:
	_on_selected_placeholder(interactor)
	selected.emit(interactor)

func _on_interacted_placeholder(interactor: W_Interactor3D) -> void:
	pass

func _on_selected_placeholder(interactor: W_Interactor3D) -> void:
	pass
