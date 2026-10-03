class_name GirlScheduler extends RefCounted
## Decides where each girl is during a time phase.
## The default implementation is uniformly random. Subclass and override
## _pick_candidate() (or schedule()) for schedules, preferences, events, etc.


## Returns placements keyed by girl id. A girl without a free candidate spot is left out.
func schedule(girls: Array[GirlInfo], locations: Array[LocationInfo], world: WorldInfo) -> Dictionary[StringName, GirlPlacement]:
	var result: Dictionary[StringName, GirlPlacement] = {}
	var occupied: Dictionary = {} # PoiInfo -> true

	var order := girls.duplicate()
	order.shuffle()
	for girl: GirlInfo in order:
		var candidates := _get_candidates(girl, locations, occupied)
		if candidates.is_empty():
			continue
		var placement := _pick_candidate(girl, candidates, world)
		occupied[placement.poi] = true
		result[girl.id] = placement
	return result


func _get_candidates(girl: GirlInfo, locations: Array[LocationInfo], occupied: Dictionary) -> Array[GirlPlacement]:
	var candidates: Array[GirlPlacement] = []
	for location in locations:
		if not location.is_available():
			continue
		for poi in location.get_active_pois():
			if occupied.has(poi):
				continue
			var setup := poi.get_setup_for(girl.id)
			if setup != null:
				candidates.append(GirlPlacement.new(girl, location, poi, setup))
	return candidates


## Override to change how a spot is chosen among valid candidates.
func _pick_candidate(_girl: GirlInfo, candidates: Array[GirlPlacement], _world: WorldInfo) -> GirlPlacement:
	return candidates.pick_random()
