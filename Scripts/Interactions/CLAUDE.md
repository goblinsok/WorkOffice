# Interactions

The same condition and effect building blocks power interactions, usable items (`Scripts/Items`) and dialog `do`/`if` lines.

## Pieces
- `InteractionData` (`.tres` in `Resources/Interactions/<girl key>/`: every girl has her own files, ids `<key>_<name>`) is a menu option: `conditions` decide when it's available, `effects` run in order (async ones are awaited), and `action_cost` is spent **after** the effects finish.
- Conditions. Prefer the typed ones; `ExpressionCondition` (any expression on the context) is the fallback.
  - `GirlStatCondition`: `girl` (`Ids.Girl`, NONE = the context girl), `stat`, `comparison`, `amount`.
  - `PlayerStatCondition`: `stat` (`Ids.PlayerStat`: money, fame, actions, ...), `comparison`, `amount`.
  - `comparison` is `InteractionCondition.Comparison`: AT_LEAST, AT_MOST, or BELOW_MAX (`amount` ignored; the stat is below its `max_<stat>`, e.g. energy not full, an action spent).
  - `TimeCondition`: checkboxes for phases and weekdays; nothing ticked in a group means any.
- The bases `InteractionCondition.is_met(ctx)` and `InteractionEffect.execute(ctx)` are abstract. `describe()` returns tooltip text.
- `InteractionContext` (`Scripts/Core`) says who, where and which view. **Its public methods are the function API of every script expression** (`add_stat`, `add_money`, `add_actions`, `flag`, `set_flag`, `bubble`, ...).
- `GameExpression` (`Scripts/Core`) is the single cached evaluator, plus `{expr}` interpolation. Variables: `girl`, `player`, `world`, `location`, `name`.
- Build a context with `InteractionContext.new(view)` for a world girl, or `InteractionContext.new().with_girl(g)` without a view. Don't add a static factory that references its own class_name; it triggers editor parse errors.

## Flow
Clicking a girl emits `GlobalSignals.girl_clicked`. `UI/Interaction/interaction_menu` builds the context and shows a radial menu of `InteractionManager.get_visible_interactions()`. Picking an option calls `InteractionManager.run()`, which runs the effects and then `TimeManager.spend_actions(cost)`. Only one interaction runs at a time (`can_interact()`).

The options offered are the girl's own `GirlInfo.interactions` followed by her setup's `PoiGirlSetup.extra_interactions` at that point (`InteractionContext.get_interactions()`; see `Scenes/Locations/CLAUDE.md`). `ContentValidator` reports a girl using a file from another girl's folder.

## Recipes
- **New option:** create an `InteractionData` `.tres` in the girl's folder from existing conditions and effects, then add it to her `GirlInfo.interactions` (offered everywhere) or to a setup's `extra_interactions` (only at that point).
- **New behaviour:** subclass `InteractionEffect` or `InteractionCondition` and implement `describe()` if it should appear in item tooltips.
- **New expression function:** add a public method to `InteractionContext`. For a new variable, extend `GameExpression.VARIABLE_NAMES` and `_get_inputs()`.
- `ExpressionEffect` needs its `description` set by hand to appear in tooltips.
