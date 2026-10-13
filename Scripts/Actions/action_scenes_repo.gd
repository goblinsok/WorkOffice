class_name ActionScenesRepo extends Resource
## Registry of every Action minigame scene. Edit Resources/ActionScenes/action_scenes_repo.tres
## to add scenes. The order is the order of the minigame's bottom bar.

@export var scenes: Array[ActionSceneData] = []


## Scenes offered to the context girl at her point right now. Empty without a girl, location or point.
func get_available(context: InteractionContext) -> Array[ActionSceneData]:
	var result: Array[ActionSceneData] = []
	if context == null or context.girl == null or context.location == null or context.poi == null:
		return result
	for scene in scenes:
		if scene != null and scene.is_available(context):
			result.append(scene)
	return result


func get_by_id(scene_id: StringName) -> ActionSceneData:
	for scene in scenes:
		if scene != null and scene.id == scene_id:
			return scene
	return null
