class_name LocationsRepo extends Resource
## Registry of every location in the game. Edit Resources/Locations/locations_repo.tres to add locations.

@export var locations: Array[LocationInfo] = []
## Location the game starts in.
@export var starting_location: LocationInfo


func get_by_id(location_id: Ids.Location) -> LocationInfo:
	for location in locations:
		if location.id == location_id:
			return location
	return null


func get_available() -> Array[LocationInfo]:
	return locations.filter(func(location: LocationInfo) -> bool: return location.is_available())
