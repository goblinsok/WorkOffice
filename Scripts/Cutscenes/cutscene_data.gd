class_name CutsceneData extends Resource
## A cutscene: ordered steps (dialogs, background changes) plus the rules for auto-triggering.
## Register it in Resources/Cutscenes/cutscenes_repo.tres to make it trigger automatically.

@export var id: StringName
## Auto-triggers right before this interaction runs (when registered and conditions pass).
## Null means it never auto-triggers. Matched by CutsceneManager.try_trigger_interaction().
@export var trigger_interaction: InteractionData
## Auto-triggers after any interaction or item use finishes (before its actions are spent)
## once the conditions pass. Use it for thresholds, e.g. a GirlStatCondition "Nelle affection >= 10".
## Without play_once it plays again after every action while the conditions hold.
@export var trigger_after_action: bool = false
## All must pass for the cutscene to trigger.
@export var conditions: Array[InteractionCondition] = []
## Triggers only once (tracked with the world flag cutscene_seen:<id>). play() from code always plays.
@export var play_once: bool = true
## Default outcome for the interaction that triggered it: true cancels it (no effects, no actions spent).
@export var cancels_action: bool = false
@export var steps: Array[CutsceneStep] = []


func seen_flag() -> String:
	return "cutscene_seen:%s" % id


func can_trigger(context: InteractionContext) -> bool:
	if play_once and GameState.world_info.get_flag(seen_flag()):
		return false
	for condition in conditions:
		if not condition.is_met(context):
			return false
	return true
