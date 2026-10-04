class_name Ids extends RefCounted
## Typed ids for content that code and data refer to. Exported as enums, so the inspector
## shows a dropdown and a typo in code is a parse error.
##
## Rules (.tres files store the int value, not the name):
##   - Give every value an explicit number. Never reorder, renumber or reuse a value.
##     Renaming a key is safe for data (code then fails to parse until it is updated).
##   - NONE = 0 is the default and means "unset" / "empty".
##   - Poi values are <location value> * 100 + n, and the key starts with the location key
##     (GYM_TREADMILL = 301 belongs to GYM = 3). ContentValidator enforces both.
##   - Removing a value: delete it here, then fix everything ContentValidator reports.
##
## Text forms (.dlg speakers, Dialogs/<girl>/ paths, add_stat("affection", 1)) are the
## lowercase keys, converted with the helpers below.

enum Girl {
	NONE = 0,
	LIDYA = 1,
	NELLE = 2,
}

enum Location {
	NONE = 0,
	WORKING_AREA = 1,
	KITCHEN = 2,
	GYM = 3,
}

enum Poi {
	NONE = 0,
	WORKING_AREA_DESK_LEFT = 101,
	WORKING_AREA_DESK_RIGHT = 102,
	GYM_TREADMILL = 301,
	GYM_MATS = 302,
}

## Girl stats. Each one maps to the GirlInfo property of the same lowercase name.
enum Stat {
	NONE = 0,
	ENERGY = 1,
	AROUSAL = 2,
	AFFECTION = 3,
}

## Player stats for PlayerStatCondition. Each one maps to the PlayerInfo property of the same
## lowercase name (and max_<name>, if it exists, is its max).
enum PlayerStat {
	NONE = 0,
	MONEY = 1,
	FAME = 2,
	ACTIONS = 3,
	CHARISMA = 4,
	MANAGEMENT = 5,
}

## Keys of StatusEffectData.modifiers.
enum BossModifier {
	NONE = 0,
	## Added to the boss's attack.
	ATTACK = 1,
	## Added to every hit the boss receives.
	DAMAGE_TAKEN = 2,
}

const POI_BLOCK := 100


## "lidya" for Girl.LIDYA. Used for .dlg speakers and Dialogs/<girl>/ paths.
static func girl_key(girl: Girl) -> String:
	return String(Girl.find_key(girl)).to_lower() if Girl.values().has(girl) else ""


## Case-insensitive. Girl.NONE if unknown.
static func girl_from_key(key: String) -> Girl:
	return Girl.get(key.strip_edges().to_upper(), Girl.NONE)


## &"affection" for Stat.AFFECTION: the GirlInfo property name.
static func stat_property(stat: Stat) -> StringName:
	return StringName(String(Stat.find_key(stat)).to_lower()) if Stat.values().has(stat) else &""


## Case-insensitive. Stat.NONE if unknown.
static func stat_from_name(stat_name: String) -> Stat:
	return Stat.get(stat_name.strip_edges().to_upper(), Stat.NONE)


## &"money" for PlayerStat.MONEY: the PlayerInfo property name.
static func player_stat_property(stat: PlayerStat) -> StringName:
	return StringName(String(PlayerStat.find_key(stat)).to_lower()) if PlayerStat.values().has(stat) else &""


static func poi_location(poi: Poi) -> Location:
	@warning_ignore("integer_division")
	return (poi / POI_BLOCK) as Location


## "Desk Left" for Poi.WORKING_AREA_DESK_LEFT.
static func poi_label(poi: Poi) -> String:
	var key := String(Poi.find_key(poi)) if Poi.values().has(poi) else ""
	var prefix := String(Location.find_key(poi_location(poi))) + "_"
	if key.begins_with(prefix):
		key = key.substr(prefix.length())
	return key.capitalize()


## Readable name of any enum value, for messages ("GYM_MATS", or the number if unknown).
static func name_of(enum_dict: Dictionary, value: int) -> String:
	var key: Variant = enum_dict.find_key(value)
	return String(key) if key != null else str(value)
