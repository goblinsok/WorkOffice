@tool
class_name CutsceneGirlStaging extends Resource
## One girl placed in a staged location of a CutsceneBackgroundStep.
## In the inspector the poi dropdown lists only the points of the step's location.

@export var girl: Ids.Girl = Ids.Girl.NONE
## Point of interest the girl stands at. It must be one of the step location's PoiInfos.
@export var poi: Ids.Poi = Ids.Poi.NONE
@export var animation: StringName = &"Standing"

## Set by the owning CutsceneBackgroundStep. Only used to filter the poi dropdown.
var location: LocationInfo:
	set(value):
		location = value
		notify_property_list_changed()


func _validate_property(property: Dictionary) -> void:
	if property.name != "poi" or location == null:
		return
	var options: PackedStringArray = ["NONE:%d" % Ids.Poi.NONE]
	for point in location.points_of_interest:
		if point != null and point.id != Ids.Poi.NONE:
			options.append("%s:%d" % [Ids.name_of(Ids.Poi, point.id), point.id])
	property.hint = PROPERTY_HINT_ENUM
	property.hint_string = ",".join(options)
