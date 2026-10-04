class_name DialogEffect extends InteractionEffect
## Plays a dialog in the bottom panel and waits for it to finish.

## Path to a .dlg file. "{girl}" is replaced with the girl key (Ids.girl_key, "lidya"), so one
## resource can serve every girl: "res://Dialogs/{girl}/talk.dlg".
@export var dialog_path: String
## Label to start from. Empty means the start of the file.
@export var start_label: String


func execute(context: InteractionContext) -> void:
	var path := dialog_path
	if context.girl:
		path = path.replace("{girl}", Ids.girl_key(context.girl.id))
	await DialogManager.start(path, start_label, context)
