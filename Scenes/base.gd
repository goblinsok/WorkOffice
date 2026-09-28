extends Control

@onready var location_center: CenterContainer = %LocationCenter
@onready var location_black_fade: ColorRect = %LocationBlackFade
var current_location : BaseLocation

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	default_setup()
	
	#GlobalSignals.switch_location.connect(switch_locations)
	GlobalSignals.switch_location.connect(switch_locations)
	
func default_setup() -> void:
	var WORKING_AREA = preload("uid://gv44ik0vj3db").instantiate()
	
	location_center.add_child(WORKING_AREA)
	current_location = WORKING_AREA
	
#func switch_locations(new_location: PackedScene) -> void:
func switch_locations(new_location: LocationInfo) -> void:
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(location_black_fade,"modulate:a",1, 0.5)
	await fade_tween.finished
	fade_tween.kill()
	
	var location = new_location.scene.instantiate()
	
	location_center.add_child(location)
	
	current_location.queue_free()
	await current_location.tree_exited
	current_location = location
	
	fade_tween = get_tree().create_tween()
	fade_tween.tween_property(location_black_fade,"modulate:a",0, 0.5)
	await fade_tween.finished
	fade_tween.kill()
