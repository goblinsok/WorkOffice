extends Node

var lidya: GirlInfo = preload("res://Resources/Girls/lidya_stats.tres")
var nelle: GirlInfo = preload("res://Resources/Girls/nelle_stats.tres")

var player_stats : PlayerInfo

var world_info : WorldInfo = WorldInfo.new()

var top_ui_update : bool = false

func _ready():
	load_default()
	
func load_default() -> void:
	player_stats = preload("res://Resources/Player/player_info.tres")
	
	world_info.current_location = world_info.working_area_location
