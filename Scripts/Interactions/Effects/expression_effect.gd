class_name ExpressionEffect extends InteractionEffect
## Runs a script expression for its side effects (see GameExpression).
## Example: "add_money(-10)", "set_flag('gave_gift')"

@export_multiline var expression: String
## Player-facing text for tooltips, since an expression can't describe itself.
@export var description: String


func execute(context: InteractionContext) -> void:
	GameExpression.evaluate(expression, context)


func describe() -> String:
	return description
