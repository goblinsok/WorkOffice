class_name GirlScheduler extends RefCounted
## Decides where each girl is during a time phase. Default rules:
##   - A candidate is a free, active point where the girl has an available setup (its
##     conditions pass). Among her available setups there, one is picked at random.
##   - At most one girl per point.
##   - Girls move: each girl goes to a point other than her previous one whenever possible.
##     Several random orders are tried and the best is kept (most girls placed, then most
##     girls moved), so one girl taking the only free spot can't strand another.
## Subclass and override _pick_candidate() (or schedule()) for schedules, preferences, events, ...

## Random orders tried before settling for the best one found.
const MAX_ATTEMPTS := 32


## Returns placements keyed by girl. A girl without a free candidate spot is left out.
## world.placements still holds the previous phase's placements when this is called.
func schedule(girls: Array[GirlInfo], locations: Array[LocationInfo], world: WorldInfo) -> Dictionary[Ids.Girl, GirlPlacement]:
	var previous: Dictionary[Ids.Girl, PoiInfo] = {}
	for girl_id in world.placements:
		previous[girl_id] = world.placements[girl_id].poi

	var candidates: Dictionary[GirlInfo, Array] = {}
	var placeable := 0
	var movable := 0
	for girl in girls:
		var options := _get_candidates(girl, locations)
		candidates[girl] = options
		if not options.is_empty():
			placeable += 1
		if options.any(func(option: GirlPlacement) -> bool: return option.poi != previous.get(girl.id)):
			movable += 1

	var best: Dictionary[Ids.Girl, GirlPlacement] = {}
	var best_score := -1
	for attempt in MAX_ATTEMPTS:
		var result := _attempt(girls, candidates, previous, world)
		var moved := result.values().filter(
			func(placement: GirlPlacement) -> bool: return placement.poi != previous.get(placement.girl.id)).size()
		var score := result.size() * (girls.size() + 1) + moved
		if score > best_score:
			best = result
			best_score = score
		if result.size() == placeable and moved == movable:
			break
	return best


## One greedy pass in a random order. Free spots other than the girl's previous one are preferred.
func _attempt(girls: Array[GirlInfo], candidates: Dictionary[GirlInfo, Array], previous: Dictionary[Ids.Girl, PoiInfo], world: WorldInfo) -> Dictionary[Ids.Girl, GirlPlacement]:
	var result: Dictionary[Ids.Girl, GirlPlacement] = {}
	var occupied: Dictionary[PoiInfo, bool] = {}
	var order := girls.duplicate()
	order.shuffle()
	for girl: GirlInfo in order:
		var free: Array[GirlPlacement] = []
		free.assign(candidates[girl].filter(func(option: GirlPlacement) -> bool: return not occupied.has(option.poi)))
		var moving: Array[GirlPlacement] = []
		moving.assign(free.filter(func(option: GirlPlacement) -> bool: return option.poi != previous.get(girl.id)))
		var pool := moving if not moving.is_empty() else free
		if pool.is_empty():
			continue
		var placement := _pick_candidate(girl, pool, world)
		occupied[placement.poi] = true
		result[girl.id] = placement
	return result


## Every active point where the girl has an available setup (one random setup per point).
func _get_candidates(girl: GirlInfo, locations: Array[LocationInfo]) -> Array[GirlPlacement]:
	var candidates: Array[GirlPlacement] = []
	for location in locations:
		if not location.is_available():
			continue
		for poi in location.get_active_pois():
			var setups := poi.get_available_setups(girl, location)
			if not setups.is_empty():
				candidates.append(GirlPlacement.new(girl, location, poi, setups.pick_random()))
	return candidates


## Override to change how a spot is chosen among valid candidates.
func _pick_candidate(_girl: GirlInfo, candidates: Array[GirlPlacement], _world: WorldInfo) -> GirlPlacement:
	return candidates.pick_random()
