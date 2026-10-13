extends CanvasLayer
## View for ActionManager (the Action minigame), hidden outside it. A full-screen STOP blocker
## keeps the world unclickable. On top of it: the girl's Arousal bar (under the top info bar),
## the scene's options in two columns beside her, the bottom bar of available scenes plus the
## end button, and the end confirmation (also opened with Esc).

const OPTION_SIZE := Vector2(120, 44)
const OPTION_SPACING := 54.0
const SCENE_BUTTON_SIZE := Vector2(88, 96)
const AROUSAL_UP_COLOR := Color(1.0, 0.45, 0.75)
const AROUSAL_DOWN_COLOR := Color(0.55, 0.75, 1.0)

## Horizontal distance from the girl's menu anchor to each option column's center.
@export var column_offset: float = 150.0
@export var button_theme: Theme
## Look of the current scene's button in the bottom bar.
@export var current_scene_style: StyleBox

@onready var blocker: Control = %Blocker
@onready var name_label: Label = %NameLabel
@onready var arousal_bar: ProgressBar = %ArousalBar
@onready var value_label: Label = %ValueLabel
@onready var options_root: Control = %Options
@onready var feedback_root: Control = %Feedback
@onready var scenes_row: HBoxContainer = %Scenes
@onready var end_button: Button = %EndButton
@onready var confirm: Control = %Confirm
@onready var confirm_label: Label = %ConfirmLabel
@onready var confirm_yes: Button = %ConfirmYes
@onready var confirm_no: Button = %ConfirmNo

var _floating_text_scene: PackedScene = preload("res://UI/Components/floating_text.tscn")
var _girl: GirlInfo
var _shown_arousal: int = 0
var _bar_tween: Tween


func _ready() -> void:
	_close()
	end_button.pressed.connect(_open_confirm)
	confirm_yes.pressed.connect(_on_confirm_yes)
	confirm_no.pressed.connect(_close_confirm)
	confirm.gui_input.connect(_on_confirm_background_input)
	GlobalSignals.action_started.connect(_on_action_started)
	GlobalSignals.action_scene_changed.connect(func(_scene: ActionSceneData): _refresh())
	GlobalSignals.action_finished.connect(_close)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if confirm.visible:
			_close_confirm()
		else:
			_open_confirm()


func _on_action_started(_scene: ActionSceneData) -> void:
	_girl = ActionManager.context.girl
	_girl.stats_changed.connect(_on_girl_stats_changed)
	name_label.text = _girl.display_name
	arousal_bar.max_value = _girl.max_arousal
	_set_arousal_shown(_girl.arousal)
	confirm.visible = false
	visible = true
	_refresh()


func _close() -> void:
	if _girl and _girl.stats_changed.is_connected(_on_girl_stats_changed):
		_girl.stats_changed.disconnect(_on_girl_stats_changed)
	_girl = null
	visible = false
	confirm.visible = false
	_clear(options_root)
	_clear(scenes_row)
	_clear(feedback_root)


## Rebuilds the options and the scene bar for ActionManager's current scene.
func _refresh() -> void:
	_build_options()
	_build_scene_bar()


# ---------------------------------------------------------------- options

## Options alternate right / left of the girl, each column centered on her menu anchor.
func _build_options() -> void:
	_clear(options_root)
	var view := ActionManager.context.view
	if view == null:
		return
	var anchor := view.get_menu_screen_position()
	var options := ActionManager.get_visible_options()
	var columns: Array[Array] = [[], []]
	for i in options.size():
		columns[i % 2].append(options[i])
	for side in 2:
		var column := columns[side]
		var x := anchor.x + (column_offset if side == 0 else -column_offset)
		for row in column.size():
			var y := anchor.y + (row - (column.size() - 1) * 0.5) * OPTION_SPACING
			_add_option(column[row], _clamp_center(Vector2(x, y)))
	_update_option_states()
	_animate_options()


func _add_option(option: InteractionData, center: Vector2) -> void:
	var button := Button.new()
	button.text = option.label
	button.icon = option.icon
	button.theme = button_theme
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = OPTION_SIZE
	button.size = OPTION_SIZE
	button.position = center - OPTION_SIZE * 0.5
	button.pivot_offset = OPTION_SIZE * 0.5
	button.set_meta(&"option", option)
	button.pressed.connect(_on_option_pressed.bind(option))
	options_root.add_child(button)


func _on_option_pressed(option: InteractionData) -> void:
	_set_options_disabled(true)
	await ActionManager.perform(option)
	if visible:
		_update_option_states()


## Conditions can depend on stats the options just changed.
func _update_option_states() -> void:
	for button: Button in options_root.get_children():
		var option: InteractionData = button.get_meta(&"option")
		button.disabled = not option.is_available(ActionManager.context)


func _set_options_disabled(disabled: bool) -> void:
	for button: Button in options_root.get_children():
		button.disabled = disabled


func _animate_options() -> void:
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for button: Control in options_root.get_children():
		button.scale = Vector2.ZERO
		tween.tween_property(button, "scale", Vector2.ONE, 0.2)


func _clamp_center(center: Vector2) -> Vector2:
	var screen := blocker.get_viewport_rect().size
	var margin := OPTION_SIZE * 0.5 + Vector2(8, 8)
	return center.clamp(margin, screen - margin)


# ---------------------------------------------------------------- scene bar

func _build_scene_bar() -> void:
	_clear(scenes_row)
	for scene in ActionManager.get_available_scenes():
		var button := Button.new()
		button.text = scene.label
		button.icon = scene.icon
		button.tooltip_text = scene.label
		button.theme = button_theme
		button.add_theme_font_size_override(&"font_size", 16)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = SCENE_BUTTON_SIZE
		if scene == ActionManager.current:
			for style_name: StringName in [&"normal", &"hover", &"pressed"]:
				button.add_theme_stylebox_override(style_name, current_scene_style)
		else:
			button.pressed.connect(ActionManager.switch_to.bind(scene))
		scenes_row.add_child(button)


# ---------------------------------------------------------------- arousal

func _on_girl_stats_changed(stat: Ids.Stat, value: int) -> void:
	if stat != Ids.Stat.AROUSAL:
		return
	var delta := value - _shown_arousal
	_set_arousal_shown(value, true)
	if delta != 0:
		_show_feedback("%+d" % delta, AROUSAL_UP_COLOR if delta > 0 else AROUSAL_DOWN_COLOR)


func _set_arousal_shown(value: int, animate: bool = false) -> void:
	_shown_arousal = value
	value_label.text = "%d / %d" % [value, _girl.max_arousal]
	if _bar_tween:
		_bar_tween.kill()
	if animate:
		_bar_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_bar_tween.tween_property(arousal_bar, "value", float(value), 0.35)
	else:
		arousal_bar.value = value


## Floating number under the bar, where the fill now ends.
func _show_feedback(text: String, color: Color) -> void:
	var rect := arousal_bar.get_global_rect()
	var ratio := _shown_arousal / arousal_bar.max_value if arousal_bar.max_value > 0 else 0.0
	var floating: FloatingText = _floating_text_scene.instantiate()
	feedback_root.add_child(floating)
	floating.play(text, color, Vector2(rect.position.x + rect.size.x * ratio, rect.end.y + 40), 16.0)


# ---------------------------------------------------------------- end confirmation

func _open_confirm() -> void:
	if ActionManager.is_busy():
		return
	confirm_label.text = "End the action with %s?" % _girl.display_name
	confirm.visible = true


func _close_confirm() -> void:
	confirm.visible = false


func _on_confirm_yes() -> void:
	confirm.visible = false
	ActionManager.end()


func _on_confirm_background_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		confirm.accept_event()
		_close_confirm()


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
