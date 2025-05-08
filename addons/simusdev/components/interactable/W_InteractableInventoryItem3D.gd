extends W_Interactable3D
class_name W_InteractableInventoryItem3D

@export var holder_node: Node
@export var unique: bool = true
@export var _item: W_InventoryItem

signal picked_up(inventory: W_ComponentInventory3D)

func _ready() -> void:
	if unique:
		_item = _item.duplicate()

func get_item() -> W_InventoryItem:
	return _item

func _on_interacted(interactor: W_Interactor3D) -> void:
	var inventory: W_ComponentInventory3D = interactor.inventory_component
	
	inventory.pickup_interactable(self)
