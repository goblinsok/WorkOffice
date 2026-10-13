class_name BaseGirlLocation extends Node2D
## A girl's clickable presence in a location. Scenes inherit it in two steps:
## Scenes/Girls/Poses/base_<pose>.tscn sets the frame layout and autoplays the pose's looping
## animation, and Scenes/Girls/<Girl>/<girl>_<pose>.tscn only sets her sprite sheet for that pose.

const HOVER_MODULATE := Color(1.2, 1.2, 1.2)

@onready var sprite: Sprite2D = %Sprite
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var select: Area2D = %Select
## Speech bubbles attach here.
@onready var bubble_anchor: Marker2D = %BubbleAnchor
## The interaction menu is centered here.
@onready var menu_anchor: Marker2D = %MenuAnchor

var placement: GirlPlacement


func _ready() -> void:
	add_to_group(&"girl_views")
	select.mouse_entered.connect(_set_hovered.bind(true))
	select.mouse_exited.connect(_set_hovered.bind(false))
	select.input_event.connect(_on_select_input_event)


func setup(p_placement: GirlPlacement) -> void:
	placement = p_placement


func get_girl() -> GirlInfo:
	return placement.girl if placement else null


## Staged views (cutscenes, action scenes) are not clickable and are not world views.
func set_staged() -> void:
	select.input_pickable = false
	remove_from_group(&"girl_views")
	add_to_group(&"staged_girl_views")


## Screen-space position of the menu anchor (for UI placed on a CanvasLayer).
func get_menu_screen_position() -> Vector2:
	return menu_anchor.get_global_transform_with_canvas().origin


func _set_hovered(is_hovered: bool) -> void:
	sprite.modulate = HOVER_MODULATE if is_hovered else Color.WHITE


func _on_select_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_set_hovered(false)
		GlobalSignals.girl_clicked.emit(self)
