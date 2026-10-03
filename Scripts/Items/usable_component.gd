class_name UsableComponent extends ItemComponent
## Makes an item usable from the inventory. Reuses the interaction condition/effect
## system, so anything an interaction can do, an item can do too.

enum Target {
	## Used directly (affects the player/world).
	NONE,
	## The player picks a girl. context.girl is set to her.
	GIRL,
}

@export var target: Target = Target.NONE
@export var consumed: bool = true
## Actions spent when used. 0 means free.
@export var action_cost: int = 0
@export var conditions: Array[InteractionCondition] = []
@export var effects: Array[InteractionEffect] = []


func can_use(context: InteractionContext) -> bool:
	if target == Target.GIRL and context.girl == null:
		return false
	if action_cost > 0 and GameState.player_stats.actions < action_cost:
		return false
	for condition in conditions:
		if not condition.is_met(context):
			return false
	return true


func use(context: InteractionContext) -> void:
	for effect in effects:
		await effect.execute(context)


func describe() -> String:
	var parts: PackedStringArray = []
	for effect in effects:
		var text := effect.describe()
		if not text.is_empty():
			parts.append(text)
	if parts.is_empty():
		return ""
	var prefix := "Use on a girl: " if target == Target.GIRL else "Use: "
	var text := prefix + ", ".join(parts)
	if action_cost > 0:
		text += " (costs %d action%s)" % [action_cost, "" if action_cost == 1 else "s"]
	return text
