extends CanvasLayer
signal closed

@onready var panel: Panel = %Panel
@onready var working_area: Button = %WorkingArea
@onready var kitchen: Button = %Kitchen
@onready var gym: Button = %Gym
var locked_button : Button

var y_starting : float
var y_ending : float

var is_open: bool = false


var location_dict: Dictionary[LocationInfo, Button] = {}

func _ready() -> void:
	visible = false
	
	location_dict[GameState.world_info.working_area_location] = working_area
	location_dict[GameState.world_info.gym_location] = gym
	
	set_up_scene()
	
	y_starting = 0 - panel.global_position.y - panel.size.y
	y_ending = panel.position.y
		
func set_up_scene() -> void:
	GlobalSignals.switch_location.connect(transition)
	for key in location_dict.keys():
		location_dict[key].pressed.connect(func (): GlobalSignals.switch_location.emit(key))

func show_map() -> void:
	visible = true
	
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "position:y", y_ending, 0.6).from(y_starting)
	
	await tween.finished
	tween.kill()
	is_open = true
	
func _input(event):
	if is_open and (event is InputEventMouseButton) and event.pressed:
		var evLocal = panel.make_input_local(event)
		if !Rect2(Vector2(0,0),panel.get_rect().size).has_point(evLocal.position):
			close()
	
func close() -> void:
	is_open = false
	
	var tween = get_tree().create_tween()
	tween.tween_property(panel, "position:y", y_starting, 0.2).from(y_ending)
	
	await tween.finished
	visible = false
	
	tween.kill()
	closed.emit()
	
func transition(location: LocationInfo) -> void:
	await close()
	
	if locked_button != null:
		locked_button.disabled = false
		
	var current_button = location_dict[location]
	current_button.disabled = true
	locked_button = current_button








	
#func transition(map_button: Button, location: LocationInfo) -> void:
	#if locked_button != null:
		#locked_button.disabled = false
		#
	#map_button.disabled = true
	#locked_button = map_button
	#
	#await close()
	#GlobalSignals.switch_location.emit(location.scene)

	
#func init_locations() -> void:
	#var location = preload("res://Resources/Locations/gym_area_info.tres")
	#location.map_button = gym
	#locations.append(location)
	#
	#location = preload("res://Resources/Locations/kitchen_area_info.tres")
	#location.map_button = kitchen
	#locations.append(location)
	#
	#location = preload("res://Resources/Locations/working_area_info.tres")
	#location.map_button = working_area
	#locations.append(location)
