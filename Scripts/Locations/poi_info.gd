class_name PoiInfo extends Resource
## A point of interest inside a location: a spot where a girl can be spawned.
## Only girls that have a PoiGirlSetup here can appear at this point.

@export var id: StringName
## Minimum LocationInfo.upgrade_level for this point to be used.
@export var required_upgrade_level: int = 0
@export var girl_setups: Array[PoiGirlSetup] = []


func is_active(location: LocationInfo) -> bool:
	return location.upgrade_level >= required_upgrade_level


func get_setup_for(girl_id: StringName) -> PoiGirlSetup:
	for setup in girl_setups:
		if setup.girl_id == girl_id:
			return setup
	return null
