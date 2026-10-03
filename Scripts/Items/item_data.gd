class_name ItemData extends Resource
## Definition of an item. Behaviour is composed from ItemComponents
## (UsableComponent, ...), so new kinds of items rarely need new item classes.

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
## Short text drawn on the slot when there is no real icon art yet.
@export var short_name: String
@export_multiline var flavor_text: String
@export var max_stack: int = 10
## Overrides the auto-generated effect description when not empty.
@export_multiline var effect_description: String
@export var components: Array[ItemComponent] = []


## Returns the first component of the given class, e.g. get_component(UsableComponent).
func get_component(component_class: Script) -> ItemComponent:
	for component in components:
		if is_instance_of(component, component_class):
			return component
	return null


func get_usable() -> UsableComponent:
	return get_component(UsableComponent) as UsableComponent


func is_usable() -> bool:
	return get_usable() != null


func get_effect_text() -> String:
	if not effect_description.is_empty():
		return effect_description
	var parts: PackedStringArray = []
	for component in components:
		var text := component.describe()
		if not text.is_empty():
			parts.append(text)
	return "\n".join(parts)
