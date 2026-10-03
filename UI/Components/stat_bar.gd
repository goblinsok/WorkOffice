class_name StatBar extends VBoxContainer
## Label + progress bar + "value / max" text. Reused by menus and the battle window.

@export var label_text: String = "Stat":
	set(value):
		label_text = value
		if is_node_ready():
			name_label.text = value
@export var fill_color: Color = Color(0.4, 0.7, 0.4):
	set(value):
		fill_color = value
		if is_node_ready():
			_apply_fill_color()
@export var show_value: bool = true

@onready var name_label: Label = %NameLabel
@onready var value_label: Label = %ValueLabel
@onready var bar: ProgressBar = %Bar

var _tween: Tween


func _ready() -> void:
	name_label.text = label_text
	value_label.visible = show_value
	_apply_fill_color()


func set_values(value: int, max_value: int) -> void:
	if _tween:
		_tween.kill()
	bar.max_value = maxi(max_value, 1)
	bar.value = value
	value_label.text = "%d / %d" % [value, max_value]


## Same as set_values(), but slides the bar.
func animate_to(value: int, max_value: int, duration: float = 0.25) -> void:
	if _tween:
		_tween.kill()
	bar.max_value = maxi(max_value, 1)
	value_label.text = "%d / %d" % [value, max_value]
	_tween = create_tween()
	_tween.tween_property(bar, "value", float(value), duration)


func _apply_fill_color() -> void:
	var fill := bar.get_theme_stylebox("fill")
	if fill is StyleBoxFlat:
		var style := fill.duplicate() as StyleBoxFlat
		style.bg_color = fill_color
		bar.add_theme_stylebox_override("fill", style)
