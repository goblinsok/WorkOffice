class_name DialogParser extends RefCounted
## Compiles .dlg text into a DialogResource.
## The full syntax reference is in Dialogs/README.md.
##
## Works in two passes:
##   1. The indentation-aware parser builds a statement tree.
##   2. The emitter flattens the tree into jump-based instructions and resolves labels.

const Op = DialogResource.Op
const END_LABEL := "END"
const TAB_WIDTH := 4

enum Kind { LABEL, LINE, CHOICE, IF, ELIF, ELSE, JUMP, DO }

var _lines: Array[Dictionary] = [] # { indent, text, src }
var _cursor: int = 0
var _result: DialogResource
var _pending_label_refs: Array[Dictionary] = [] # { holder: Dictionary, label: String, src: int }

static var _speaker_regex := RegEx.create_from_string("^([A-Za-z_][\\w ]{0,23}):\\s*(.*)$")
static var _choice_regex := RegEx.create_from_string("^-\\s*(.*?)\\s*(?:\\[if\\s+(.+?)\\])?\\s*(?:=>\\s*(\\S+))?\\s*$")


static func parse_file(path: String) -> DialogResource:
	if not FileAccess.file_exists(path):
		var missing := DialogResource.new()
		missing.source_path = path
		missing.errors.append("File not found: %s" % path)
		return missing
	return DialogParser.new().parse(FileAccess.get_file_as_string(path), path)


func parse(source: String, path: String = "") -> DialogResource:
	_result = DialogResource.new()
	_result.source_path = path
	_tokenize(source)
	var tree := _parse_block(0)
	_emit_block(tree)
	_emit({ "op": Op.END })
	_resolve_labels()
	return _result


# ---------------------------------------------------------------- tokenizing

func _tokenize(source: String) -> void:
	_lines.clear()
	_cursor = 0
	var src := 0
	for raw_line in source.split("\n"):
		src += 1
		var line := raw_line.replace("\r", "")
		var stripped := line.strip_edges()
		if stripped.is_empty() or stripped.begins_with("#"):
			continue
		_lines.append({ "indent": _measure_indent(line), "text": stripped, "src": src })


func _measure_indent(line: String) -> int:
	var width := 0
	for character in line:
		if character == "\t":
			width += TAB_WIDTH
		elif character == " ":
			width += 1
		else:
			break
	return width


# ---------------------------------------------------------------- tree building

## Parses statements at the same indent. Statements that own a block
## (choices, if/elif/else) get their deeper-indented lines as children.
func _parse_block(min_indent: int) -> Array[Dictionary]:
	var nodes: Array[Dictionary] = []
	var block_indent := -1
	while _cursor < _lines.size():
		var line: Dictionary = _lines[_cursor]
		if line.indent < min_indent or (block_indent >= 0 and line.indent < block_indent):
			break
		if block_indent < 0:
			block_indent = line.indent
		if line.indent > block_indent:
			_error(line.src, "Unexpected indentation")
			_cursor += 1
			continue

		_cursor += 1
		var node := _make_node(line)
		if node.is_empty():
			continue
		if _cursor < _lines.size() and _lines[_cursor].indent > block_indent:
			if node.kind in [Kind.CHOICE, Kind.IF, Kind.ELIF, Kind.ELSE]:
				node.children = _parse_block(block_indent + 1)
			else:
				_error(_lines[_cursor].src, "Unexpected indentation (only choices and if/elif/else can have a block)")
				_parse_block(block_indent + 1) # Skip the stray block so it is reported only once.
		nodes.append(node)
	return nodes


func _make_node(line: Dictionary) -> Dictionary:
	var text: String = line.text
	var src: int = line.src
	var node := { "src": src, "indent": line.indent, "children": [] as Array[Dictionary] }

	if text.begins_with("~"):
		node.kind = Kind.LABEL
		node.name = text.substr(1).strip_edges()
		if node.name.is_empty():
			_error(src, "Label without a name")
			return {}
	elif text.begins_with("=>"):
		node.kind = Kind.JUMP
		node.label = text.substr(2).strip_edges()
	elif text.begins_with("-"):
		var found := _choice_regex.search(text)
		node.kind = Kind.CHOICE
		node.text = found.get_string(1) if found else text.substr(1).strip_edges()
		node.condition = found.get_string(2) if found else ""
		node.label = found.get_string(3) if found else ""
	elif _starts_with_keyword(text, "if"):
		node.kind = Kind.IF
		node.condition = _keyword_argument(text, "if")
	elif _starts_with_keyword(text, "elif"):
		node.kind = Kind.ELIF
		node.condition = _keyword_argument(text, "elif")
	elif _starts_with_keyword(text, "else"):
		node.kind = Kind.ELSE
	elif _starts_with_keyword(text, "do"):
		node.kind = Kind.DO
		node.expression = _keyword_argument(text, "do")
	else:
		node.kind = Kind.LINE
		var found := _speaker_regex.search(text)
		node.speaker = found.get_string(1).strip_edges() if found else ""
		node.text = found.get_string(2) if found else text

	if node.kind in [Kind.IF, Kind.ELIF] and node.condition.is_empty():
		_error(src, "Missing condition")
	if node.kind == Kind.JUMP and node.label.is_empty():
		_error(src, "Jump without a label")
	return node


func _starts_with_keyword(text: String, keyword: String) -> bool:
	if not text.begins_with(keyword):
		return false
	if text.length() == keyword.length():
		return true
	var next := text[keyword.length()]
	return next == " " or next == "\t" or next == ":"


func _keyword_argument(text: String, keyword: String) -> String:
	var argument := text.substr(keyword.length()).strip_edges()
	if argument.ends_with(":"):
		argument = argument.left(-1).strip_edges()
	return argument


# ---------------------------------------------------------------- emitting

func _emit(instruction: Dictionary, src: int = 0) -> Dictionary:
	instruction.src = src
	_result.instructions.append(instruction)
	return instruction


func _here() -> int:
	return _result.instructions.size()


func _emit_block(nodes: Array[Dictionary]) -> void:
	var i := 0
	while i < nodes.size():
		var node: Dictionary = nodes[i]
		match node.kind:
			Kind.LABEL:
				if node.indent > 0:
					_error(node.src, "Labels must not be indented")
				if _result.labels.has(node.name):
					_error(node.src, "Duplicate label '%s'" % node.name)
				# Reaching the next label ends the dialog instead of falling through.
				if _here() > 0:
					_emit({ "op": Op.END }, node.src)
				_result.labels[node.name] = _here()
			Kind.LINE:
				_emit({ "op": Op.LINE, "speaker": node.speaker, "text": node.text }, node.src)
			Kind.DO:
				_emit({ "op": Op.DO, "expression": node.expression }, node.src)
			Kind.JUMP:
				_emit_jump(node.label, node.src)
			Kind.CHOICE:
				var group: Array[Dictionary] = []
				while i < nodes.size() and nodes[i].kind == Kind.CHOICE:
					group.append(nodes[i])
					i += 1
				_emit_menu(group)
				continue
			Kind.IF:
				var chain: Array[Dictionary] = [node]
				i += 1
				while i < nodes.size() and nodes[i].kind in [Kind.ELIF, Kind.ELSE]:
					chain.append(nodes[i])
					i += 1
					if chain.back().kind == Kind.ELSE:
						break
				_emit_if(chain)
				continue
			Kind.ELIF, Kind.ELSE:
				_error(node.src, "'elif'/'else' without a matching 'if'")
		i += 1


func _emit_jump(label: String, src: int) -> void:
	if label == END_LABEL:
		_emit({ "op": Op.END }, src)
		return
	var jump := _emit({ "op": Op.JUMP, "target": -1 }, src)
	_pending_label_refs.append({ "holder": jump, "label": label, "src": src })


func _emit_menu(group: Array[Dictionary]) -> void:
	var menu := _emit({ "op": Op.MENU, "options": [] }, group[0].src)
	var jumps_to_end: Array[Dictionary] = []
	var options_to_end: Array[Dictionary] = []

	for choice in group:
		var option := { "text": choice.text, "condition": choice.condition, "target": -1 }
		menu.options.append(option)
		if choice.children.is_empty():
			if choice.label.is_empty():
				options_to_end.append(option)
			elif choice.label == END_LABEL:
				option.target = _here()
				_emit({ "op": Op.END }, choice.src)
			else:
				_pending_label_refs.append({ "holder": option, "label": choice.label, "src": choice.src })
			continue

		option.target = _here()
		_emit_block(choice.children)
		if choice.label.is_empty():
			jumps_to_end.append(_emit({ "op": Op.JUMP, "target": -1 }, choice.src))
		else:
			_emit_jump(choice.label, choice.src)

	var end := _here()
	for jump in jumps_to_end:
		jump.target = end
	for option in options_to_end:
		option.target = end


func _emit_if(chain: Array[Dictionary]) -> void:
	var jumps_to_end: Array[Dictionary] = []
	for branch in chain:
		if branch.kind == Kind.ELSE:
			_emit_block(branch.children)
			continue
		var check := _emit({ "op": Op.BRANCH, "condition": branch.condition, "target": -1 }, branch.src)
		_emit_block(branch.children)
		jumps_to_end.append(_emit({ "op": Op.JUMP, "target": -1 }, branch.src))
		check.target = _here()

	var end := _here()
	for jump in jumps_to_end:
		jump.target = end


func _resolve_labels() -> void:
	for ref in _pending_label_refs:
		if _result.labels.has(ref.label):
			ref.holder.target = _result.labels[ref.label]
		else:
			_error(ref.src, "Unknown label '%s'" % ref.label)
	_pending_label_refs.clear()


func _error(src: int, message: String) -> void:
	_result.errors.append("%s:%d: %s" % [_result.source_path, src, message])
