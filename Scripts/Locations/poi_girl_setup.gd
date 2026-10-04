class_name PoiGirlSetup extends Resource
## How a specific girl looks and behaves when spawned at a specific point of interest.
## A girl can have several setups at one point. When the girls are placed, one of her setups
## whose conditions pass is picked at random.

@export var girl: Ids.Girl
## All must pass for this setup to be used. Checked when the girls are placed (at the start of
## every phase) with a context of the girl, the location and the point (no view).
@export var conditions: Array[InteractionCondition] = []
## Animation played by the girl's scene at this point.
@export var animation: StringName = &"Standing"
## Optional override of GirlInfo.location_scene.
@export var scene: PackedScene
## Offered at this point in addition to GirlInfo.interactions (shown after them).
@export var extra_interactions: Array[InteractionData] = []


func get_scene(girl_info: GirlInfo) -> PackedScene:
	return scene if scene != null else girl_info.location_scene


func is_available(context: InteractionContext) -> bool:
	for condition in conditions:
		if condition != null and not condition.is_met(context):
			return false
	return true
