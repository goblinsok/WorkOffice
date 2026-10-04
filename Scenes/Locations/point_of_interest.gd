@tool
class_name PointOfInterest extends Marker2D
## Marks where a girl stands in a location scene. poi must match a PoiInfo.id
## in the location's LocationInfo resource. Spawned girls become children of this node,
## so the marker's position and scale control how the girl appears.

@export var poi: Ids.Poi = Ids.Poi.NONE:
	set(value):
		poi = value
		update_configuration_warnings()

var girl_view: BaseGirlLocation


func _get_configuration_warnings() -> PackedStringArray:
	if poi == Ids.Poi.NONE:
		return ["poi is NONE. It must match a PoiInfo.id in the location's LocationInfo."]
	return []


func clear() -> void:
	if is_instance_valid(girl_view):
		girl_view.queue_free()
	girl_view = null


func spawn(placement: GirlPlacement) -> void:
	clear()
	var scene := placement.setup.get_scene(placement.girl)
	if scene == null:
		push_error("No scene for girl '%s' at POI '%s'" % [Ids.name_of(Ids.Girl, placement.girl.id), Ids.name_of(Ids.Poi, poi)])
		return
	girl_view = scene.instantiate()
	add_child(girl_view)
	girl_view.setup(placement)
