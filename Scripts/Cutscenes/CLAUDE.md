# Cutscenes

Data-driven sequences of steps. `CutsceneManager` (autoload) plays them; `UI/Cutscene/cutscene_overlay` is the view.

## Pieces
- `CutsceneData` (`.tres` in `Resources/Cutscenes/`): `id`, `trigger_interaction`, `trigger_after_action`, `conditions`, `play_once`, `cancels_action`, `steps`. Register it in `cutscenes_repo.tres` to auto-trigger. Unregistered ones can still be played from code with `await CutsceneManager.play(data, ctx)`.
- Steps (`CutsceneStep`, abstract, `run(ctx)` may await): `CutsceneDialogStep` (`.dlg` path + label) and `CutsceneBackgroundStep` (a full-screen `image`, and/or a `location` staged with `CutsceneGirlStaging`s: `girl`, `poi`, `pose`). Both are `@tool` only so the staging's `poi` dropdown lists just the step location's points; `ContentValidator` reports a staging POI outside its location.
- A staged location is shown in the real world view without changing `WorldInfo.current_location` or placements; staged girls are not clickable. The real location is restored (with a fade) when the cutscene ends.

## Flow
`play()` emits `GlobalSignals.cutscene_started`, runs the steps, then restores the world view and emits `cutscene_finished`. During a cutscene only the top info bar is visible (`GameUi` hides the toolbar and closes the menus, the map included), the world is blocked structurally by the overlay's STOP blocker, and a top-right Skip button ends it.
- Click rules: every step except the first waits for a click first (`wait_for_click`, default true; false chains it straight after the previous step). Inside a dialog step the dialog panel handles clicks as usual. If the last step is a background, one more click ends the cutscene.
- Skip stops any active dialog and ends the cutscene, keeping the current proceed/cancel value.

## Proceed or cancel
`play()` returns true if the triggering action should proceed. It starts as `not cancels_action`. A cutscene dialog can override it with `do cancel_action()` / `do proceed_action()` (`InteractionContext.action_cancelled`). A cancelled interaction runs no effects and spends no actions.

## Triggers
Two hooks, both gated by `conditions`:
- `trigger_interaction`: the `InteractionData` resource (drag the `.tres`). `InteractionManager.run()` calls `CutsceneManager.try_trigger_interaction(interaction, ctx)` right after it becomes busy, and the cutscene decides proceed/cancel.
- `trigger_after_action`: checked after every interaction (`InteractionManager.run()`) and item use (`Inventory.use_at()`) finishes, before its actions are spent, with that action's context. Use it for thresholds: `example_cutscene.tres` plays once when a `GirlStatCondition` (Nelle, affection, AT_LEAST 10) passes. Proceed/cancel doesn't apply. Stat changes outside player actions (the day-end battle) are not checked.

A registered cutscene with neither hook is reported by `ContentValidator`. `play_once` is tracked with the world flag `cutscene_seen:<id>` and only affects triggering. To add another kind of hook, add a typed trigger field to `CutsceneData`, a matching `find_*` in `CutscenesRepo` and a `try_trigger_*` in `CutsceneManager`, and honor the returned bool.

## Recipe
Write the `.dlg` (labels per part), create the steps and the `CutsceneData` `.tres` (see `Resources/Cutscenes/example_cutscene.tres`, unregistered; the smoke test builds its own cutscene in code), set `trigger_interaction`/`conditions`, then add it to `cutscenes_repo.tres`.
