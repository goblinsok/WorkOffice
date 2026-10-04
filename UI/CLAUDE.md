# UI

## Layers (`Scenes/base.tscn`)
```
LocationControl (world, layer 0)   world-container Controls use mouse_filter IGNORE
GameUi 10       top bar, toolbar, Menus/{Girls, Inventory, EmployeeCard, Job, Map}
InteractionMenu 15
CutsceneOverlay: ImageLayer 1 (stage image), InputLayer 25 (STOP blocker, click advances), SkipLayer 35 (Skip button, above DialogPanel); all hidden outside a cutscene
DialogPanel 30
BattleWindow 40
ScreenFader 100 (autoload)
```
**Input blocking is structural:** a visible full-screen Control with mouse_filter STOP (a menu root (the map included), the dialog root, the menu blocker, the fader, the battle root) stops world clicks. There are no global lock flags. Keep new overlays this way.

## Menus (`UI/Menus`)
- A menu inherits `base_menu.tscn` (`BaseMenu`), which provides the dim background, the window (theme variation `MenuWindow`), the title, closing on X, Esc or an outside click, and `open()`/`close()`/`toggle()`. Put UI under `%Content`. Refresh in `_on_open()` and disconnect live signals in `_on_close()`.
- `UI/Themes/menu.tres` is the shared theme (dark text on paper). Individual menus restyle the window with `theme_override_styles/panel` on `Window`.
- `GameUi.menu_buttons` maps toolbar buttons to menus (the Map button included), and only one menu is open at a time.
- A menu with its own look can extend `BaseMenu` without inheriting `base_menu.tscn`: the window/title/close/content nodes are optional, and it can override `_animate_open()`. `UI/Menu/map` does this (slide-down panel, no dim).
- Click-outside handlers must check `button_index` (left/right only): the mouse wheel also sends pressed `InputEventMouseButton`s.
- **Stats are hard-linked:** each stat has its own node wired up in the menu script. Don't generate stat UI generically. `UI/Components/stat_bar` is the reusable label + bar.
- `UI/Components/floating_text`: instance it, add it to a Control, then call `play(text, color, center)`.

## Drag & drop
Use the built-in `_get_drag_data` / `_can_drop_data` / `_drop_data` with a Dictionary payload `{type, ...}`. Drop targets walk up through parents only while children use mouse_filter PASS, not STOP. Examples: `UI/Menus/Job` (chips to zones) and `UI/Menus/Inventory` (slot to slot).

## Recipes
- **New menu:** create a scene inheriting `base_menu.tscn` with its content under `Content`, override `_on_open()`, instance it under `GameUi/Menus`, add a toolbar button to `game_ui.tscn`, and add an entry in `menu_buttons`.
- **Popup/overlay not based on BaseMenu:** use its own CanvasLayer at the right layer, with a full-rect root set to STOP while visible.
- Check layouts at 900x700 with a screenshot. Tall content goes in a ScrollContainer.
