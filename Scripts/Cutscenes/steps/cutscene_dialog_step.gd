class_name CutsceneDialogStep extends CutsceneStep
## Plays a .dlg dialog (optionally from a label) and finishes when it ends.

@export_file("*.dlg") var dialog_path: String
@export var label: String


func run(context: InteractionContext) -> void:
	await DialogManager.start(dialog_path, label, context)
