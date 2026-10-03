@tool
class_name PointOfInterest extends Marker2D
## Marks where a girl stands in a location scene. poi_id must match a PoiInfo.id
## in the location's LocationInfo resource. Spawned girls become children of this node,
## so the marker's position and scale control how the girl appears.

@export var poi_id: StringName:
	set(value):
		poi_id = value
		update_configuration_warnings()

var girl_view: BaseGirlLocation


func _get_configuration_warnings() -> PackedStringArray:
	if poi_id.is_empty():
		return ["poi_id is empty. It must match a PoiInfo.id in the location's LocationInfo."]
	return []


func clear() -> void:
	if is_instance_valid(girl_view):
		girl_view.queue_free()
	girl_view = null


func spawn(placement: GirlPlacement) -> void:
	clear()
	var scene := placement.setup.get_scene(placement.girl)
	if scene == null:
		push_error("No scene for girl '%s' at POI '%s'" % [placement.girl.id, poi_id])
		return
	girl_view = scene.instantiate()
	add_child(girl_view)
	girl_view.setup(placement)
