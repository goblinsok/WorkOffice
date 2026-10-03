class_name GameExpression extends RefCounted
## Shared evaluator for script expressions used by dialogs, conditions and effects.
##
## Available variables: girl, player, world, location, name (girl display name).
## Available functions: public methods of InteractionContext (add_stat, add_money, flag, set_flag, ...).
## Example: "girl.affection >= 5 and flag('met_lidya')"

const VARIABLE_NAMES: PackedStringArray = ["girl", "player", "world", "location", "name"]

static var _cache: Dictionary = {} # String -> Expression
static var _interpolation_regex: RegEx


## Evaluates an expression and returns its value, or null if it failed (an error is printed).
static func evaluate(source: String, context: InteractionContext) -> Variant:
	var expression := _get_expression(source)
	if expression == null:
		return null
	var result: Variant = expression.execute(_get_inputs(context), context)
	if expression.has_execute_failed():
		push_error("Expression failed: '%s' -> %s" % [source, expression.get_error_text()])
		return null
	return result


## Evaluates an expression as a condition. Empty source counts as true.
static func check(source: String, context: InteractionContext) -> bool:
	if source.strip_edges().is_empty():
		return true
	return bool(evaluate(source, context))


## Replaces every {expression} in text with its evaluated value.
static func interpolate(text: String, context: InteractionContext) -> String:
	if not "{" in text:
		return text
	if _interpolation_regex == null:
		_interpolation_regex = RegEx.create_from_string("\\{([^{}]+)\\}")
	var result := text
	for found in _interpolation_regex.search_all(text):
		var value: Variant = evaluate(found.get_string(1), context)
		result = result.replace(found.get_string(0), str(value))
	return result


static func _get_expression(source: String) -> Expression:
	if _cache.has(source):
		return _cache[source]
	var expression := Expression.new()
	var error := expression.parse(source, VARIABLE_NAMES)
	if error != OK:
		push_error("Expression parse error: '%s' -> %s" % [source, expression.get_error_text()])
		return null
	_cache[source] = expression
	return expression


static func _get_inputs(context: InteractionContext) -> Array:
	var girl: GirlInfo = context.girl if context else null
	return [
		girl,
		GameState.player_stats,
		GameState.world_info,
		context.location if context else null,
		girl.display_name if girl else "",
	]
