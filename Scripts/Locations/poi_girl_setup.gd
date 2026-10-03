class_name PoiGirlSetup extends Resource
## How a specific girl looks and behaves when spawned at a specific point of interest.

@export var girl_id: StringName
## Animation played by the girl's scene at this point.
@export var animation: StringName = &"Standing"
## Optional override of GirlInfo.location_scene.
@export var scene: PackedScene
## Interactions offered when the girl is clicked at this point, in display order.
@export var interactions: Array[InteractionData] = []


func get_scene(girl: GirlInfo) -> PackedScene:
	return scene if scene != null else girl.location_scene
