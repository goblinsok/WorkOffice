class_name BubbleEffect extends InteractionEffect
## Shows a short, non-skippable bubble above the girl. One random line is picked.
## Lines support {expression} interpolation, e.g. "{name} is busy typing."

@export var lines: Array[String] = []
@export var duration: float = 2.5
## If true, the interaction waits until the bubble disappears.
@export var wait: bool = false


func execute(context: InteractionContext) -> void:
	if lines.is_empty():
		return
	context.bubble(lines.pick_random(), duration)
	if wait:
		await DialogManager.get_tree().create_timer(duration).timeout
