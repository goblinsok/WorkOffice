extends Node
## View for CutsceneManager. Three layers, all hidden outside a cutscene:
## ImageLayer (1): full-screen background image, under the top bar.
## InputLayer (25): a STOP blocker so the world is not clickable; a click or ui_accept advances.
## SkipLayer (35, above the DialogPanel): top-right Skip button.

@onready var image_layer: CanvasLayer = %ImageLayer
@onready var stage_image: TextureRect = %StageImage
@onready var input_layer: CanvasLayer = %InputLayer
@onready var blocker: Control = %Blocker
@onready var skip_layer: CanvasLayer = %SkipLayer
@onready var skip_button: Button = %SkipButton


func _ready() -> void:
	_set_active(false)
	blocker.gui_input.connect(_on_blocker_gui_input)
	skip_button.pressed.connect(CutsceneManager.skip)
	GlobalSignals.cutscene_started.connect(func(_cutscene: CutsceneData): _set_active(true))
	GlobalSignals.cutscene_finished.connect(func(_cutscene: CutsceneData): _set_active(false))
	GlobalSignals.cutscene_background_requested.connect(_on_background_requested)


func _unhandled_input(event: InputEvent) -> void:
	if input_layer.visible and CutsceneManager.is_waiting_for_click() and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		CutsceneManager.advance()


func _on_blocker_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		blocker.accept_event()
		CutsceneManager.advance()


func _on_background_requested(step: CutsceneBackgroundStep) -> void:
	_show_image(step.image if step else null)


func _show_image(texture: Texture2D) -> void:
	stage_image.texture = texture
	image_layer.visible = texture != null and input_layer.visible


func _set_active(active: bool) -> void:
	input_layer.visible = active
	skip_layer.visible = active
	if not active:
		stage_image.texture = null
	image_layer.visible = active and stage_image.texture != null
