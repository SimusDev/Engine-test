extends Node3D
class_name W_ComponentInventory3D

@export var holder_node: Node
@export var items: Array[W_InventoryItem] = []

signal updated()
signal picked_up(item: W_InventoryItem)
signal dropped(item: W_InventoryItem)

func update_inventory() -> void:
	updated.emit()

func pickup_item(item: W_InventoryItem) -> void:
	SD_Array.append_to_array_no_repeat(items, item)
	
	picked_up.emit(item)
	update_inventory()

func consume_item(item: W_InventoryItem) -> void:
	SD_Array.erase_from_array(items, item)

func drop_item(item: W_InventoryItem) -> Node:
	if not item.can_drop:
		return
	
	SD_Array.erase_from_array(items, item)
	dropped.emit(item)
	update_inventory()
	
	var world_model: PackedScene = load(item.data.scene_path) as PackedScene
	if world_model:
		var world_node: Node = world_model.instantiate()
		
		
		holder_node.get_parent().add_child(world_node)
		if world_node is Node3D:
			world_node.global_transform = global_transform
		return world_node
	return null

func pickup_interactable(interactable: W_InteractableInventoryItem3D) -> void:
	var item: W_InventoryItem = interactable.get_item()
	
	if not item.can_pickup:
		return
	
	
	interactable.picked_up.emit(self)
	interactable.holder_node.queue_free()
	
	pickup_item(item)
