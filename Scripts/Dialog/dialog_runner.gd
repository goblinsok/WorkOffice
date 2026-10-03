class_name DialogRunner extends RefCounted
## Executes a DialogResource step by step. It has no UI and no signals, so it can be
## driven by DialogManager, by tests, or by other presenters in the future.
##
## Usage: start(), then call next() repeatedly. next() returns a DialogLine, an
## Array[DialogChoice] (answer it with choose()), or null when the dialog ended.

const Op = DialogResource.Op
## Guards against infinite loops made only of jumps/branches/do instructions.
const MAX_STEPS_WITHOUT_OUTPUT := 10000

var dialog: DialogResource
var context: InteractionContext
var _pc: int = -1
var _pending_menu: Dictionary = {}


func start(p_dialog: DialogResource, label: String = "", p_context: InteractionContext = null) -> bool:
	dialog = p_dialog
	context = p_context if p_context else InteractionContext.new()
	_pending_menu = {}
	if not dialog.is_valid():
		for error in dialog.errors:
			push_error(error)
		return false
	if label.is_empty():
		_pc = 0
	elif dialog.has_label(label):
		_pc = dialog.labels[label]
	else:
		push_error("Dialog '%s' has no label '%s'" % [dialog.source_path, label])
		return false
	return true


func is_running() -> bool:
	return _pc >= 0


func is_waiting_for_choice() -> bool:
	return not _pending_menu.is_empty()


## Advances to the next thing to show. Returns a DialogLine, an Array[DialogChoice], or null at the end.
func next() -> Variant:
	if not is_running() or is_waiting_for_choice():
		return null
	for _step in MAX_STEPS_WITHOUT_OUTPUT:
		var instruction: Dictionary = dialog.instructions[_pc]
		match instruction.op:
			Op.LINE:
				_pc += 1
				return _make_line(instruction)
			Op.MENU:
				var choices := _make_choices(instruction)
				if choices.is_empty():
					push_warning("%s:%d: no available choices, skipping menu" % [dialog.source_path, instruction.src])
					_pc += 1
					continue
				_pending_menu = instruction
				return choices
			Op.JUMP:
				_pc = instruction.target
			Op.BRANCH:
				_pc = _pc + 1 if GameExpression.check(instruction.condition, context) else instruction.target
			Op.DO:
				GameExpression.evaluate(instruction.expression, context)
				_pc += 1
			Op.END:
				stop()
				return null
	push_error("Dialog '%s' ran too many steps without output (infinite loop?)" % dialog.source_path)
	stop()
	return null


func choose(index: int) -> void:
	if not is_waiting_for_choice():
		push_warning("DialogRunner.choose() called while no choice is pending")
		return
	var options: Array = _pending_menu.options
	if index < 0 or index >= options.size():
		push_error("Invalid choice index %d" % index)
		return
	_pc = options[index].target
	_pending_menu = {}


func stop() -> void:
	_pc = -1
	_pending_menu = {}


## True if the instruction after the current point is a choice menu (following plain jumps only).
func is_menu_next() -> bool:
	var pc := _pc
	for _step in 32:
		if pc < 0 or pc >= dialog.instructions.size():
			return false
		var instruction: Dictionary = dialog.instructions[pc]
		match instruction.op:
			Op.MENU:
				return true
			Op.JUMP:
				pc = instruction.target
			_:
				return false
	return false


func _make_line(instruction: Dictionary) -> DialogLine:
	var line := DialogLine.new()
	line.text = GameExpression.interpolate(instruction.text, context)
	line.speaker_id = instruction.speaker
	_resolve_speaker(line)
	line.choices_follow = is_menu_next()
	return line


func _resolve_speaker(line: DialogLine) -> void:
	var speaker_id := line.speaker_id
	if speaker_id.is_empty():
		return
	var girl: GirlInfo = null
	if speaker_id == "girl":
		girl = context.girl
	else:
		girl = GameState.girls.get_by_id(StringName(speaker_id.to_lower()))
	if girl:
		line.speaker_name = girl.display_name
		line.speaker_color = girl.name_color
	elif speaker_id == "player":
		line.speaker_name = GameState.player_stats.display_name
	else:
		line.speaker_name = GameExpression.interpolate(speaker_id, context)


func _make_choices(instruction: Dictionary) -> Array[DialogChoice]:
	var choices: Array[DialogChoice] = []
	var options: Array = instruction.options
	for i in options.size():
		var option: Dictionary = options[i]
		if GameExpression.check(option.condition, context):
			choices.append(DialogChoice.new(i, GameExpression.interpolate(option.text, context)))
	return choices
