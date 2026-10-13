class_name BaseLocation extends Node2D
## Base for every location scene. Finds its PointOfInterest nodes and spawns
## the girls that WorldInfo placed here. Set `info` before adding it to the tree.

var info: LocationInfo
## Staging (cutscenes, action scenes): set both before add_child. A staged location ignores
## WorldInfo placements and spawns only staged_girls (non-clickable, group staged_girl_views).
var staged_girls: Array[CutsceneGirlStaging] = []
var is_staged: bool = false

var _points: Dictionary[Ids.Poi, PointOfInterest] = {}


func _ready() -> void:
	_collect_points(self)
	_validate_points()
	if is_staged:
		_spawn_staged_girls()
		return
	GlobalSignals.girls_placed.connect(refresh_girls)
	refresh_girls()


func refresh_girls() -> void:
	for point: PointOfInterest in _points.values():
		point.clear()
	if info == null:
		return
	for placement in GameState.world_info.get_placements_in(info):
		var point: PointOfInterest = _points.get(placement.poi.id)
		if point:
			point.spawn(placement)


func _spawn_staged_girls() -> void:
	for staging in staged_girls:
		var girl := GameState.girls.get_by_id(staging.girl)
		var poi := info.get_poi(staging.poi) if info else null
		var point: PointOfInterest = _points.get(staging.poi)
		if girl == null or poi == null or point == null:
			push_warning("Cutscene staging: unknown girl '%s' or poi '%s'" % [
				Ids.name_of(Ids.Girl, staging.girl), Ids.name_of(Ids.Poi, staging.poi)])
			continue
		var setup := PoiGirlSetup.new()
		setup.girl = girl.id
		setup.pose = staging.pose
		point.spawn(GirlPlacement.new(girl, info, poi, setup))
		if point.girl_view != null:
			point.girl_view.set_staged()


func get_point(poi: Ids.Poi) -> PointOfInterest:
	return _points.get(poi)


func _collect_points(node: Node) -> void:
	for child in node.get_children():
		if child is PointOfInterest:
			_points[child.poi] = child
		else:
			_collect_points(child)


func _validate_points() -> void:
	if info == null:
		push_warning("Location scene '%s' has no LocationInfo assigned" % name)
		return
	var location_name := Ids.name_of(Ids.Location, info.id)
	for poi in info.points_of_interest:
		if not _points.has(poi.id):
			push_warning("Location '%s': PoiInfo '%s' has no PointOfInterest node in the scene" % [
				location_name, Ids.name_of(Ids.Poi, poi.id)])
	for poi_id in _points:
		if info.get_poi(poi_id) == null:
			push_warning("Location '%s': PointOfInterest '%s' has no PoiInfo" % [
				location_name, Ids.name_of(Ids.Poi, poi_id)])
