extends CanvasLayer
## Map panel. Each button is bound to a location id. Buttons are disabled for the
## current location and for locations that are not available (locked or without a scene).

signal closed

@onready var panel: Panel = %Panel
@onready var close_button: Button = %Close

## location id -> button. Add an entry here when a new button is added to the map scene.
@onready var location_buttons: Dictionary[StringName, Button] = {
	&"working_area": %WorkingArea,
	&"kitchen": %Kitchen,
	&"gym": %Gym,
}

var y_starting: float
var y_ending: float
var is_open: bool = false


func _ready() -> void:
	visible = false

	for location_id in location_buttons:
		location_buttons[location_id].pressed.connect(_on_location_pressed.bind(location_id))
	close_button.pressed.connect(close)
	GlobalSignals.location_changed.connect(func(_location): refresh_buttons())
	refresh_buttons()

	y_starting = 0 - panel.global_position.y - panel.size.y
	y_ending = panel.position.y


func refresh_buttons() -> void:
	var current := GameState.world_info.current_location
	for location_id in location_buttons:
		var location := GameState.locations.get_by_id(location_id)
		location_buttons[location_id].disabled = location == null or not location.is_available() or location == current


func show_map() -> void:
	visible = true

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "position:y", y_ending, 0.6).from(y_starting)

	await tween.finished
	is_open = true


func _input(event: InputEvent) -> void:
	if is_open and event is InputEventMouseButton and event.pressed:
		var local_event := panel.make_input_local(event)
		if not Rect2(Vector2.ZERO, panel.get_rect().size).has_point(local_event.position):
			close()


func close() -> void:
	if not is_open:
		return
	is_open = false

	var tween := create_tween()
	tween.tween_property(panel, "position:y", y_starting, 0.2).from(y_ending)

	await tween.finished
	visible = false
	closed.emit()


func _on_location_pressed(location_id: StringName) -> void:
	await close()
	GlobalSignals.switch_location.emit(GameState.locations.get_by_id(location_id))
