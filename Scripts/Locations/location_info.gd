class_name LocationInfo extends Resource
## Definition and runtime state of a location reachable through the map.

@export var id: Ids.Location
@export var display_name: String
## Scene to instantiate. Must inherit Scenes/Locations/base_location.tscn.
@export var scene: PackedScene
@export var unlocked: bool = true

@export_group("Upgrades")
@export var upgrade_level: int = 0
@export var max_upgrade_level: int = 0

@export_group("Points of interest")
## Data for every spawn point. The scene must contain a PointOfInterest node with a matching poi.
## Each PoiInfo.id must belong to this location (see Ids.Poi numbering).
@export var points_of_interest: Array[PoiInfo] = []


func is_available() -> bool:
	return unlocked and scene != null


func get_poi(poi_id: Ids.Poi) -> PoiInfo:
	for poi in points_of_interest:
		if poi.id == poi_id:
			return poi
	return null


## Points of interest that are currently usable (their upgrade requirement is met).
func get_active_pois() -> Array[PoiInfo]:
	return points_of_interest.filter(func(poi: PoiInfo) -> bool: return poi.is_active(self))
