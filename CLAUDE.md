# CLAUDE.md

Guidance for working in this Godot project.

## Project

Office-management game. The player manages 3+ girls: interacts with them, raises their stats, and assigns them to work. Scope is still loosely defined, so don't build ahead of the current task without an explicit request.

- **Engine:** Godot 4.5, Forward+ renderer, GDScript only
- **Viewport:** 900x700, nearest-neighbor texture filtering
- **Main scene:** `res://Scenes/base.tscn`
- **Not a git repo** (there is no version control yet)

## Folder layout

| Folder | Contents |
|---|---|
| `Assets/` | Raw art: character sprite sheets (`Characters/Girls/<Name>/Sheet.png`), location backgrounds (`Locations/<Loc>/BG.jpg`) |
| `Resources/` | `.tres` data instances: girl stats, player info, location info |
| `Scenes/` | Gameplay scenes and their attached scripts: the root `base`, locations, girl-in-location scenes |
| `Scripts/` | Scripts that aren't tied to a scene: autoloads and data classes (`Resource` subclasses) |
| `UI/` | HUD (`Game/`), menus (`Menu/`), themes (`Themes/`) |

## Architecture

### Autoloads (`Scripts/Autoload/`)
- `GameState` (`autoload.gd`): global state. Holds the girl resources (`lidya`, `nelle`), `player_stats: PlayerInfo`, and `world_info: WorldInfo`.
- `GlobalSignals` (`global_signals.gd`): event bus. Currently only `switch_location(new_location: LocationInfo)`.
- `Enums` (`enums.gd`): `TIME_STATE`, `WEEK_STATE`, `LOCATIONS`.

### Data model (Resources)
- `GirlInfo` (`Scripts/Girls/girl_info.gd`): exported stats `energy`/`max_energy`, `arousal`, `affection`/`max_affection`. One `.tres` per girl in `Resources/Girls/`.
- `PlayerInfo`: `money` (its setter emits `money_update`) and `fame`.
- `WorldInfo`: current time, day, and location. Owns the singleton `LocationInfo` instances (`gym_location`, `working_area_location`) plus `advance_time()`/`advance_day()`.
- `LocationInfo` → `GymInfo`, `WorkingAreaInfo`, `KitchenInfo` (`Scripts/Locations/Available/`). Each subclass preloads its scene by UID in `_init()`.
- `GirlsRepo`: empty placeholder.

### Scene tree and flow
```
Base (Control, base.gd)
├─ GameUi (CanvasLayer, layer 10): top bar with money and date, Map button
│   └─ Map (CanvasLayer, layer 20): slide-in panel with location buttons
└─ LocationControl
    ├─ LocationBlackFade: fade overlay used during transitions
    └─ LocationCenter: holds the current BaseLocation instance
```
- **Location switching:** a map button emits `GlobalSignals.switch_location(LocationInfo)`. `base.gd` fades to black, instantiates `LocationInfo.scene`, frees the old location, and fades back in. `map.gd` closes itself and disables the button for the current location.
- **Locations:** `BaseLocation` (`Scenes/Locations/base_location.tscn`) is a `Node2D` with a `BG` sprite. Concrete locations inherit it (`working_area.tscn`, `gym_scene.tscn`).
- **Girls in locations:** `BaseGirlLocation` (`Scenes/Girls/Location/base_girl_location_scene.tscn`) has a Sprite, an AnimationPlayer, a `Select` Area2D that handles hover, and a `Selector_Test` highlight polygon. Per-girl, per-location variants inherit it, for example `WorkingArea/Lidya/lidya_WA_standing.tscn` (animations `Standing` and `Jumping`).

## Conventions
- Static typing: `var x: Type`, and `-> void` return types on functions.
- `class_name X extends Y` on one line for reusable classes.
- Node references use unique names: `@onready var foo: Type = %Foo`.
- Scenes and resources are often referenced by UID (`preload("uid://...")`). Prefer UIDs over paths so references survive file moves.
- Tweens: `get_tree().create_tween()`, then `await tween.finished`, then `kill()`.
- Cross-system communication goes through `GlobalSignals`. UI reads state from `GameState`.
- Base scenes and scripts are named `base_*`, and concrete variants inherit them (both the scene and the script).
- Tabs for indentation (see `.editorconfig`).

## Known issues / tech debt (as of initial analysis)
- `Enums.TIME_STATE` sets every value to `1`, so `MORNING == AFTERNOON == EVENING`.
- `WorldInfo.advance_time()`/`advance_day()` assign `find_key()` (a String) to an enum-typed variable. They should assign the int value.
- `LidyaLocation` is instanced directly under `Base/LocationCenter` instead of inside the working-area scene, so she stays visible on every location.
- `Resources/Locations/*.tres` are unused. They also set an `identifier` property that `LocationInfo` doesn't define, and `scene` isn't `@export`ed.
- The Kitchen map button isn't wired up, and `KitchenInfo` has no scene.
- The map doesn't disable the Working Area button at startup, and the `Close` button is unconnected.
- `base.gd` hardcodes the initial scene instead of using `GameState.world_info.current_location`.
- `update_date()` is only called in `_ready`, and nothing triggers a time advance yet.
- There are debug `print`s in `base_girl_location_scene.gd`, stray `map.tscn*.tmp` files, and a placeholder "rweqr" button in `game_ui.tscn`.
- `GirlsRepo` is empty, and the girl `.tres` files are loaded ad hoc in `GameState`.

## Working notes
- Don't hand-edit `.tscn`/`.tres` files unless the change is simple and safe (property values, adding nodes). Prefer describing editor steps for anything complex, such as animations or new UIDs.
- New `.gd` files get a `.gd.uid` sidecar from the editor. Don't invent UIDs.
- Keep changes scoped to the current task. Log newly found issues in the section above instead of fixing them unasked.
