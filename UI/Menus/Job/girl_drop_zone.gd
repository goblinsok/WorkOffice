class_name GirlDropZone extends PanelContainer
## Accepts dropped GirlChips. slot_index >= 0 is an assignment slot; -1 is the
## "available" pool (dropping there unassigns). The zone only reports the drop;
## the owning menu decides what it means.

signal girl_dropped(girl_id: Ids.Girl, slot_index: int)

const POOL := -1

@export var slot_index: int = POOL
@export var normal_style: StyleBox
@export var highlight_style: StyleBox

@onready var chips: Container = %Chips
@onready var placeholder: Label = %Placeholder


func _ready() -> void:
	mouse_exited.connect(_set_highlight.bind(false))
	_set_highlight(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_set_highlight(false)


func set_placeholder_visible(value: bool) -> void:
	placeholder.visible = value


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var ok: bool = data is Dictionary and data.get("type") == GirlChip.DRAG_TYPE
	_set_highlight(ok)
	return ok


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_set_highlight(false)
	girl_dropped.emit(data.girl_id, slot_index)


func _set_highlight(value: bool) -> void:
	var style := highlight_style if value else normal_style
	if style:
		add_theme_stylebox_override("panel", style)
