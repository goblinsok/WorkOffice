class_name ActionScenesAvailableCondition extends InteractionCondition
## Met when at least one Action minigame scene is available for the context girl at her point.


func is_met(context: InteractionContext) -> bool:
	return not GameState.action_scenes.get_available(context).is_empty()
