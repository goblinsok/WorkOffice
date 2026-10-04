extends BaseMenu
## Map panel that slides down from the top. It is a menu like the others (GameUi.menu_buttons):
## the Map button toggles it, only one menu is open at a time, and Esc or a click outside closes it.
## Each button is bound to a location. Buttons are disabled for the current location and for
## locations that are not available (locked or without a scene).

const SLIDE_TIME := 0.6

@onready var center: CenterContainer = %Center

## location -> button. Add an entry here when a new button is added to the map scene.
@onready var location_buttons: Dictionary[Ids.Location, Button] = {
	Ids.Location.WORKING_AREA: %WorkingArea,
	Ids.Location.KITCHEN: %Kitchen,
	Ids.Location.GYM: %Gym,
}

var _rest_top: float
var _rest_bottom: float
var _slide: Tween


func _ready() -> void:
	super._ready()
	_rest_top = center.offset_top
	_rest_bottom = center.offset_bottom
	for location_id in location_buttons:
		location_buttons[location_id].pressed.connect(_on_location_pressed.bind(location_id))
	GlobalSignals.location_changed.connect(func(_location): refresh_buttons())


func refresh_buttons() -> void:
	var current := GameState.world_info.current_location
	for location_id in location_buttons:
		var location := GameState.locations.get_by_id(location_id)
		location_buttons[location_id].disabled = location == null or not location.is_available() or location == current


func _on_open() -> void:
	refresh_buttons()


func _animate_open() -> void:
	var distance := get_viewport_rect().size.y
	if _slide:
		_slide.kill()
	_slide = create_tween().set_parallel().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_slide.tween_property(center, "offset_top", _rest_top, SLIDE_TIME).from(_rest_top - distance)
	_slide.tween_property(center, "offset_bottom", _rest_bottom, SLIDE_TIME).from(_rest_bottom - distance)


func _on_close() -> void:
	if _slide:
		_slide.kill()
	center.offset_top = _rest_top
	center.offset_bottom = _rest_bottom


func _on_location_pressed(location_id: Ids.Location) -> void:
	close()
	GlobalSignals.switch_location.emit(GameState.locations.get_by_id(location_id))
