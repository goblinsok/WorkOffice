extends BaseMenu
## Grid inventory. Slots are views of Inventory.slots and rebuild on Inventory.changed.
## Items that target a girl open a girl picker first.

const SLOT_SCENE := preload("res://UI/Menus/Inventory/inventory_slot.tscn")
const FEEDBACK_TIME := 2.5

@onready var grid: GridContainer = %Grid
@onready var girl_picker: PopupMenu = %GirlPicker
@onready var feedback_label: Label = %FeedbackLabel

var _slots: Array[InventorySlotUI] = []
var _pending_index: int = -1


func _ready() -> void:
	super._ready()
	girl_picker.id_pressed.connect(_on_girl_picked)
	feedback_label.text = ""


func _on_open() -> void:
	var inventory := _inventory()
	if not inventory.changed.is_connected(_refresh):
		inventory.changed.connect(_refresh)
	_refresh()


func _on_close() -> void:
	var inventory := _inventory()
	if inventory.changed.is_connected(_refresh):
		inventory.changed.disconnect(_refresh)
	girl_picker.hide()


func _inventory() -> Inventory:
	return GameState.player_stats.inventory


func _refresh() -> void:
	var inventory := _inventory()
	while _slots.size() < inventory.get_size():
		var slot: InventorySlotUI = SLOT_SCENE.instantiate()
		grid.add_child(slot)
		slot.use_requested.connect(_on_use_requested)
		slot.move_requested.connect(func(from: int, to: int): inventory.move(from, to))
		_slots.append(slot)
	for i in _slots.size():
		_slots[i].set_stack(i, inventory.get_slot_stack(i))


func _on_use_requested(index: int) -> void:
	var stack := _inventory().get_slot_stack(index)
	if stack == null:
		return
	var usable := stack.item.get_usable()
	if usable == null:
		_show_feedback("%s can't be used." % stack.item.display_name)
		return
	if usable.target == UsableComponent.Target.GIRL:
		_open_girl_picker(index, usable)
	else:
		_use(index, InteractionContext.new())


func _open_girl_picker(index: int, usable: UsableComponent) -> void:
	_pending_index = index
	girl_picker.clear()
	var girls := GameState.get_girls()
	for i in girls.size():
		girl_picker.add_item(girls[i].display_name, i)
		girl_picker.set_item_disabled(i, not usable.can_use(InteractionContext.new().with_girl(girls[i])))
	girl_picker.position = Vector2i(get_global_mouse_position())
	girl_picker.reset_size()
	girl_picker.popup()


func _on_girl_picked(girl_index: int) -> void:
	var girl := GameState.get_girls()[girl_index]
	_use(_pending_index, InteractionContext.new().with_girl(girl))
	_pending_index = -1


func _use(index: int, context: InteractionContext) -> void:
	var item := _inventory().get_slot_stack(index).item
	var used: bool = await _inventory().use_at(index, context)
	if not used:
		_show_feedback("Can't use %s right now." % item.display_name)
		return
	var target := "%s: " % context.girl.display_name if context.girl else ""
	_show_feedback("Used %s. %s%s" % [item.display_name, target, item.get_effect_text().get_slice(": ", 1)])


func _show_feedback(text: String) -> void:
	feedback_label.text = text
	var tween := create_tween()
	feedback_label.modulate.a = 1.0
	tween.tween_interval(FEEDBACK_TIME)
	tween.tween_property(feedback_label, "modulate:a", 0.0, 0.4)
