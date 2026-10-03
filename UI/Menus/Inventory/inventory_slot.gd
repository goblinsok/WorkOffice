class_name InventorySlotUI extends PanelContainer
## One cell of the inventory grid. Shows a stack, provides the custom tooltip,
## supports drag & drop to rearrange, and right-click/double-click to use.

signal use_requested(index: int)
signal move_requested(from: int, to: int)

const TOOLTIP_SCENE := preload("res://UI/Menus/Inventory/item_tooltip.tscn")
const DRAG_TYPE := &"inventory_slot"

@export var normal_style: StyleBox
@export var hover_style: StyleBox

@onready var icon_rect: TextureRect = %Icon
@onready var short_label: Label = %ShortLabel
@onready var count_label: Label = %CountLabel

var index: int = -1
var stack: ItemStack


func _ready() -> void:
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))
	_set_hover(false)


func set_stack(p_index: int, p_stack: ItemStack) -> void:
	index = p_index
	stack = p_stack
	var item := stack.item if stack else null
	icon_rect.texture = item.icon if item else null
	short_label.text = item.short_name if item else ""
	count_label.text = str(stack.count) if stack and stack.count > 1 else ""
	# A non-empty tooltip_text is what makes Godot call _make_custom_tooltip().
	tooltip_text = item.display_name if item else ""


func _make_custom_tooltip(_for_text: String) -> Object:
	if stack == null:
		return null
	var tooltip: ItemTooltip = TOOLTIP_SCENE.instantiate()
	tooltip.item = stack.item
	return tooltip


func _gui_input(event: InputEvent) -> void:
	if stack == null or not event is InputEventMouseButton or not event.pressed:
		return
	var is_right_click: bool = event.button_index == MOUSE_BUTTON_RIGHT
	var is_double_click: bool = event.button_index == MOUSE_BUTTON_LEFT and event.double_click
	if is_right_click or is_double_click:
		accept_event()
		use_requested.emit(index)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if stack == null:
		return null
	var preview := TextureRect.new()
	preview.texture = stack.item.icon
	preview.custom_minimum_size = Vector2(48, 48)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.modulate.a = 0.8
	set_drag_preview(preview)
	return { "type": DRAG_TYPE, "index": index }


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("type") == DRAG_TYPE


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	move_requested.emit(data.index, index)


func _set_hover(is_hovered: bool) -> void:
	var style := hover_style if is_hovered and stack else normal_style
	if style:
		add_theme_stylebox_override("panel", style)
