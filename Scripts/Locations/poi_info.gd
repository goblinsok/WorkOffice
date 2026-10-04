class_name PoiInfo extends Resource
## A point of interest inside a location: a spot where a girl can be spawned.
## Only girls that have an available PoiGirlSetup here can appear at this point.

@export var id: Ids.Poi
## Minimum LocationInfo.upgrade_level for this point to be used.
@export var required_upgrade_level: int = 0
## Any number per girl; see PoiGirlSetup.
@export var girl_setups: Array[PoiGirlSetup] = []


func is_active(location: LocationInfo) -> bool:
	return location.upgrade_level >= required_upgrade_level


## Every setup of this girl here, ignoring conditions.
func get_setups_for(girl: Ids.Girl) -> Array[PoiGirlSetup]:
	return girl_setups.filter(func(setup: PoiGirlSetup) -> bool: return setup != null and setup.girl == girl)


## The girl's setups here whose conditions pass right now.
func get_available_setups(girl: GirlInfo, location: LocationInfo) -> Array[PoiGirlSetup]:
	var context := InteractionContext.new().with_girl(girl)
	context.location = location
	context.poi = self
	return get_setups_for(girl.id).filter(func(setup: PoiGirlSetup) -> bool: return setup.is_available(context))
