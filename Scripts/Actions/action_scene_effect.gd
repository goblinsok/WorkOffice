class_name ActionSceneEffect extends InteractionEffect
## Plays the Action minigame with the context girl and waits until the player ends it.
## Pair it with an ActionScenesAvailableCondition on the same interaction.

## Scene to open first. Empty (or not available) means the first available one.
@export var start_scene: ActionSceneData


func execute(context: InteractionContext) -> void:
	await ActionManager.play(context, start_scene)
	# The minigame rebuilt the world view, which freed the clicked girl's view.
	InteractionManager.refresh_view(context)
