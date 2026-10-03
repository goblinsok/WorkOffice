class_name SpeechBubble extends PanelContainer
## Small floating text above a world anchor. Non-interactive. Frees itself after its duration.
## Spawn it through DialogManager.show_bubble().

const FADE_TIME := 0.2

@onready var label: Label = %Label


func show_text(text: String, duration: float) -> void:
	label.text = text
	modulate.a = 0.0
	# Keep a constant on-screen size no matter how the anchor is scaled.
	var parent_scale := (get_parent() as Node2D).global_scale
	scale = Vector2.ONE / parent_scale
	reset_size()
	await get_tree().process_frame
	# Bottom-center of the bubble sits on the anchor.
	position = -Vector2(size.x * 0.5, size.y) * scale

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_TIME)
	tween.tween_interval(duration)
	tween.tween_property(self, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(queue_free)
