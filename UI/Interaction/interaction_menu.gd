extends CanvasLayer
## Radial menu of interactions that appears around a clicked girl.
## Clicking outside the buttons, right-clicking or pressing Esc closes it.

@export var radius: float = 120.0
@export var button_size: Vector2 = Vector2(110, 40)
## Angle (degrees) of the first option. -90 is straight up.
@export var start_angle: float = -90.0
@export var button_theme: Theme

@onready var blocker: Control = %Blocker
@onready var options_root: Control = %Options

var _context: InteractionContext


func _ready() -> void:
	close()
	blocker.gui_input.connect(_on_blocker_gui_input)
	GlobalSignals.girl_clicked.connect(open_for)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func open_for(view: BaseGirlLocation) -> void:
	if not InteractionManager.can_interact():
		return
	_context = InteractionContext.new(view)
	var interactions := InteractionManager.get_visible_interactions(_context)
	if interactions.is_empty():
		return

	_clear_options()
	options_root.position = _clamp_center(view.get_menu_screen_position())
	for i in interactions.size():
		var angle := deg_to_rad(start_angle + 360.0 * i / interactions.size())
		_add_option(interactions[i], Vector2.from_angle(angle) * radius)
	visible = true
	_animate_open()


func close() -> void:
	visible = false
	_context = null
	_clear_options()


func _add_option(interaction: InteractionData, offset: Vector2) -> void:
	var button := Button.new()
	button.text = interaction.label
	button.icon = interaction.icon
	button.theme = button_theme
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = button_size
	button.size = button_size
	button.position = offset - button_size * 0.5
	button.pivot_offset = button_size * 0.5
	button.disabled = not interaction.is_available(_context)
	button.pressed.connect(_on_option_pressed.bind(interaction))
	options_root.add_child(button)


func _on_option_pressed(interaction: InteractionData) -> void:
	var context := _context
	close()
	InteractionManager.run(interaction, context)


func _on_blocker_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		blocker.accept_event()
		close()


func _animate_open() -> void:
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for button: Control in options_root.get_children():
		var target := button.position
		button.position = -button_size * 0.5
		button.scale = Vector2.ZERO
		tween.tween_property(button, "position", target, 0.2)
		tween.tween_property(button, "scale", Vector2.ONE, 0.2)


## Keeps the whole menu inside the screen.
func _clamp_center(center: Vector2) -> Vector2:
	var screen := blocker.get_viewport_rect().size
	var margin := Vector2(radius, radius) + button_size * 0.5
	return center.clamp(margin, screen - margin)


func _clear_options() -> void:
	for child in options_root.get_children():
		options_root.remove_child(child)
		child.queue_free()
