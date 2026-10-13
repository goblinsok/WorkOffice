# Action minigame

A girl's "Action" interaction opens a minigame: she is shown alone in a staged copy of her location, at her point, in the scene's pose. Options around her (Praise, Scold, Pat) raise or lower her Arousal. `ActionManager` (autoload) runs it, and `UI/Action/action_overlay` is the view.

## Pieces
- `ActionSceneData` (`.tres` in `Resources/ActionScenes/`, registered in `action_scenes_repo.tres`; the repo order is the bottom bar order): `id`, `label`, `icon`, `pose` (`Ids.Pose`), `conditions` (when it's offered: `LocationCondition`, `TimeCondition`, stat conditions, ...), `options`.
- Options are plain `InteractionData` (shared files in `Resources/ActionScenes/Options/`, ids `action_<name>`). Arousal changes are `StatEffect(AROUSAL, ±n)`, and any other effect works too (bubbles, dialogs). They spend no actions, so keep `action_cost` at 0. `ContentValidator` reports a non-zero cost.
- Every girl needs a scene for every action scene's pose (`GirlInfo.poses`). `ContentValidator` reports a missing one.
- Each girl has `Resources/Interactions/<key>/action.tres`, listed in her `GirlInfo.interactions`: `ActionScenesAvailableCondition` (hidden when no scene is available) plus `ActionSceneEffect` (optional `start_scene`; otherwise the first available scene).

## Flow
`ActionSceneEffect` awaits `ActionManager.play(ctx)`, so `InteractionManager` stays busy for the whole minigame and spends the interaction's `action_cost` (1) once it ends.
- `play()` fades out and stages the scene: `GlobalSignals.action_stage_requested(staging)`, which `Scenes/base.gd` handles like a cutscene staging (`WorldInfo` placements and location are untouched). Then it emits `action_started` and fades in.
- The session context (`ActionManager.context`) has the girl, her real location and point, and `view` = her staged view (group `staged_girl_views`). Scene conditions and options are checked against it.
- `switch_to(scene)` (bottom bar) fades and restages. `perform(option)` runs the option's effects. `end()` (X, then confirmation; Esc opens it too) fades, restores the real location (`action_stage_requested(null)`), and emits `action_finished`. All of them are ignored while `is_busy()`.
- `GameUi` hides the toolbar and closes menus on `action_started`, exactly as for cutscenes, so the top info bar stays. The overlay (layer 20) blocks the world with a full-screen STOP blocker. The Arousal bar is the girl's persistent `arousal` stat and updates through `GirlInfo.stats_changed`. Reaching max does nothing for now.

## Recipes
- **New option:** create an `InteractionData` in `Resources/ActionScenes/Options/` (`action_cost = 0`) and add it to a scene's `options`.
- **New action scene:** if it needs a new pose, add an `Ids.Pose` value, a `Scenes/Girls/Poses/base_<pose>.tscn` (copy one: frame layout plus an autoplayed looping animation) and a `<girl>_<pose>.tscn` per girl, then add it to each `GirlInfo.poses`. Then create the `ActionSceneData` `.tres` (icon: a 64x64 white silhouette in `Assets/UI/Actions/`) and register it in `action_scenes_repo.tres`.
