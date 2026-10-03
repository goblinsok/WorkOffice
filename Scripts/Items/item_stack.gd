class_name ItemStack extends Resource
## An item and an amount. Used both in exported lists (starting items, rewards)
## and as the content of an inventory slot.

@export var item: ItemData
@export var count: int = 1


func _init(p_item: ItemData = null, p_count: int = 1) -> void:
	item = p_item
	count = p_count


func space_left() -> int:
	return item.max_stack - count if item else 0
