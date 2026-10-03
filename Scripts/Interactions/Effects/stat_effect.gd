class_name StatEffect extends InteractionEffect
## Changes a stat of the girl in context by a fixed amount.

@export var stat: StringName = &"affection"
@export var amount: int = 1


func execute(context: InteractionContext) -> void:
	context.add_stat(stat, amount)


func describe() -> String:
	return "%+d %s" % [amount, String(stat).capitalize()]
