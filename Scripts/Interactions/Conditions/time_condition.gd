class_name TimeCondition extends InteractionCondition
## Met during the ticked phases and weekdays. Nothing ticked in a group means "any".
## Bit i is Enums.TIME_STATE / Enums.WEEK_STATE value i, so the checkbox names below must
## follow those enums' order.

@export_flags("Morning", "Afternoon", "Evening") var phases: int = 0
@export_flags("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday") var days: int = 0


func is_met(_context: InteractionContext) -> bool:
	var world := GameState.world_info
	return _allows(phases, world.current_time) and _allows(days, world.current_day)


static func _allows(mask: int, value: int) -> bool:
	return mask == 0 or (mask & (1 << value)) != 0
