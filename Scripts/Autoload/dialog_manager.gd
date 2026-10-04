extends Node
## DialogManager: loads and caches dialogs, drives a DialogRunner, and tells the UI
## what to show through signals. The UI answers with advance() / choose().
## It also spawns floating speech bubbles.

signal dialog_started()
signal line_shown(line: DialogLine)
signal choices_shown(choices: Array[DialogChoice])
signal dialog_finished()

const SPEECH_BUBBLE := preload("res://UI/Dialog/speech_bubble.tscn")

var _cache: Dictionary = {} # path -> DialogResource
var _runner: DialogRunner = DialogRunner.new()


func is_active() -> bool:
	return _runner.is_running()


func get_dialog(path: String) -> DialogResource:
	if not _cache.has(path):
		_cache[path] = DialogParser.parse_file(path)
	return _cache[path]


## Plays a dialog and returns (when awaited) after it ends.
func start(path: String, label: String = "", context: InteractionContext = null) -> void:
	if is_active():
		push_warning("A dialog is already running, ignoring '%s'" % path)
		return
	if not _runner.start(get_dialog(path), label, context):
		return
	dialog_started.emit()
	advance()
	if is_active():
		await dialog_finished


## Ends the running dialog immediately (used when a cutscene is skipped).
func stop() -> void:
	if not is_active():
		return
	_runner.stop()
	dialog_finished.emit()


## Moves to the next line. Called by the UI when the player clicks.
func advance() -> void:
	if not is_active() or _runner.is_waiting_for_choice():
		return
	_show(_runner.next())


func choose(index: int) -> void:
	_runner.choose(index)
	advance()


## Shows a non-skippable bubble above anchor that removes itself after duration seconds.
func show_bubble(anchor: Node2D, text: String, duration: float = 2.5) -> void:
	if not is_instance_valid(anchor):
		return
	var bubble: SpeechBubble = SPEECH_BUBBLE.instantiate()
	anchor.add_child(bubble)
	bubble.show_text(text, duration)


func _show(step: Variant) -> void:
	if step is DialogLine:
		line_shown.emit(step)
	elif step is Array:
		choices_shown.emit(step)
	else:
		dialog_finished.emit()
