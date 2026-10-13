extends Node
## InteractionManager: runs interactions and makes sure only one runs at a time.

var is_busy: bool = false


## Interactions that should appear in the menu for this context.
func get_visible_interactions(context: InteractionContext) -> Array[InteractionData]:
	return context.get_interactions().filter(
		func(interaction: InteractionData) -> bool: return interaction.is_visible(context))


func can_interact() -> bool:
	return not is_busy and not TimeManager.is_transitioning and not DialogManager.is_active() \
			and not CutsceneManager.is_playing() and not ActionManager.is_playing()


func run(interaction: InteractionData, context: InteractionContext) -> void:
	if not can_interact() or not interaction.is_available(context):
		return
	is_busy = true
	var had_view := context.view != null
	var proceed: bool = await CutsceneManager.try_trigger_interaction(interaction, context)
	if not proceed:
		is_busy = false
		return
	if had_view:
		refresh_view(context)
	GlobalSignals.interaction_started.emit(interaction, context)

	await interaction.execute(context)

	GlobalSignals.interaction_finished.emit(interaction, context)
	await CutsceneManager.try_trigger_after_action(context)
	is_busy = false
	# Spend actions last so a phase change never interrupts a running interaction.
	await TimeManager.spend_actions(interaction.action_cost)


## A cutscene or action scene that staged a location rebuilds the world view, which frees the
## clicked girl's view. Points the context at the girl's new view (or null if she is not in the world).
func refresh_view(context: InteractionContext) -> void:
	if is_instance_valid(context.view):
		return
	context.view = null
	for node in get_tree().get_nodes_in_group(&"girl_views"):
		var girl_view := node as BaseGirlLocation
		if girl_view and girl_view.get_girl() == context.girl:
			context.view = girl_view
			return
