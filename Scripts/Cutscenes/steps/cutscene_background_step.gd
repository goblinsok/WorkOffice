@tool
class_name CutsceneBackgroundStep extends CutsceneStep
## Changes what is behind the dialog: a full-screen image, or a location staged with
## specific girls (the real world location and placements are not touched).
## @tool only so each staging's poi dropdown is narrowed to this location's points.

## If set, it covers the whole screen (below the top bar).
@export var image: Texture2D
## Location shown in the world view. Ignored when null (keeps the current view).
@export var location: LocationInfo:
	set(value):
		location = value
		_link_stagings()
@export var girls: Array[CutsceneGirlStaging] = []:
	set(value):
		girls = value
		_link_stagings()
## Fade out and in around the change.
@export var fade: bool = true


func run(_context: InteractionContext) -> void:
	await CutsceneManager.show_background(self)


func _link_stagings() -> void:
	for staging in girls:
		if staging != null:
			staging.location = location
