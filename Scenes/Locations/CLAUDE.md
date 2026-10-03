# Locations, points of interest, girl views

## Data (`Scripts/Locations`, `Resources/Locations`)
- `LocationInfo`: its scene, `unlocked`, `upgrade_level`, and `points_of_interest: Array[PoiInfo]`. It's available when it's unlocked **and** has a scene. The list and `starting_location` live in `locations_repo.tres`.
- `PoiInfo`: a spawn point with `required_upgrade_level` and `girl_setups`. **A girl can only appear at a POI that has a `PoiGirlSetup` for her.**
- `PoiGirlSetup`: the per-girl, per-point config: `animation`, an optional `scene` override (otherwise `GirlInfo.location_scene`), and `interactions`.
- `GirlScheduler`: at every phase start `TimeManager` calls `schedule()`, which returns girl id → `GirlPlacement` (at most one girl per POI, chosen at random). For new rules, subclass it and override `_pick_candidate()`.

## Scenes
- A location scene inherits `base_location.tscn` (`BaseLocation`) and contains `PointOfInterest` Marker2D nodes. **A marker's `poi_id` must match a `PoiInfo.id`**, and mismatches are warned about at runtime. The marker's position and scale control how the girl looks there. `Scenes/base.gd` sets `location.info` before adding it to the tree.
- `BaseLocation` re-spawns girls from `WorldInfo.placements` whenever `GlobalSignals.girls_placed` fires.
- A girl view inherits `Scenes/Girls/Location/base_girl_location_scene.tscn` (`BaseGirlLocation`). It provides the Sprite (3x2 frames), the shared animation library `Resources/Animations/girl_basic_animations.tres` (Standing, Jumping), the `Select` Area2D (hover and click), `BubbleAnchor` and `MenuAnchor`. A concrete girl scene only sets the texture.
- Location switching: the map emits `switch_location`, `base.gd` fades, swaps the scene, and emits `location_changed`.

## Recipes
- **New location:** create a scene inheriting `base_location.tscn` with markers, add a `LocationInfo` `.tres` with matching `PoiInfo`s, register it in `locations_repo.tres`, and add a map button plus an entry in `UI/Menu/map.gd` `location_buttons`.
- **New girl:** create a sprite sheet and a scene inheriting the base girl scene, add a `GirlInfo` `.tres` (with an AtlasTexture `portrait`) registered in `girls_repo.tres`, add `PoiGirlSetup`s where she can appear, and add `Dialogs/<id>/talk.dlg`.
