@tool
extends RayCast3D
class_name W_Interactor3D

@export var interactor: Node : set = set_interactor, get = get_interactor
@export var inventory_component: W_ComponentInventory3D

signal interactable_selected(interactable: W_Interactable3D)
signal interactable_interacted(interactable: W_Interactable3D)

var _current_interactable: W_Interactable3D = null

func set_interactor(node: Node) -> void:
	collide_with_areas = true
	interactor = node

func select_interactable(interactable: W_Interactable3D) -> void:
	if interactable:
		interactable.select(self)
	interactable_selected.emit(interactable)

func get_interactor() -> Node:
	return interactor

func get_current_interectable() -> W_Interactable3D:
	return _current_interactable

func try_to_interact() -> W_Interactable3D:
	if _current_interactable:
		_current_interactable.interact(self)
		interactable_interacted.emit(_current_interactable)
	return _current_interactable

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	var collider: Object = get_collider()
	
	if is_colliding():
		if collider is W_Interactable3D:
			if _current_interactable != collider:
				_current_interactable = collider
				select_interactable(_current_interactable)
	
	if _current_interactable:
		if (not collider) or (not collider is W_Interactable3D):
			_current_interactable = null
			select_interactable(_current_interactable)
