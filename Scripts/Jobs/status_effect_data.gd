class_name StatusEffectData extends Resource
## A buff or debuff on a boss. It modifies battle numbers through Ids.BossModifier keys
## (see Ids.BossModifier for what each one does).

@export var display_name: String
@export_multiline var description: String
@export var is_debuff: bool = false
@export var modifiers: Dictionary[Ids.BossModifier, int] = {}


func get_modifier(modifier: Ids.BossModifier) -> int:
	return modifiers.get(modifier, 0)
