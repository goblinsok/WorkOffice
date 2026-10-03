class_name BaseLocation extends Node2D
## Base for every location scene. Finds its PointOfInterest nodes and spawns
## the girls that WorldInfo placed here. Set `info` before adding it to the tree.

var info: LocationInfo

var _points: Dictionary[StringName, PointOfInterest] = {}


func _ready() -> void:
	_collect_points(self)
	_validate_points()
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


func get_point(poi_id: StringName) -> PointOfInterest:
	return _points.get(poi_id)


func _collect_points(node: Node) -> void:
	for child in node.get_children():
		if child is PointOfInterest:
			_points[child.poi_id] = child
		else:
			_collect_points(child)


func _validate_points() -> void:
	if info == null:
		push_warning("Location scene '%s' has no LocationInfo assigned" % name)
		return
	for poi in info.points_of_interest:
		if not _points.has(poi.id):
			push_warning("Location '%s': PoiInfo '%s' has no PointOfInterest node in the scene" % [info.id, poi.id])
	for poi_id in _points:
		if info.get_poi(poi_id) == null:
			push_warning("Location '%s': PointOfInterest '%s' has no PoiInfo" % [info.id, poi_id])
