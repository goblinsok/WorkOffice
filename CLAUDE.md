# CLAUDE.md

Office-management game: the player manages 3+ girls, interacts with them, raises their stats, and assigns them to jobs (boss battles). Scope is loosely defined, so don't build ahead of the current task without an explicit request.

Godot 4.5, GDScript only, 900x700 viewport. Main scene: `Scenes/base.tscn`. Not a git repo.

## Verify every change
```
Tools/verify.sh          # import (script/resource errors) + smoke test (prints PASS / N FAILURES)
Tools/verify.sh import   # or only one of them
Tools/verify.sh smoke
```
Run it exactly like this (no `cd`, no variables, no pipes): that form is allowlisted in `.claude/settings.json` and runs without a permission prompt. Edit files with the Edit/Write tools, not `python -`/`sed -i`/`cat >` heredocs, which always prompt. One-off Godot runs (`--script`, screenshot scenes) use the full path `D:/MyGame/Godot_v4.5.1/Godot_v4.5.1-stable_win64_console.exe` and prompt, which is intended.
The smoke test also asserts `ContentValidator` finds no problems; in debug builds `GameState` prints them at startup as `Content: ...` errors. Keep `Tests/smoke_test.gd` in sync with core flows. For visual checks, run a temporary scene that saves `get_viewport().get_texture().get_image()`, then delete it. **Only ever stop the Godot process you started (by PID). The user's editor may be open.**

## Subsystem docs: read the one for the area you touch
| Area | Doc | Code |
|---|---|---|
| Interactions, conditions/effects, expressions | `Scripts/Interactions/CLAUDE.md` | `Scripts/Interactions`, `Scripts/Core`, `UI/Interaction` |
| Dialog scripts (`.dlg`) and the dialog runtime | `Dialogs/README.md`, `Scripts/Dialog/CLAUDE.md` | `Scripts/Dialog`, `UI/Dialog` |
| Cutscenes (steps, triggers, proceed/cancel) | `Scripts/Cutscenes/CLAUDE.md` | `Scripts/Cutscenes`, `Scripts/Autoload/cutscene_manager.gd`, `UI/Cutscene` |
| Locations, POIs, girl views and poses, placement | `Scenes/Locations/CLAUDE.md` | `Scenes/`, `Scripts/Locations` |
| Action minigame (action scenes, options, Arousal) | `Scripts/Actions/CLAUDE.md` | `Scripts/Actions`, `Scripts/Autoload/action_manager.gd`, `UI/Action` |
| Items and inventory | `Scripts/Items/CLAUDE.md` | `Scripts/Items`, `UI/Menus/Inventory` |
| Jobs, boss battle, day end | `Scripts/Jobs/CLAUDE.md` | `Scripts/Jobs`, `Scripts/Battle`, `UI/Battle`, `UI/Menus/Job` |
| All UI: layers, menus, input blocking, drag & drop | `UI/CLAUDE.md` | `UI/` |

Data (`.tres`) lives in `Resources/<Area>/`, and each area has a `*_repo.tres` registry. Class APIs are documented in `##` comments at the top of each script. Read those instead of expecting field lists here.

## Core architecture
Data-driven: content lives in Resources and `.dlg` files, logic in small systems, and scenes are views.

Autoloads, in load order:
- `GameState`: data only (`girls`, `locations`, `jobs`, `cutscenes`, `action_scenes`, `player_stats` + inventory, `world_info`)
- `GlobalSignals`: event bus
- `Enums`
- `ScreenFader`: `await fade_out()` / `fade_in()`
- `DialogManager`
- `CutsceneManager`: plays `CutsceneData`; `InteractionManager.run()` auto-triggers `interaction:<id>` cutscenes
- `ActionManager`: runs the Action minigame (`ActionSceneData` scenes in a staged location)
- `InteractionManager`
- `TimeManager`: actions, phases, and `register_day_end_step()`
- `JobManager`

**Time loop:** every interaction spends actions (3 per phase). At 0, `TimeManager.advance_phase()` runs. At the end of Evening it first awaits the day-end steps (the job battle). Then it fades, advances the phase (and the day, restoring girls' energy), refills actions, re-places the girls, and fades back in.

## Conventions
- Static typing everywhere. `class_name X extends Y` on one line. Use `@abstract` for bases that must be subclassed.
- Node references use `@onready var x: T = %UniqueName`. Base scenes are named `base_*`, and variants inherit both the scene and the script.
- Girls, locations, POIs, poses, girl stats, player stats and boss modifiers are identified by the enums in `Scripts/Core/ids.gd` (`Ids.Girl.LIDYA`). Values are explicit and never reordered or reused (`.tres` stores the int); read its header before adding or removing one. Other content ids (interactions, items, jobs, cutscenes) are lowercase `StringName`s (`&"talk"`). Indent with tabs.
- Cross-system events go through `GlobalSignals`. Direct calls into manager autoloads are fine for commands.
- Runtime state lives on the loaded `.tres` instances (not duplicated). That's fine at runtime, but a save system must serialize it.

## Traps (these have bitten before)
- **Never `preload()` `Resources/**/*.tres` in autoloads or in scripts those resources depend on.** Use `load()`. It creates a compile-time cycle: the editor shows "Could not parse global class" and then re-saves `.tres` files with sub-resources dropped.
- Never invent UIDs. Reference new files by `res://` path; Godot adds UIDs on save.
- Don't name methods or variables after GDScript builtins (`get_stack`, `round`, `match`, `size`).
- A function containing `await` is a coroutine. Call it bare or with `await`, never assign its result without awaiting.
- `.tscn`/`.tres` are safe to hand-write for plain properties. Generate complex ones with a script, and check them with the import command.
- After outside edits, the user's editor needs Project → Reload Current Project before it saves anything.

## Known issues / tech debt
- `*.dlg` must be added to the export preset's non-resource filter.
- There's no save/load, no "new game" reset, and no id registry for items or jobs.
- The Kitchen has no scene.
- The Bowing sheets are generated from the Standing frame (a per-row remap of the upper body), as placeholders for real art.
- Location travel and item use cost no actions (intentional for now).
