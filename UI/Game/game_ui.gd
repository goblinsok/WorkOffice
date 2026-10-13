extends CanvasLayer
## HUD: top bar (money, date, actions) and the toolbar. menu_buttons maps each
## toolbar button to a BaseMenu (the map included), and only one menu is open at a time.

@onready var money_label: Label = %MoneyLabel
@onready var date_label: Label = %DateLabel
@onready var actions_label: Label = %ActionsLabel

@onready var wait_button: Button = %WaitButton
@onready var top_menu: Control = %TopMenu

## Toolbar button -> menu it toggles. Only one menu is open at a time.
@onready var menu_buttons: Dictionary[Button, BaseMenu] = {
	%MapButton: %Map,
	%GirlsButton: %GirlsMenu,
	%ItemsButton: %InventoryMenu,
	%CardButton: %EmployeeCard,
	%JobButton: %JobMenu,
}


func _ready() -> void:
	var player := GameState.player_stats
	player.money_update.connect(update_money)
	player.actions_changed.connect(update_actions)
	GlobalSignals.time_changed.connect(func(_day, _time): update_date())

	update_money()
	update_actions(player.actions, player.max_actions)
	update_date()

	for button in menu_buttons:
		button.pressed.connect(toggle_menu.bind(menu_buttons[button]))

	wait_button.pressed.connect(func(): TimeManager.spend_actions())

	# Cutscenes and the action minigame: only the top info bar stays; the toolbar and menus
	# (the map too) go away.
	GlobalSignals.cutscene_started.connect(func(_cutscene: CutsceneData): _set_toolbar_visible(false))
	GlobalSignals.cutscene_finished.connect(func(_cutscene: CutsceneData): _set_toolbar_visible(true))
	GlobalSignals.action_started.connect(func(_scene: ActionSceneData): _set_toolbar_visible(false))
	GlobalSignals.action_finished.connect(_set_toolbar_visible.bind(true))


func _set_toolbar_visible(shown: bool) -> void:
	top_menu.visible = shown
	if not shown:
		close_menus()


func toggle_menu(menu: BaseMenu) -> void:
	var was_open := menu.is_open()
	close_menus()
	if not was_open:
		menu.open()


func close_menus() -> void:
	for menu: BaseMenu in menu_buttons.values():
		menu.close()


func update_money() -> void:
	money_label.text = str(GameState.player_stats.money)


func update_actions(actions: int, max_actions: int) -> void:
	actions_label.text = "Actions: %s" % ("●".repeat(actions) + "○".repeat(max_actions - actions))


func update_date() -> void:
	var world := GameState.world_info
	date_label.text = "%s, %s" % [Enums.WEEK_STATE_NAMES[world.current_day], Enums.TIME_STATE_NAMES[world.current_time]]
