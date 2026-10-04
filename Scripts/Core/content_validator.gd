class_name ContentValidator extends RefCounted
## Cross-checks content that enums alone can't protect: a .tres still holding the number of a
## removed Ids value, a POI used in the wrong location, a scene marker without data, a missing
## dialog file, a misspelled .dlg speaker or stat name, duplicate content ids, a girl using
## another girl's interaction file, a condition pointing at an unknown girl or stat.
## Every problem is one readable line. GameState runs validate() at startup in debug builds,
## and the smoke test asserts that it returns nothing.

const DIALOGS_DIR := "res://Dialogs"
const CUTSCENES_DIR := "res://Resources/Cutscenes"
const INTERACTIONS_DIR := "res://Resources/Interactions"
const ITEMS_DIR := "res://Resources/Items"
const JOBS_DIR := "res://Resources/Jobs"
## A speaker this close to a girl key (but not equal) is reported as a likely typo.
const MAX_SPEAKER_TYPO_DISTANCE := 2

static var _stat_call_regex := RegEx.create_from_string("\\b(?:add_stat|stat)\\(\\s*\"([^\"]*)\"")


static func validate(girls: GirlsRepo, locations: LocationsRepo, cutscenes: CutscenesRepo) -> PackedStringArray:
	var problems: PackedStringArray = []
	problems.append_array(_check_girls(girls))
	problems.append_array(_check_locations(locations, girls))
	problems.append_array(_check_cutscenes(_collect_cutscenes(cutscenes), cutscenes, girls))
	var interactions := _load_all(INTERACTIONS_DIR, "InteractionData")
	problems.append_array(_check_unique_ids("Interaction", interactions))
	for interaction: InteractionData in interactions:
		problems.append_array(_check_conditions(interaction.conditions, girls, "Interaction '%s'" % interaction.id))
	var items := _load_all(ITEMS_DIR, "ItemData")
	problems.append_array(_check_unique_ids("Item", items))
	for item: ItemData in items:
		var usable := item.get_usable()
		if usable != null:
			problems.append_array(_check_conditions(usable.conditions, girls, "Item '%s'" % item.id))
	problems.append_array(_check_unique_ids("Job", _load_all(JOBS_DIR, "JobData")))
	for path in _find_files(DIALOGS_DIR, "dlg"):
		problems.append_array(validate_dialog(DialogParser.parse_file(path)))
	return problems


## Compile errors, speakers that look like a misspelled girl key, and unknown stat names
## in add_stat("...") / stat("...").
static func validate_dialog(dialog: DialogResource) -> PackedStringArray:
	var problems: PackedStringArray = dialog.errors.duplicate()
	for instruction in dialog.instructions:
		var where := "%s:%d" % [dialog.source_path, instruction.get("src", 0)]
		if instruction.op == DialogResource.Op.LINE:
			var typo_of := _speaker_typo_of(instruction.speaker)
			if not typo_of.is_empty():
				problems.append("%s: speaker '%s' looks like a typo of '%s'" % [where, instruction.speaker, typo_of])
		for text in _instruction_texts(instruction):
			for found in _stat_call_regex.search_all(text):
				var stat_name := found.get_string(1)
				if Ids.stat_from_name(stat_name) == Ids.Stat.NONE:
					problems.append("%s: unknown stat '%s' (see Ids.Stat)" % [where, stat_name])
	return problems


# ---------------------------------------------------------------- girls

static func _check_girls(girls: GirlsRepo) -> PackedStringArray:
	var problems: PackedStringArray = []
	var seen: Dictionary[int, GirlInfo] = {}
	for girl in girls.girls:
		if girl == null:
			problems.append("girls_repo.tres has an empty entry")
		elif not Ids.Girl.values().has(girl.id) or girl.id == Ids.Girl.NONE:
			problems.append("GirlInfo '%s' has id %s, which is not a valid Ids.Girl" % [girl.resource_path, Ids.name_of(Ids.Girl, girl.id)])
		elif seen.has(girl.id):
			problems.append("Girl %s is defined twice (%s, %s)" % [Ids.name_of(Ids.Girl, girl.id), seen[girl.id].resource_path, girl.resource_path])
		else:
			seen[girl.id] = girl
			for interaction in girl.interactions:
				problems.append_array(_check_interaction(interaction, girl.id, "Girl %s" % Ids.name_of(Ids.Girl, girl.id)))
	for value: int in Ids.Girl.values():
		if value != Ids.Girl.NONE and not seen.has(value):
			problems.append("Ids.Girl.%s has no GirlInfo in girls_repo.tres" % Ids.name_of(Ids.Girl, value))
	return problems


static func _is_registered_girl(girls: GirlsRepo, girl: Ids.Girl) -> bool:
	return girl != Ids.Girl.NONE and girls.get_by_id(girl) != null


## An interaction offered by a girl: not empty, its dialogs exist, and its file isn't in
## another girl's folder (Resources/Interactions/<girl key>/), which is usually a copy-paste slip.
static func _check_interaction(interaction: InteractionData, girl: Ids.Girl, context: String) -> PackedStringArray:
	if interaction == null:
		return ["%s: empty interaction entry" % context]
	var problems: PackedStringArray = []
	var where := "%s, interaction '%s'" % [context, interaction.id]
	for value: int in Ids.Girl.values():
		var folder := INTERACTIONS_DIR.path_join(Ids.girl_key(value as Ids.Girl)) + "/"
		if value != Ids.Girl.NONE and value != girl and interaction.resource_path.begins_with(folder):
			problems.append("%s: uses %s's file %s" % [where, Ids.name_of(Ids.Girl, value), interaction.resource_path])
	for effect in interaction.effects:
		if effect is DialogEffect:
			var path: String = effect.dialog_path.replace("{girl}", Ids.girl_key(girl))
			problems.append_array(_check_dialog_ref(path, effect.start_label, where))
	return problems


# ---------------------------------------------------------------- locations

static func _check_locations(locations: LocationsRepo, girls: GirlsRepo) -> PackedStringArray:
	var problems: PackedStringArray = []
	var seen: Dictionary[int, LocationInfo] = {}
	var poi_owner: Dictionary[int, LocationInfo] = {}
	for location in locations.locations:
		if location == null:
			problems.append("locations_repo.tres has an empty entry")
			continue
		var location_name := Ids.name_of(Ids.Location, location.id)
		if not Ids.Location.values().has(location.id) or location.id == Ids.Location.NONE:
			problems.append("LocationInfo '%s' has id %s, which is not a valid Ids.Location" % [location.resource_path, location_name])
			continue
		if seen.has(location.id):
			problems.append("Location %s is defined twice (%s, %s)" % [location_name, seen[location.id].resource_path, location.resource_path])
			continue
		seen[location.id] = location
		for poi in location.points_of_interest:
			if poi == null:
				problems.append("Location %s has an empty point of interest" % location_name)
				continue
			problems.append_array(_check_poi(location, poi, poi_owner, girls))
		if location.scene != null:
			problems.append_array(_check_scene_markers(location))

	for value: int in Ids.Location.values():
		if value != Ids.Location.NONE and not seen.has(value):
			problems.append("Ids.Location.%s has no LocationInfo in locations_repo.tres" % Ids.name_of(Ids.Location, value))
	for value: int in Ids.Poi.values():
		if value != Ids.Poi.NONE and not poi_owner.has(value):
			problems.append("Ids.Poi.%s is not used by any location" % Ids.name_of(Ids.Poi, value))
	if locations.starting_location != null and not locations.starting_location in locations.locations:
		problems.append("locations_repo.tres: starting_location is not in the locations list")
	return problems


static func _check_poi(location: LocationInfo, poi: PoiInfo, poi_owner: Dictionary[int, LocationInfo], girls: GirlsRepo) -> PackedStringArray:
	var problems: PackedStringArray = []
	var location_name := Ids.name_of(Ids.Location, location.id)
	var poi_name := Ids.name_of(Ids.Poi, poi.id)
	if poi.id == Ids.Poi.NONE or not Ids.Poi.values().has(poi.id):
		problems.append("Location %s has POI %s, which is not a valid Ids.Poi" % [location_name, poi_name])
		return problems
	if poi_owner.has(poi.id):
		problems.append("POI %s is used by both %s and %s" % [poi_name, Ids.name_of(Ids.Location, poi_owner[poi.id].id), location_name])
	poi_owner[poi.id] = location
	if Ids.poi_location(poi.id) != location.id or not poi_name.begins_with(location_name + "_"):
		problems.append("POI %s is in location %s but is not numbered/named for it (see Ids.Poi rules)" % [poi_name, location_name])

	for setup in poi.girl_setups:
		if setup == null:
			problems.append("POI %s has an empty girl setup" % poi_name)
			continue
		var girl_name := Ids.name_of(Ids.Girl, setup.girl)
		if not _is_registered_girl(girls, setup.girl):
			problems.append("POI %s has a setup for girl %s, who is not a registered girl" % [poi_name, girl_name])
			continue
		var context := "POI %s, girl %s setup" % [poi_name, girl_name]
		problems.append_array(_check_conditions(setup.conditions, girls, context))
		for interaction in setup.extra_interactions:
			problems.append_array(_check_interaction(interaction, setup.girl, context))
	return problems


## Instantiates the scene (not added to the tree, so _ready doesn't run) and compares its
## PointOfInterest markers with the location's PoiInfos.
static func _check_scene_markers(location: LocationInfo) -> PackedStringArray:
	var problems: PackedStringArray = []
	var location_name := Ids.name_of(Ids.Location, location.id)
	var root := location.scene.instantiate()
	var markers: Dictionary[int, bool] = {}
	for marker in root.find_children("*", "PointOfInterest", true, false):
		var poi: int = (marker as PointOfInterest).poi
		var poi_name := Ids.name_of(Ids.Poi, poi)
		if poi == Ids.Poi.NONE:
			problems.append("Location %s scene: marker '%s' has no poi set" % [location_name, marker.name])
		elif markers.has(poi):
			problems.append("Location %s scene: two markers for POI %s" % [location_name, poi_name])
		elif location.get_poi(poi as Ids.Poi) == null:
			problems.append("Location %s scene: marker for POI %s has no PoiInfo" % [location_name, poi_name])
		markers[poi] = true
	root.free()
	for poi in location.points_of_interest:
		if poi != null and not markers.has(poi.id):
			problems.append("Location %s: PoiInfo %s has no marker in the scene" % [location_name, Ids.name_of(Ids.Poi, poi.id)])
	return problems


# ---------------------------------------------------------------- cutscenes

## Registered cutscenes plus every CutsceneData .tres (unregistered ones can be played from code).
static func _collect_cutscenes(repo: CutscenesRepo) -> Array[CutsceneData]:
	var result: Array[CutsceneData] = []
	for cutscene in repo.cutscenes:
		if cutscene != null and not cutscene in result:
			result.append(cutscene)
	for resource in _load_all(CUTSCENES_DIR, "CutsceneData"):
		if not resource in result:
			result.append(resource)
	return result


static func _check_cutscenes(cutscenes: Array[CutsceneData], repo: CutscenesRepo, girls: GirlsRepo) -> PackedStringArray:
	var problems: PackedStringArray = []
	var resources: Array[Resource] = []
	resources.assign(cutscenes)
	problems.append_array(_check_unique_ids("Cutscene", resources))
	for cutscene in cutscenes:
		var cutscene_name := "Cutscene '%s'" % cutscene.id
		if cutscene in repo.cutscenes and cutscene.trigger_interaction == null and not cutscene.trigger_after_action:
			problems.append("%s is registered but has no trigger (set trigger_interaction or trigger_after_action)" % cutscene_name)
		problems.append_array(_check_conditions(cutscene.conditions, girls, cutscene_name))
		for step in cutscene.steps:
			if step is CutsceneDialogStep:
				problems.append_array(_check_dialog_ref(step.dialog_path, step.label, cutscene_name))
			elif step is CutsceneBackgroundStep:
				problems.append_array(_check_staging(step, girls, cutscene_name))
	return problems


static func _check_staging(step: CutsceneBackgroundStep, girls: GirlsRepo, cutscene_name: String) -> PackedStringArray:
	var problems: PackedStringArray = []
	for staging in step.girls:
		if staging == null:
			continue
		var girl_name := Ids.name_of(Ids.Girl, staging.girl)
		var poi_name := Ids.name_of(Ids.Poi, staging.poi)
		if not _is_registered_girl(girls, staging.girl):
			problems.append("%s stages girl %s, who is not a registered girl" % [cutscene_name, girl_name])
		if step.location == null:
			problems.append("%s stages girl %s but its background step has no location" % [cutscene_name, girl_name])
		elif step.location.get_poi(staging.poi) == null:
			problems.append("%s stages girl %s at POI %s, which is not in location %s" % [
				cutscene_name, girl_name, poi_name, Ids.name_of(Ids.Location, step.location.id)])
	return problems


# ---------------------------------------------------------------- shared

static func _check_conditions(conditions: Array[InteractionCondition], girls: GirlsRepo, context: String) -> PackedStringArray:
	var problems: PackedStringArray = []
	for condition in conditions:
		if condition == null:
			problems.append("%s has an empty condition" % context)
		elif condition is GirlStatCondition:
			var girl_condition := condition as GirlStatCondition
			if girl_condition.girl != Ids.Girl.NONE and not _is_registered_girl(girls, girl_condition.girl):
				problems.append("%s: GirlStatCondition girl %s is not a registered girl" % [context, Ids.name_of(Ids.Girl, girl_condition.girl)])
			if not Ids.Stat.values().has(girl_condition.stat) or girl_condition.stat == Ids.Stat.NONE:
				problems.append("%s: GirlStatCondition has no valid stat (%s)" % [context, Ids.name_of(Ids.Stat, girl_condition.stat)])
			elif girl_condition.comparison == InteractionCondition.Comparison.BELOW_MAX and GirlInfo.new().get_stat_max(girl_condition.stat) < 0:
				problems.append("%s: GirlStatCondition BELOW_MAX on %s, which has no max" % [context, Ids.name_of(Ids.Stat, girl_condition.stat)])
		elif condition is PlayerStatCondition:
			var player_condition := condition as PlayerStatCondition
			if not Ids.PlayerStat.values().has(player_condition.stat) or player_condition.stat == Ids.PlayerStat.NONE:
				problems.append("%s: PlayerStatCondition has no valid stat (%s)" % [context, Ids.name_of(Ids.PlayerStat, player_condition.stat)])
			elif player_condition.comparison == InteractionCondition.Comparison.BELOW_MAX and PlayerInfo.new().get_stat_max(player_condition.stat) < 0:
				problems.append("%s: PlayerStatCondition BELOW_MAX on %s, which has no max" % [context, Ids.name_of(Ids.PlayerStat, player_condition.stat)])
	return problems


static func _check_dialog_ref(path: String, label: String, context: String) -> PackedStringArray:
	if not FileAccess.file_exists(path):
		return ["%s: dialog file '%s' not found" % [context, path]]
	if not label.is_empty() and not DialogParser.parse_file(path).has_label(label):
		return ["%s: dialog '%s' has no label '%s'" % [context, path, label]]
	return []


static func _check_unique_ids(kind: String, resources: Array[Resource]) -> PackedStringArray:
	var problems: PackedStringArray = []
	var seen: Dictionary[StringName, Resource] = {}
	for resource in resources:
		var id: StringName = resource.get(&"id")
		if id.is_empty():
			problems.append("%s '%s' has an empty id" % [kind, resource.resource_path])
		elif seen.has(id):
			problems.append("%s id '%s' is used twice (%s, %s)" % [kind, id, seen[id].resource_path, resource.resource_path])
		else:
			seen[id] = resource
	return problems


static func _speaker_typo_of(speaker: String) -> String:
	var key := speaker.strip_edges().to_lower()
	if key.is_empty() or key == "girl" or key == "player" or key.contains("{"):
		return ""
	if Ids.girl_from_key(key) != Ids.Girl.NONE:
		return ""
	for value: int in Ids.Girl.values():
		var girl_key := Ids.girl_key(value as Ids.Girl)
		if value != Ids.Girl.NONE and _edit_distance(key, girl_key) <= MAX_SPEAKER_TYPO_DISTANCE:
			return girl_key.capitalize()
	return ""


static func _instruction_texts(instruction: Dictionary) -> PackedStringArray:
	var texts: PackedStringArray = []
	for key in ["text", "condition", "expression"]:
		if instruction.has(key):
			texts.append(str(instruction[key]))
	for option: Dictionary in instruction.get("options", []):
		texts.append(str(option.get("text", "")))
		texts.append(str(option.get("condition", "")))
	return texts


## Levenshtein distance.
static func _edit_distance(a: String, b: String) -> int:
	var previous: PackedInt32Array = []
	for j in b.length() + 1:
		previous.append(j)
	for i in range(1, a.length() + 1):
		var current: PackedInt32Array = [i]
		for j in range(1, b.length() + 1):
			var cost := 0 if a[i - 1] == b[j - 1] else 1
			current.append(mini(mini(previous[j] + 1, current[j - 1] + 1), previous[j - 1] + cost))
		previous = current
	return previous[b.length()]


static func _load_all(dir_path: String, class_name_filter: StringName) -> Array[Resource]:
	var result: Array[Resource] = []
	for path in _find_files(dir_path, "tres"):
		var resource := load(path)
		if resource != null and resource.get_script() != null \
				and resource.get_script().get_global_name() == class_name_filter:
			result.append(resource)
	return result


static func _find_files(dir_path: String, extension: String) -> PackedStringArray:
	var result: PackedStringArray = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return result
	for file in dir.get_files():
		# Exported builds list "x.tres.remap" instead of "x.tres".
		var file_name := file.trim_suffix(".remap")
		if file_name.get_extension() == extension:
			result.append(dir_path.path_join(file_name))
	for sub_dir in dir.get_directories():
		result.append_array(_find_files(dir_path.path_join(sub_dir), extension))
	return result
