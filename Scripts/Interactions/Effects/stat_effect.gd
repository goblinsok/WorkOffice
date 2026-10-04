class_name StatEffect extends InteractionEffect
## Changes a stat of the girl in context by a fixed amount.

@export var stat: Ids.Stat = Ids.Stat.AFFECTION
@export var amount: int = 1


func execute(context: InteractionContext) -> void:
	if context.girl:
		context.girl.modify_stat(stat, amount)


func describe() -> String:
	return "%+d %s" % [amount, String(Ids.stat_property(stat)).capitalize()]
