class_name WorldInfo extends Resource
## Runtime state of the world: calendar, current location and where the girls are.

var current_time: Enums.TIME_STATE = Enums.TIME_STATE.MORNING
var current_day: Enums.WEEK_STATE = Enums.WEEK_STATE.MONDAY
## Total days passed since the game started (never wraps).
var day_count: int = 0

var current_location: LocationInfo

## girl id -> placement for the current time phase.
var placements: Dictionary[StringName, GirlPlacement] = {}

## Generic story/progress flags usable from dialogs and conditions.
var flags: Dictionary = {}


func is_last_phase_of_day() -> bool:
	return current_time == Enums.TIME_STATE.size() - 1


## Moves to the next phase and wraps into the next day after the last one.
## Returns true if a new day started.
func advance_time() -> bool:
	var next_time := current_time + 1
	if next_time < Enums.TIME_STATE.size():
		current_time = next_time as Enums.TIME_STATE
		return false
	current_time = 0 as Enums.TIME_STATE
	advance_day()
	return true


func advance_day() -> void:
	current_day = ((current_day + 1) % Enums.WEEK_STATE.size()) as Enums.WEEK_STATE
	day_count += 1


func get_placements_in(location: LocationInfo) -> Array[GirlPlacement]:
	var result: Array[GirlPlacement] = []
	for placement: GirlPlacement in placements.values():
		if placement.location == location:
			result.append(placement)
	return result


func get_flag(flag_name: String, default: Variant = false) -> Variant:
	return flags.get(flag_name, default)


func set_flag(flag_name: String, value: Variant = true) -> void:
	flags[flag_name] = value
