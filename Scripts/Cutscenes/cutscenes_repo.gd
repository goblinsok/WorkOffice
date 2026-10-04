class_name CutscenesRepo extends Resource
## Registry of cutscenes that can auto-trigger. Edit Resources/Cutscenes/cutscenes_repo.tres.

@export var cutscenes: Array[CutsceneData] = []


## First registered cutscene triggered by this interaction whose conditions pass, or null.
func find_for_interaction(interaction: InteractionData, context: InteractionContext) -> CutsceneData:
	for cutscene in cutscenes:
		if interaction != null and cutscene.trigger_interaction == interaction and cutscene.can_trigger(context):
			return cutscene
	return null


## First registered after-action cutscene whose conditions pass, or null.
func find_after_action(context: InteractionContext) -> CutsceneData:
	for cutscene in cutscenes:
		if cutscene.trigger_after_action and cutscene.can_trigger(context):
			return cutscene
	return null
