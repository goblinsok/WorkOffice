class_name GirlInfo extends Resource
## Definition and runtime state of a single girl.
## Stats are plain exported ints named after Ids.Stat keys (lowercase). A stat `x` is clamped
## to `max_x` if such a property exists.

signal stats_changed(stat: Ids.Stat, value: int)

@export var id: Ids.Girl
@export var display_name: String
@export var name_color: Color = Color.WHITE
## Her world scene for each pose (inheriting Scenes/Girls/Poses/base_<pose>.tscn).
## PoiGirlSetup, cutscene stagings and action scenes pick a pose; ContentValidator reports a
## pose they use that has no scene here.
@export var poses: Dictionary[Ids.Pose, PackedScene] = {}
## Photo used by menus (dossier, job assignment, battle).
@export var portrait: Texture2D
## Job title shown in the dossier.
@export var role: String
@export_multiline var bio: String

## Offered at every point where she appears, before the point's PoiGirlSetup.extra_interactions.
## Her interaction .tres files live in Resources/Interactions/<girl key>/.
@export var interactions: Array[InteractionData] = []

@export_group("Stats")
@export var energy: int
@export var max_energy: int = 100

@export var arousal: int
@export var max_arousal: int = 100

@export var affection: int
@export var max_affection: int = 20

@export_group("Work")
## Base damage dealt to a job boss per attack.
@export var attack: int = 5
## Energy spent per attack. The girl stops acting when her energy is below this.
@export var attack_energy_cost: int = 10


## Her scene for the pose, or null if she has none.
func get_pose_scene(pose: Ids.Pose) -> PackedScene:
	return poses.get(pose)


func has_stat(stat: Ids.Stat) -> bool:
	var property := Ids.stat_property(stat)
	return not property.is_empty() and property in self


func get_stat(stat: Ids.Stat) -> int:
	if not has_stat(stat):
		push_warning("GirlInfo '%s' has no stat '%s'" % [Ids.name_of(Ids.Girl, id), Ids.name_of(Ids.Stat, stat)])
		return 0
	return get(Ids.stat_property(stat))


func set_stat(stat: Ids.Stat, value: int) -> void:
	if not has_stat(stat):
		push_warning("GirlInfo '%s' has no stat '%s'" % [Ids.name_of(Ids.Girl, id), Ids.name_of(Ids.Stat, stat)])
		return
	var property := Ids.stat_property(stat)
	var max_property := StringName("max_" + property)
	if max_property in self:
		value = mini(value, get(max_property))
	value = maxi(value, 0)
	set(property, value)
	stats_changed.emit(stat, value)


## The stat's max_<stat> value, or -1 if it has none.
func get_stat_max(stat: Ids.Stat) -> int:
	var max_property := StringName("max_" + Ids.stat_property(stat))
	return get(max_property) if max_property in self else -1


func modify_stat(stat: Ids.Stat, delta: int) -> void:
	set_stat(stat, get_stat(stat) + delta)


func restore_energy() -> void:
	set_stat(Ids.Stat.ENERGY, max_energy)
