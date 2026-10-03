# Items and inventory

- `ItemData` (`Resources/Items/*.tres`): behaviour comes from `components: Array[ItemComponent]` rather than subclasses. The tooltip effect text is built from each component's `describe()`, unless `effect_description` overrides it.
- `UsableComponent`: `target` (NONE or GIRL, which fills `ctx.girl`), `consumed`, `action_cost`, plus **the same `conditions`/`effects` as interactions** (see `Scripts/Interactions/CLAUDE.md`). Example: the Soda is a `StatEffect(energy +30)` with the condition `girl.energy < girl.max_energy`.
- `Inventory`: a fixed-size grid (`slots: Array[ItemStack]`, null means empty) owned by `PlayerInfo.inventory`, created from `starting_items`. Every mutation calls `emit_changed()`, and the UI listens to `changed`. `use_at(index, ctx)` is async: it consumes the item first, then runs the effects, then spends actions.
- UI (`UI/Menus/Inventory`): `InventorySlotUI` provides the custom tooltip (`_make_custom_tooltip` returns an `ItemTooltip`; set `item` **before** the tooltip enters the tree), drag to move, and right-click/double-click to use. Items that target a girl open the `GirlPicker` PopupMenu.

## Recipes
- **New item:** create an `ItemData` `.tres` with a GradientTexture2D placeholder icon and a `short_name`. For a usable item, add a `UsableComponent`. Give it to the player via `PlayerInfo.starting_items` or `inventory.add_item()`.
- **New capability** (equip, gift, sell, ...): subclass `ItemComponent` and look it up with `item.get_component(MyComponent)`.
