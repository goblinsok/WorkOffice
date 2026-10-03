class_name GirlsRepo extends Resource
## Registry of every girl in the game. Edit Resources/Girls/girls_repo.tres to add girls.

@export var girls: Array[GirlInfo] = []


func get_by_id(girl_id: StringName) -> GirlInfo:
	for girl in girls:
		if girl.id == girl_id:
			return girl
	return null
