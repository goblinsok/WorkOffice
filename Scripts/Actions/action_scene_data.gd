class_name ActionSceneData extends Resource
## One scene of the Action minigame (Bowing, ...): the girl's pose, when the scene is offered,
## and the options shown around her. Register it in Resources/ActionScenes/action_scenes_repo.tres.
## Conditions and options get the minigame context: the girl, her real location and point, and
## (options only) her staged view.

@export var id: StringName
@export var label: String
## Shown in the minigame's bottom bar.
@export var icon: Texture2D
## Her pose in this scene: picks her scene from GirlInfo.poses.
@export var pose: Ids.Pose = Ids.Pose.STANDING
## All must pass for the scene to be offered (location, time, girl or player stats, ...).
@export var conditions: Array[InteractionCondition] = []
## Shown around the girl. Shared files in Resources/ActionScenes/Options/. They spend no
## actions (the Action interaction pays once), so keep their action_cost at 0.
@export var options: Array[InteractionData] = []


func is_available(context: InteractionContext) -> bool:
	for condition in conditions:
		if condition != null and not condition.is_met(context):
			return false
	return true


func get_visible_options(context: InteractionContext) -> Array[InteractionData]:
	return options.filter(func(option: InteractionData) -> bool: return option != null and option.is_visible(context))
