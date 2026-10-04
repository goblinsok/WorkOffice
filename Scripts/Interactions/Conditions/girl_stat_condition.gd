class_name GirlStatCondition extends InteractionCondition
## Compares a girl's stat. girl NONE means the girl in context (the clicked girl or the
## item's target); set a girl when it must be a specific one (e.g. a cutscene threshold).

@export var girl: Ids.Girl = Ids.Girl.NONE
@export var stat: Ids.Stat = Ids.Stat.AFFECTION
@export var comparison: Comparison = Comparison.AT_LEAST
## Ignored by BELOW_MAX.
@export var amount: int = 0


func is_met(context: InteractionContext) -> bool:
	var target := get_target_girl(context)
	if target == null:
		return false
	return compare(target.get_stat(stat), target.get_stat_max(stat), comparison, amount)


func get_target_girl(context: InteractionContext) -> GirlInfo:
	if girl == Ids.Girl.NONE:
		return context.girl if context else null
	return GameState.girls.get_by_id(girl)
