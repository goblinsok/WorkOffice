extends Node
## CutsceneManager: plays CutsceneData step by step and decides whether the interaction
## that triggered it proceeds. Views react through GlobalSignals (cutscene_started /
## cutscene_finished / cutscene_background_requested); the overlay calls advance() / skip().

## Emitted when the player clicks (advance) or skips.
signal advanced()

var current: CutsceneData
var _skipped: bool = false
var _waiting: bool = false
var _stage_changed: bool = false


func is_playing() -> bool:
	return current != null


func is_waiting_for_click() -> bool:
	return _waiting


## Continues a step that waits for a click. Does nothing otherwise.
func advance() -> void:
	if _waiting:
		_waiting = false
		advanced.emit()


## Ends the cutscene as soon as possible (keeps the current proceed/cancel value).
func skip() -> void:
	if current == null:
		return
	_skipped = true
	if DialogManager.is_active():
		DialogManager.stop()
	_waiting = false
	advanced.emit()


## Plays the first matching cutscene triggered by the interaction. Returns true if the
## interaction should proceed (also when nothing matched). Await it.
func try_trigger_interaction(interaction: InteractionData, context: InteractionContext = null) -> bool:
	var cutscene := GameState.cutscenes.find_for_interaction(interaction, context)
	if cutscene == null:
		return true
	return await play(cutscene, context)


## Called after an interaction or item use finished: plays the first matching
## trigger_after_action cutscene, if any. Await it.
func try_trigger_after_action(context: InteractionContext = null) -> void:
	if current != null:
		return
	var cutscene := GameState.cutscenes.find_after_action(context)
	if cutscene != null:
		await play(cutscene, context)


## Plays a cutscene to its end. Returns true if the triggering action should proceed.
func play(cutscene: CutsceneData, context: InteractionContext = null) -> bool:
	if current != null:
		push_warning("A cutscene is already playing, ignoring '%s'" % cutscene.id)
		return true
	if context == null:
		context = InteractionContext.new()
	context.action_cancelled = cutscene.cancels_action
	current = cutscene
	_skipped = false
	_waiting = false
	_stage_changed = false
	GameState.world_info.set_flag(cutscene.seen_flag())
	GlobalSignals.cutscene_started.emit(cutscene)

	var steps := cutscene.steps
	for i in steps.size():
		var step := steps[i]
		if step == null:
			continue
		if i > 0 and step.wait_for_click:
			await _wait_for_click()
			if _skipped:
				break
		await step.run(context)
		if _skipped:
			break
	if not _skipped and not steps.is_empty() and steps[-1] is CutsceneBackgroundStep:
		await _wait_for_click()

	var faded := false
	if _stage_changed:
		await ScreenFader.fade_out()
		GlobalSignals.cutscene_background_requested.emit(null)
		faded = true
	current = null
	_stage_changed = false
	GlobalSignals.cutscene_finished.emit(cutscene)
	if faded:
		await ScreenFader.fade_in()
	return not context.action_cancelled


## Called by CutsceneBackgroundStep.
func show_background(step: CutsceneBackgroundStep) -> void:
	if step.fade:
		await ScreenFader.fade_out()
	GlobalSignals.cutscene_background_requested.emit(step)
	_stage_changed = true
	if step.fade:
		await ScreenFader.fade_in()


func _wait_for_click() -> void:
	_waiting = true
	await advanced
	_waiting = false
