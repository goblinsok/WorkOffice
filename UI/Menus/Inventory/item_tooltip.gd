class_name ItemTooltip extends VBoxContainer
## Tooltip content for an item: name, flavor text, effect description and usage hint.

@onready var name_label: Label = %NameLabel
@onready var flavor_label: Label = %FlavorLabel
@onready var effect_label: Label = %EffectLabel
@onready var hint_label: Label = %HintLabel

## Set before adding to the tree. Godot sizes the tooltip popup right after it is added.
var item: ItemData


func _ready() -> void:
	if item:
		setup(item)


func setup(p_item: ItemData) -> void:
	item = p_item
	name_label.text = item.display_name
	flavor_label.text = item.flavor_text
	flavor_label.visible = not item.flavor_text.is_empty()
	var effect := item.get_effect_text()
	effect_label.text = effect
	effect_label.visible = not effect.is_empty()
	hint_label.visible = item.is_usable()
