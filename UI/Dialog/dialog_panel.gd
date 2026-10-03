extends CanvasLayer
## View for DialogManager: bottom text panel with speaker name box, typewriter text,
## and a choice menu in the middle of the screen. Clicking anywhere (or ui_accept)
## finishes the typing or advances to the next line.

@export var characters_per_second: float = 45.0
@export var choice_theme: Theme

@onready var root: Control = %Root
@onready var name_box: PanelContainer = %NameBox
@onready var name_label: Label = %NameLabel
@onready var text_label: RichTextLabel = %TextLabel
@onready var continue_indicator: Control = %ContinueIndicator
@onready var choices_box: VBoxContainer = %Choices

var _current_line: DialogLine
var _typing_tween: Tween


func _ready() -> void:
	visible = false
	root.gui_input.connect(_on_root_gui_input)
	DialogManager.dialog_started.connect(_on_dialog_started)
	DialogManager.line_shown.connect(_on_line_shown)
	DialogManager.choices_shown.connect(_on_choices_shown)
	DialogManager.dialog_finished.connect(_on_dialog_finished)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_click()


func _on_root_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		root.accept_event()
		_on_click()


func _on_click() -> void:
	if _has_choices():
		return
	if is_typing():
		_finish_typing()
	else:
		DialogManager.advance()


func is_typing() -> bool:
	return _typing_tween != null and _typing_tween.is_running()


# ---------------------------------------------------------------- DialogManager signals

func _on_dialog_started() -> void:
	_clear_choices()
	text_label.text = ""
	name_box.visible = false
	visible = true


func _on_line_shown(line: DialogLine) -> void:
	_current_line = line
	_clear_choices()
	continue_indicator.visible = false

	name_box.visible = not line.speaker_name.is_empty()
	name_label.text = line.speaker_name
	name_label.modulate = line.speaker_color

	text_label.text = line.text
	text_label.visible_ratio = 0.0
	var duration := text_label.get_total_character_count() / maxf(characters_per_second, 1.0)
	if _typing_tween:
		_typing_tween.kill()
	_typing_tween = create_tween()
	_typing_tween.tween_property(text_label, "visible_ratio", 1.0, duration)
	_typing_tween.finished.connect(_on_typing_finished)


func _on_choices_shown(choices: Array[DialogChoice]) -> void:
	if is_typing():
		_typing_tween.kill()
		text_label.visible_ratio = 1.0
	_clear_choices()
	continue_indicator.visible = false
	for choice in choices:
		var button := Button.new()
		button.text = choice.text
		button.theme = choice_theme
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(320, 44)
		button.pressed.connect(_on_choice_pressed.bind(choice.index))
		choices_box.add_child(button)
	choices_box.visible = true


func _on_dialog_finished() -> void:
	if _typing_tween:
		_typing_tween.kill()
	_clear_choices()
	_current_line = null
	visible = false


# ---------------------------------------------------------------- helpers

func _finish_typing() -> void:
	_typing_tween.kill()
	text_label.visible_ratio = 1.0
	_on_typing_finished()


func _on_typing_finished() -> void:
	if _current_line and _current_line.choices_follow:
		DialogManager.advance()
	else:
		continue_indicator.visible = true


func _on_choice_pressed(index: int) -> void:
	_clear_choices()
	DialogManager.choose(index)


func _has_choices() -> bool:
	return choices_box.get_child_count() > 0


func _clear_choices() -> void:
	for child in choices_box.get_children():
		choices_box.remove_child(child)
		child.queue_free()
	choices_box.visible = false
