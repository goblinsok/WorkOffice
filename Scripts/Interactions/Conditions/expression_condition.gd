class_name ExpressionCondition extends InteractionCondition
## Condition written as a script expression (see GameExpression).
## Example: "player.money >= 10", "girl.affection > 5 and not flag('angry')"

@export_multiline var expression: String


func is_met(context: InteractionContext) -> bool:
	return GameExpression.check(expression, context)
