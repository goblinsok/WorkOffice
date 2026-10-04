# Jobs, boss battle, day end

Also covers `Scripts/Battle`, `UI/Battle` and `UI/Menus/Job`.

## Data
- `JobData` (`Resources/Jobs/*.tres`, listed in `jobs_repo.tres`): a boss. `hp` **persists between days** until 0, at which point `completed` is set and rewards are paid. `attack` drains energy from every assigned girl **once, at battle start**. It also has `abilities`, `status_effects` and `max_assigned`. Assignment is runtime `assigned` slots (`Ids.Girl`, `NONE` = empty): `assign` swaps, `unassign`, and `get_assigned_girls(repo)`.
- `StatusEffectData`: buffs and debuffs with `modifiers: Dictionary[Ids.BossModifier, int]` (`ATTACK`, `DAMAGE_TAKEN`). A new modifier needs an `Ids.BossModifier` value and handling in `BattleSimulation`/`JobData`.
- `BossAbility`: a **placeholder**. Its trigger (BATTLE_START / ROUND_START / LOW_HP) calls `activate(battle)`, which only logs an event. Subclass it to add mechanics.
- `JobsRepo.get_current()` returns the first job that isn't completed.

## Battle
- `BattleSimulation` resolves the whole fight up front into `Array[BattleEvent]`. It works on `BattleUnit` copies, takes an optional seeded RNG, and has **no side effects until `apply_results()`**. The rules are in its header comment. Change rules there, not in the view.
- `JobManager.run_battle()`: simulate, then emit `battle_started`. If a view is connected, it awaits `finish_presentation()`. Then it applies the results, completes the job if won, and emits `battle_finished`. With no view connected (tests), it applies immediately.
- `UI/Battle/battle_window` only plays events back (floating text, shakes, bars). Clicking speeds playback up (`speed`).

## Day end
`JobManager._ready()` registers `run_day_end_battle` with `TimeManager.register_day_end_step()`. The battle only runs if there's a current job with assigned girls. After the day-end steps, the new day restores every girl's energy to max. Add other end-of-day events the same way.

## Job menu (`UI/Menus/Job`)
It shows the boss info and handles assignment by drag & drop: `GirlChip` (mouse_filter PASS) onto a `GirlDropZone` (`slot_index`, or -1 for the pool). The zone only emits `girl_dropped`, and the menu calls `job.assign` / `job.unassign`.

## Balance notes
Lidya: attack 8, costs 15 energy. Nelle: attack 11, costs 20. The PC has 150 HP and a 25-energy attack, and takes +2 damage per hit. With both girls that's about 75 damage a day, so it's defeated on day 2. The smoke test asserts the attack counts (5 and 3), so update it if you change the numbers.
