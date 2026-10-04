class_name BaseGirlLocation extends Node2D
## A girl's clickable presence in a location. The scene that inherits it provides the
## sprite sheet and animations. The PoiGirlSetup chooses which animation plays.

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
	var animation := placement.setup.animation
	if animation_player.has_animation(animation):
		animation_player.play(animation)
	elif not animation.is_empty():
		push_warning("'%s' has no animation '%s'" % [scene_file_path, animation])


func get_girl() -> GirlInfo:
	return placement.girl if placement else null


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
