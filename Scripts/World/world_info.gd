class_name WorldInfo extends Resource

var current_time : Enums.TIME_STATE = Enums.TIME_STATE.MORNING
var current_day : Enums.WEEK_STATE = Enums.WEEK_STATE.MONDAY

var current_location: LocationInfo

var gym_location : GymInfo  = GymInfo.new()
var working_area_location : WorkingAreaInfo  = WorkingAreaInfo.new()
#var gym_location : GymInfo

func advance_time() -> void:
	var time_index = current_time + 1
	if Enums.TIME_STATE.find_key(time_index) != null:
		current_time = Enums.TIME_STATE.find_key(time_index)
	else:
		current_time = Enums.TIME_STATE.find_key(1)
		
func advance_day() -> void:
	var day_index = current_day + 1
	if Enums.WEEK_STATE.find_key(day_index) != null:
		current_day = Enums.WEEK_STATE.find_key(day_index)
	else:
		current_day = Enums.WEEK_STATE.find_key(1)
