extends Resource
class_name W_InventoryItem

var _inventory: W_ComponentInventory3D

@export var data: W_InventoryItemData
@export var quantity: int = 1
@export var can_drop: bool = true
@export var can_pickup: bool = true
@export var attributes: Array[W_ItemAttribute] = []
