class_name BaseMenu extends Control
## Base for every popup menu: dimmed background, framed window with a title and a
## close button, open/close animation, Esc and click-outside to close.
## Inherited scenes put their UI under %Content and override _on_open() to refresh.
## A menu with its own look (the map) can extend BaseMenu from a scene that doesn't inherit
## base_menu.tscn: the window/title/close/content nodes are then optional, and it can
## override _animate_open().

signal opened()
signal closed()

@export var title: String = "Menu":
	set(value):
		title = value
		if is_node_ready() and title_label:
			title_label.text = value
@export var close_on_click_outside: bool = true

@onready var window: PanelContainer = get_node_or_null(^"%Window")
@onready var title_label: Label = get_node_or_null(^"%Title")
@onready var close_button: Button = get_node_or_null(^"%CloseButton")
@onready var content: Control = get_node_or_null(^"%Content")

var _tween: Tween


func _ready() -> void:
	visible = false
	if title_label:
		title_label.text = title
	if close_button:
		close_button.pressed.connect(close)
	gui_input.connect(_on_background_input)


func is_open() -> bool:
	return visible


func open() -> void:
	if visible:
		return
	_on_open()
	visible = true
	_animate_open()
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


## Override for a custom open animation. Default: fade in.
func _animate_open() -> void:
	if _tween:
		_tween.kill()
	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.15)


## Override: clean up (disconnect live updates, ...) when the menu closes.
func _on_close() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _on_background_input(event: InputEvent) -> void:
	# Only real clicks: the mouse wheel also sends pressed InputEventMouseButtons.
	if close_on_click_outside and event is InputEventMouseButton and event.pressed \
			and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		accept_event()
		close()
