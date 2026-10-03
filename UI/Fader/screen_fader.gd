extends CanvasLayer
## ScreenFader (autoload): full-screen fade used by every transition.
## While it is visible, it blocks all mouse input to the game.

@export var default_duration: float = 0.5

@onready var overlay: ColorRect = %Overlay

var _tween: Tween


func _ready() -> void:
	overlay.modulate.a = 0.0
	overlay.visible = false


func is_faded() -> bool:
	return overlay.visible and overlay.modulate.a > 0.0


func fade_out(duration: float = default_duration) -> void:
	overlay.visible = true
	await _fade_to(1.0, duration)


func fade_in(duration: float = default_duration) -> void:
	await _fade_to(0.0, duration)
	overlay.visible = false


func _fade_to(alpha: float, duration: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(overlay, "modulate:a", alpha, duration)
	await _tween.finished
