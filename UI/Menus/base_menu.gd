class_name BaseMenu extends Control
## Base for every popup menu: dimmed background, framed window with a title and a
## close button, open/close animation, Esc and click-outside to close.
## Inherited scenes put their UI under %Content and override _on_open() to refresh.

signal opened()
signal closed()

@export var title: String = "Menu":
	set(value):
		title = value
		if is_node_ready():
			title_label.text = value
@export var close_on_click_outside: bool = true

@onready var window: PanelContainer = %Window
@onready var title_label: Label = %Title
@onready var close_button: Button = %CloseButton
@onready var content: Control = %Content

var _tween: Tween


func _ready() -> void:
	visible = false
	title_label.text = title
	close_button.pressed.connect(close)
	gui_input.connect(_on_background_input)


func is_open() -> bool:
	return visible


func open() -> void:
	if visible:
		return
	_on_open()
	visible = true
	if _tween:
		_tween.kill()
	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.15)
	opened.emit()


func close() -> void:
	if not visible:
		return
	_on_close()
	if _tween:
		_tween.kill()
	visible = false
	closed.emit()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


## Override: refresh the content right before the menu becomes visible.
func _on_open() -> void:
	pass


## Override: clean up (disconnect live updates, ...) when the menu closes.
func _on_close() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _on_background_input(event: InputEvent) -> void:
	if close_on_click_outside and event is InputEventMouseButton and event.pressed:
		accept_event()
		close()
