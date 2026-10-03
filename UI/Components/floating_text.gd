class_name FloatingText extends Label
## Short-lived text that rises and fades (damage numbers, status words).
## Instantiate UI/Components/floating_text.tscn, add it to a Control, then call play().


func play(p_text: String, color: Color, center: Vector2, rise: float = 50.0, duration: float = 0.9) -> void:
	text = p_text
	add_theme_color_override("font_color", color)
	reset_size()
	position = center - size * 0.5
	pivot_offset = size * 0.5
	scale = Vector2(0.6, 0.6)

	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y - rise, duration).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, duration * 0.5).set_delay(duration * 0.5)
	tween.chain().tween_callback(queue_free)
