extends Node
## GameState: owns all game data (definitions + runtime state). No gameplay logic here.
## Systems (TimeManager, InteractionManager, DialogManager) read and change this data.

# Loaded at runtime with load(), NOT preload(). These resources contain scripts
# (effects, conditions) that reference GameState itself. A preload would create a
# compile-time cycle that breaks the editor ("Could not parse global class ...") and
# can make the editor re-save resources with broken sub-resources dropped.
const GIRLS_REPO_PATH := "res://Resources/Girls/girls_repo.tres"
const LOCATIONS_REPO_PATH := "res://Resources/Locations/locations_repo.tres"
const PLAYER_INFO_PATH := "res://Resources/Player/player_info.tres"
const JOBS_REPO_PATH := "res://Resources/Jobs/jobs_repo.tres"

var girls: GirlsRepo
var locations: LocationsRepo
var jobs: JobsRepo
var player_stats: PlayerInfo
var world_info: WorldInfo


func _ready() -> void:
	load_default()


## Sets up the state for a fresh game.
## Note: runtime values (stats, money, upgrade levels) are stored directly on the loaded
## resource instances. That never writes to disk, but a future save/load or "new game"
## flow must serialize/reset these fields explicitly.
func load_default() -> void:
	girls = load(GIRLS_REPO_PATH)
	locations = load(LOCATIONS_REPO_PATH)
	jobs = load(JOBS_REPO_PATH)
	player_stats = load(PLAYER_INFO_PATH)
	player_stats.create_inventory()
	world_info = WorldInfo.new()

	world_info.current_location = locations.starting_location
	player_stats.refill_actions()


func get_girls() -> Array[GirlInfo]:
	return girls.girls
