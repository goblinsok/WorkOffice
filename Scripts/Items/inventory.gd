class_name Inventory extends Resource
## Fixed-size grid of item stacks. An empty slot is null.
## All mutations emit `changed` (Resource's built-in signal) through emit_changed().

var slots: Array[ItemStack] = []


func resize(size: int) -> void:
	slots.resize(size)
	emit_changed()


func get_size() -> int:
	return slots.size()


func get_slot_stack(index: int) -> ItemStack:
	return slots[index] if index >= 0 and index < slots.size() else null


## Adds items, filling existing stacks first. Returns how many did not fit.
func add_item(item: ItemData, count: int = 1) -> int:
	var left := count
	for stack in slots:
		if left == 0:
			break
		if stack and stack.item == item and stack.space_left() > 0:
			var moved := mini(left, stack.space_left())
			stack.count += moved
			left -= moved
	for i in slots.size():
		if left == 0:
			break
		if slots[i] == null:
			var moved := mini(left, item.max_stack)
			slots[i] = ItemStack.new(item, moved)
			left -= moved
	emit_changed()
	return left


func remove_at(index: int, count: int = 1) -> void:
	var stack := get_slot_stack(index)
	if stack == null:
		return
	stack.count -= count
	if stack.count <= 0:
		slots[index] = null
	emit_changed()


## Removes up to `count` of an item from anywhere. Returns how many were removed.
func remove_item(item: ItemData, count: int = 1) -> int:
	var removed := 0
	for i in slots.size():
		var stack := slots[i]
		if removed == count:
			break
		if stack and stack.item == item:
			var taken := mini(count - removed, stack.count)
			stack.count -= taken
			removed += taken
			if stack.count <= 0:
				slots[i] = null
	emit_changed()
	return removed


func count_of(item: ItemData) -> int:
	var total := 0
	for stack in slots:
		if stack and stack.item == item:
			total += stack.count
	return total


## Moves a stack onto another slot: merges equal items, otherwise swaps.
func move(from: int, to: int) -> void:
	if from == to or get_slot_stack(from) == null or to < 0 or to >= slots.size():
		return
	var source := slots[from]
	var target := slots[to]
	if target and target.item == source.item:
		var moved := mini(source.count, target.space_left())
		target.count += moved
		source.count -= moved
		if source.count <= 0:
			slots[from] = null
	else:
		slots[to] = source
		slots[from] = target
	emit_changed()


## Uses the item in a slot. Returns true if it was used.
func use_at(index: int, context: InteractionContext) -> bool:
	var stack := get_slot_stack(index)
	if stack == null:
		return false
	var usable := stack.item.get_usable()
	if usable == null or not usable.can_use(context):
		return false
	# Consume first so the slot can't be used twice while effects are running.
	if usable.consumed:
		remove_at(index, 1)
	await usable.use(context)
	if usable.action_cost > 0:
		await TimeManager.spend_actions(usable.action_cost)
	return true
