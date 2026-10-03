extends Node
## InteractionManager: runs interactions and makes sure only one runs at a time.

var is_busy: bool = false


## Interactions that should appear in the menu for this context.
func get_visible_interactions(context: InteractionContext) -> Array[InteractionData]:
	return context.get_interactions().filter(
		func(interaction: InteractionData) -> bool: return interaction.is_visible(context))


func can_interact() -> bool:
	return not is_busy and not TimeManager.is_transitioning and not DialogManager.is_active()


func run(interaction: InteractionData, context: InteractionContext) -> void:
	if not can_interact() or not interaction.is_available(context):
		return
	is_busy = true
	GlobalSignals.interaction_started.emit(interaction, context)

	await interaction.execute(context)

	GlobalSignals.interaction_finished.emit(interaction, context)
	is_busy = false
	# Spend actions last so a phase change never interrupts a running interaction.
	await TimeManager.spend_actions(interaction.action_cost)
