class_name PlayerInfo extends Resource
## Player definition and runtime state: money/fame, employee card fields, placeholder
## skills, per-phase actions and the runtime inventory (built from starting_items).

signal money_update()
signal actions_changed(actions: int, max_actions: int)
## Emitted when any other stat shown on the employee card changes.
signal stats_changed()

@export var money: int:
	set(value):
		money = value
		money_update.emit()

@export var fame: int:
	set(value):
		fame = value
		stats_changed.emit()

@export_group("Employee card")
@export var display_name: String = "You"
@export var position_title: String = "Office Manager"
@export var employee_id: String = "EMP-0001"
@export var photo: Texture2D

@export_group("Skills")
## Placeholder skills for future systems (dialog success, job bonuses, ...).
@export var charisma: int = 1
@export var management: int = 1

@export_group("Actions")
## Actions available per time phase. Every interaction spends some.
@export var max_actions: int = 3
var actions: int = 0:
	set(value):
		actions = clampi(value, 0, max_actions)
		actions_changed.emit(actions, max_actions)

@export_group("Inventory")
@export var inventory_size: int = 24
## Copied into the runtime inventory when a new game starts.
@export var starting_items: Array[ItemStack] = []

## Runtime inventory, created by GameState.
var inventory: Inventory


func refill_actions() -> void:
	actions = max_actions


func create_inventory() -> void:
	inventory = Inventory.new()
	inventory.resize(inventory_size)
	for stack in starting_items:
		if stack and stack.item:
			inventory.add_item(stack.item, stack.count)
