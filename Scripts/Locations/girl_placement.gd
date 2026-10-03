class_name GirlPlacement extends RefCounted
## Runtime record of where a girl is during the current time phase.

var girl: GirlInfo
var location: LocationInfo
var poi: PoiInfo
var setup: PoiGirlSetup


func _init(p_girl: GirlInfo, p_location: LocationInfo, p_poi: PoiInfo, p_setup: PoiGirlSetup) -> void:
	girl = p_girl
	location = p_location
	poi = p_poi
	setup = p_setup
