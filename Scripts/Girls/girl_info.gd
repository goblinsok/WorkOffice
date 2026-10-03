class_name GirlInfo extends Resource
## Definition and runtime state of a single girl.
## Stats are plain exported ints. A stat `x` is clamped to `max_x` if such a property exists.

signal stats_changed(stat: StringName, value: int)

@export var id: StringName
@export var display_name: String
@export var name_color: Color = Color.WHITE
## Default scene shown when the girl is spawned at a point of interest.
## PoiGirlSetup.scene overrides it.
@export var location_scene: PackedScene
## Photo used by menus (dossier, job assignment, battle).
@export var portrait: Texture2D
## Job title shown in the dossier.
@export var role: String
@export_multiline var bio: String

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


func has_stat(stat: StringName) -> bool:
	return stat in self


func get_stat(stat: StringName) -> int:
	if not has_stat(stat):
		push_warning("GirlInfo '%s' has no stat '%s'" % [id, stat])
		return 0
	return get(stat)


func set_stat(stat: StringName, value: int) -> void:
	if not has_stat(stat):
		push_warning("GirlInfo '%s' has no stat '%s'" % [id, stat])
		return
	var max_stat := StringName("max_" + stat)
	if has_stat(max_stat):
		value = mini(value, get(max_stat))
	value = maxi(value, 0)
	set(stat, value)
	stats_changed.emit(stat, value)


func modify_stat(stat: StringName, delta: int) -> void:
	set_stat(stat, get_stat(stat) + delta)


func restore_energy() -> void:
	set_stat(&"energy", max_energy)
