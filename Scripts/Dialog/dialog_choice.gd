class_name DialogChoice extends RefCounted
## One visible option of a choice menu.

## Index to pass back to DialogManager.choose().
var index: int
var text: String


func _init(p_index: int, p_text: String) -> void:
	index = p_index
	text = p_text
