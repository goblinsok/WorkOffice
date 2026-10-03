class_name StatusEffectData extends Resource
## A buff or debuff on a boss. It modifies battle numbers through named modifiers.
## Supported keys:
##   attack       - added to the boss's attack
##   damage_taken - added to every hit the boss receives

@export var display_name: String
@export_multiline var description: String
@export var is_debuff: bool = false
@export var modifiers: Dictionary[StringName, int] = {}


func get_modifier(stat: StringName) -> int:
	return modifiers.get(stat, 0)
