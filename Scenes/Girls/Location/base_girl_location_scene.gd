class_name BaseGirlLocation extends Node2D

@onready var sprite: Sprite2D = %Sprite
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var select: Area2D = %Select
@onready var selector_test: Polygon2D = %Selector_Test

func hover(is_hovered: bool) -> void:
	print("Kgd")
	if is_hovered:
		selector_test.color.a = 0.3
	else:
		selector_test.color.a = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Kgd!!!")
	select.mouse_entered.connect(hover.bind(true))
	select.mouse_exited.connect(hover.bind(false))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
