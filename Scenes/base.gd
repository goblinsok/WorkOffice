extends Control
## Root scene. Hosts the current location and switches it on GlobalSignals.switch_location.

@onready var location_center: CenterContainer = %LocationCenter

var current_location: BaseLocation
var _is_switching: bool = false


func _ready() -> void:
	GlobalSignals.switch_location.connect(switch_locations)
	_show_location(GameState.world_info.current_location)


func switch_locations(new_location: LocationInfo) -> void:
	if _is_switching or TimeManager.is_transitioning:
		return
	if new_location == null or not new_location.is_available():
		return
	if current_location and current_location.info == new_location:
		return

	_is_switching = true
	await ScreenFader.fade_out()
	_show_location(new_location)
	await ScreenFader.fade_in()
	_is_switching = false


func _show_location(info: LocationInfo) -> void:
	if current_location:
		location_center.remove_child(current_location)
		current_location.queue_free()

	current_location = info.scene.instantiate()
	current_location.info = info
	location_center.add_child(current_location)

	GameState.world_info.current_location = info
	GlobalSignals.location_changed.emit(info)
