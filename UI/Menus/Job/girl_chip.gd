class_name GirlChip extends PanelContainer
## Draggable token for a girl. Drop it on a GirlDropZone to assign/unassign her.
## mouse_filter is PASS, so drops on a chip reach the zone that contains it.

const DRAG_TYPE := &"girl_chip"

@onready var color_bar: ColorRect = %ColorBar
@onready var name_label: Label = %NameLabel
@onready var info_label: Label = %InfoLabel

var girl: GirlInfo


func setup(p_girl: GirlInfo) -> void:
	girl = p_girl
	name_label.text = girl.display_name
	info_label.text = "ATK %d · EN %d/%d" % [girl.attack, girl.energy, girl.max_energy]
	color_bar.color = girl.name_color
	tooltip_text = "Drag to assign %s" % girl.display_name


func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview := duplicate() as Control
	preview.modulate.a = 0.8
	preview.size = size
	set_drag_preview(preview)
	return { "type": DRAG_TYPE, "girl_id": girl.id }
