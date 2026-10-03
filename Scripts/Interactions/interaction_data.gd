class_name InteractionData extends Resource
## A single option in the interaction menu (Talk, Look, Reward, ...).
## Shared .tres files can be reused by many PoiGirlSetups. Behaviour is composed
## from conditions (when it is offered) and effects (what it does, run in order).

@export var id: StringName
@export var label: String
@export var icon: Texture2D
## Actions spent after the interaction finishes.
@export var action_cost: int = 1
## If true, the option is hidden when a condition fails. Otherwise it is shown disabled.
@export var hide_if_unavailable: bool = false

## All must pass for the option to be usable.
@export var conditions: Array[InteractionCondition] = []
## Executed sequentially. Async effects (dialogs) are awaited.
@export var effects: Array[InteractionEffect] = []


func is_available(context: InteractionContext) -> bool:
	if GameState.player_stats.actions < action_cost:
		return false
	for condition in conditions:
		if not condition.is_met(context):
			return false
	return true


func is_visible(context: InteractionContext) -> bool:
	return not hide_if_unavailable or is_available(context)


func execute(context: InteractionContext) -> void:
	for effect in effects:
		await effect.execute(context)
