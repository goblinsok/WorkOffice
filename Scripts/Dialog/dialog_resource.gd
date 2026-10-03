class_name DialogResource extends Resource
## A compiled dialog: a flat list of instructions plus label entry points.
## Produced by DialogParser from a .dlg file and executed by DialogRunner.
##
## Instruction layouts (Dictionaries):
##   LINE   { op, speaker: String, text: String }
##   MENU   { op, options: [{ text: String, condition: String, target: int }] }
##   JUMP   { op, target: int }
##   BRANCH { op, condition: String, target: int }  -> jumps to target when condition is FALSE
##   DO     { op, expression: String }
##   END    { op }
## Every instruction also has "src": the source line number, for error messages.

enum Op { LINE, MENU, JUMP, BRANCH, DO, END }

@export var source_path: String
@export var instructions: Array[Dictionary] = []
## label name -> instruction index
@export var labels: Dictionary = {}
## Compile errors. The dialog should not be run if this is not empty.
@export var errors: PackedStringArray = []


func has_label(label: String) -> bool:
	return labels.has(label)


func is_valid() -> bool:
	return errors.is_empty()
