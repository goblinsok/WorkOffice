extends Node
## ActionManager: runs the Action minigame. The girl is shown alone in a staged copy of her
## location, at her point, in the current ActionSceneData's pose; her placement is never changed.
## Views react through GlobalSignals (action_started / action_scene_changed / action_finished /
## action_stage_requested); UI/Action/action_overlay calls perform() / switch_to() / end().

## The player ended the minigame (internal: play() awaits it).
signal _ended()

## The scene being played, null outside the minigame.
var current: ActionSceneData
## The girl, her real location and point, and her staged view (for bubbles and option layout).
var context: InteractionContext

## An option or a scene switch is running.
var _busy: bool = false


func is_playing() -> bool:
	return context != null


func is_busy() -> bool:
	return _busy


## Scenes offered right now (the bottom bar).
func get_available_scenes() -> Array[ActionSceneData]:
	return GameState.action_scenes.get_available(context)


## Options of the current scene to show around the girl.
func get_visible_options() -> Array[InteractionData]:
	if current == null:
		return []
	return current.get_visible_options(context)


## Plays the minigame with the source's girl, location and point until end() is called. Await it.
## Starts at start_scene if it is available, otherwise at the first available scene; does
## nothing if none is.
func play(source: InteractionContext, start_scene: ActionSceneData = null) -> void:
	if is_playing():
		push_warning("The action minigame is already playing")
		return
	var session := InteractionContext.new().with_girl(source.girl)
	session.location = source.location
	session.poi = source.poi
	var scenes := GameState.action_scenes.get_available(session)
	if scenes.is_empty():
		push_warning("No action scene available for this context")
		return
	if start_scene == null or not start_scene in scenes:
		start_scene = scenes[0]

	context = session
	_busy = true
	await ScreenFader.fade_out()
	_stage(start_scene)
	GlobalSignals.action_started.emit(start_scene)
	await ScreenFader.fade_in()
	_busy = false

	await _ended

	_busy = true
	await ScreenFader.fade_out()
	GlobalSignals.action_stage_requested.emit(null)
	current = null
	context = null
	GlobalSignals.action_finished.emit()
	await ScreenFader.fade_in()
	_busy = false


## Changes the scene (with a fade). Ignored while busy or if the scene isn't available.
func switch_to(scene: ActionSceneData) -> void:
	if not is_playing() or _busy or scene == current or not scene in get_available_scenes():
		return
	_busy = true
	await ScreenFader.fade_out()
	_stage(scene)
	GlobalSignals.action_scene_changed.emit(scene)
	await ScreenFader.fade_in()
	_busy = false


## Runs an option's effects with the minigame context. Spends no actions. Await it.
func perform(option: InteractionData) -> void:
	if not is_playing() or _busy or not option in get_visible_options() or not option.is_available(context):
		return
	_busy = true
	await option.execute(context)
	_busy = false


## Ends the minigame (the overlay asks for confirmation first). Ignored while busy.
func end() -> void:
	if is_playing() and not _busy:
		_ended.emit()


## Shows the girl alone at her point in the scene's pose and points the context at that view.
func _stage(scene: ActionSceneData) -> void:
	current = scene
	var staging := CutsceneGirlStaging.new()
	staging.girl = context.girl.id
	staging.poi = context.poi.id
	staging.pose = scene.pose
	staging.location = context.location
	GlobalSignals.action_stage_requested.emit(staging)
	context.view = null
	for node in get_tree().get_nodes_in_group(&"staged_girl_views"):
		var girl_view := node as BaseGirlLocation
		if girl_view and girl_view.get_girl() == context.girl:
			context.view = girl_view
