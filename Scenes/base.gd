extends Control
## Root scene. Hosts the current location and switches it on GlobalSignals.switch_location.

@onready var location_center: CenterContainer = %LocationCenter

var current_location: BaseLocation
var _is_switching: bool = false


func _ready() -> void:
	GlobalSignals.switch_location.connect(switch_locations)
	GlobalSignals.cutscene_background_requested.connect(_on_cutscene_background_requested)
	GlobalSignals.action_stage_requested.connect(_on_action_stage_requested)
	_show_location(GameState.world_info.current_location)


func switch_locations(new_location: LocationInfo) -> void:
	if _is_switching or TimeManager.is_transitioning or CutsceneManager.is_playing() or ActionManager.is_playing():
		return
	if new_location == null or not new_location.is_available():
		return
	if current_location and current_location.info == new_location:
		return

	_is_switching = true
	await ScreenFader.fade_out()
	_show_location(new_location)
	await ScreenFader.fade_in()
	_is_switching = false


## step == null restores the real location. A step with a location stages it without touching
## the world state; an image-only step leaves the world view alone (the overlay shows it).
func _on_cutscene_background_requested(step: CutsceneBackgroundStep) -> void:
	if step == null:
		_show_location(GameState.world_info.current_location)
	elif step.location != null and step.location.is_available():
		_show_location(step.location, step.girls, true)
	elif step.location != null:
		push_warning("Cutscene location '%s' is not available" % Ids.name_of(Ids.Location, step.location.id))


## staging == null restores the real location; otherwise its location is staged with only that girl.
func _on_action_stage_requested(staging: CutsceneGirlStaging) -> void:
	if staging == null:
		_show_location(GameState.world_info.current_location)
	else:
		_show_location(staging.location, [staging] as Array[CutsceneGirlStaging], true)


## Staged locations (cutscenes, action scenes) leave world_info and location_changed alone.
func _show_location(info: LocationInfo, staged_girls: Array[CutsceneGirlStaging] = [], is_staged: bool = false) -> void:
	if current_location:
		location_center.remove_child(current_location)
		current_location.queue_free()

	current_location = info.scene.instantiate()
	current_location.info = info
	current_location.staged_girls = staged_girls
	current_location.is_staged = is_staged
	location_center.add_child(current_location)

	if not is_staged:
		GameState.world_info.current_location = info
		GlobalSignals.location_changed.emit(info)
