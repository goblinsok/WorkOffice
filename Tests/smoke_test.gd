extends Node

var failures := 0


func check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		failures += 1
		printerr("  FAIL ", msg)


func _ready() -> void:
	await get_tree().process_frame
	print("== Dialog parser")
	for path in ["res://Dialogs/lidya/talk.dlg", "res://Dialogs/nelle/talk.dlg"]:
		var d := DialogManager.get_dialog(path)
		check(d.is_valid(), "%s compiles %s" % [path, d.errors])
	var bad := DialogParser.new().parse("~ a\n=> nowhere\n  bad indent\nelse\n", "bad")
	check(bad.errors.size() == 3, "error detection: %s" % [bad.errors])

	var base: Node = load("res://Scenes/base.tscn").instantiate()
	add_child(base)
	await get_tree().process_frame

	print("== Placement")
	var world := GameState.world_info
	check(world.placements.size() == 2, "both girls placed: %s" % [world.placements.keys()])
	check(GameState.player_stats.actions == 3, "3 actions")
	var loc: BaseLocation = base.current_location
	check(loc.info.id == &"working_area", "starts in working area")

	# Force both girls into the working area so we can click them.
	var wa := GameState.locations.get_by_id(&"working_area")
	world.placements.clear()
	for poi_id in [&"desk_left", &"desk_right"]:
		var girl: GirlInfo = GameState.get_girls()[0 if poi_id == &"desk_left" else 1]
		var poi := wa.get_poi(poi_id)
		world.placements[girl.id] = GirlPlacement.new(girl, wa, poi, poi.get_setup_for(girl.id))
	GlobalSignals.girls_placed.emit()
	await get_tree().process_frame
	var view: BaseGirlLocation = loc.get_point(&"desk_left").girl_view
	check(view != null and view.get_girl().id == &"lidya", "lidya spawned at desk_left")
	check(view.animation_player.current_animation == "Standing", "animation Standing")

	print("== Interaction menu")
	var menu = base.get_node("InteractionMenu")
	GlobalSignals.girl_clicked.emit(view)
	check(menu.visible and menu.options_root.get_child_count() == 3, "menu open with 3 options")

	print("== Talk (dialog)")
	var talk: Button = menu.options_root.get_child(0)
	var lines: Array = []
	DialogManager.line_shown.connect(func(l: DialogLine): lines.append(l))
	var choices_seen: Array = []
	DialogManager.choices_shown.connect(func(c): choices_seen.append(c))
	talk.pressed.emit()
	await get_tree().process_frame
	check(DialogManager.is_active(), "dialog active")
	check(lines.size() == 1 and lines[0].speaker_name == "Lidya", "first line by Lidya: %s" % lines[0].text)
	DialogManager.advance()
	check(lines[-1].choices_follow, "line before menu flags choices_follow")
	DialogManager.advance()
	check(choices_seen.size() == 1 and choices_seen[0].size() == 2, "2 choices shown")
	DialogManager.choose(0)
	while DialogManager.is_active():
		DialogManager.advance()
	await get_tree().process_frame
	check(GameState.girls.get_by_id(&"lidya").affection == 1, "affection +1 from choice")
	check(GameState.player_stats.actions == 2, "action spent after talk")
	check(world.get_flag("met_lidya") == true, "flag set")

	print("== Reward")
	GlobalSignals.girl_clicked.emit(view)
	var reward: Button = menu.options_root.get_child(2)
	check(not reward.disabled, "reward enabled with $50")
	reward.pressed.emit()
	await get_tree().process_frame
	check(GameState.player_stats.money == 40, "money 40")
	check(GameState.girls.get_by_id(&"lidya").affection == 3, "affection 3")
	check(view.bubble_anchor.get_child_count() == 1, "bubble spawned")
	check(GameState.player_stats.actions == 1, "1 action left")

	print("== Look -> phase change")
	GlobalSignals.girl_clicked.emit(view)
	menu.options_root.get_child(1).pressed.emit()
	await get_tree().create_timer(1.5).timeout
	check(world.current_time == Enums.TIME_STATE.AFTERNOON, "afternoon now")
	check(GameState.player_stats.actions == 3, "actions refilled")
	check(base.get_node("GameUi").date_label.text == "MON, Afternoon", "date label: " + base.get_node("GameUi").date_label.text)

	print("== Day rollover")
	await TimeManager.advance_phase()
	await TimeManager.advance_phase()
	check(world.current_day == Enums.WEEK_STATE.TUESDAY and world.current_time == Enums.TIME_STATE.MORNING, "TUE morning")

	print("== Location switch")
	GlobalSignals.switch_location.emit(GameState.locations.get_by_id(&"gym"))
	await get_tree().create_timer(1.5).timeout
	check(base.current_location.info.id == &"gym", "moved to gym")
	check(world.current_location.id == &"gym", "world location gym")
	GlobalSignals.switch_location.emit(GameState.locations.get_by_id(&"kitchen"))
	await get_tree().create_timer(1.5).timeout
	check(base.current_location.info.id == &"gym", "kitchen unavailable -> stays")

	print("== Nelle dialog")
	var ctx := InteractionContext.new()
	ctx.girl = GameState.girls.get_by_id(&"nelle")
	lines.clear()
	DialogManager.start("res://Dialogs/nelle/talk.dlg", "", ctx)
	check(lines.size() == 1 and lines[0].text.begins_with("Hi! I'm Nelle"), "nelle first meeting: " + lines[0].text)
	DialogManager.advance()
	check(not DialogManager.is_active(), "=> END ends")

	await _test_inventory()
	_test_job_assignment()
	_test_simulation()
	await _test_menus(base)
	await _test_day_end_battle(base)

	print("\nRESULT: %s" % ("PASS" if failures == 0 else "%d FAILURES" % failures))
	get_tree().quit(failures)


func _item(id: String) -> ItemData:
	return load("res://Resources/Items/%s.tres" % id)


func _test_inventory() -> void:
	print("== Inventory")
	var inv := GameState.player_stats.inventory
	var soda := _item("energy_soda")
	var coffee := _item("coffee")
	check(inv.get_size() == 24, "24 slots")
	check(inv.count_of(soda) == 3 and inv.count_of(coffee) == 2, "starting items")
	check(soda.get_effect_text() == "Use on a girl: +30 Energy", "soda effect text: " + soda.get_effect_text())
	check(_item("screwdriver").get_effect_text().begins_with("Key item"), "override effect text")
	check(inv.add_item(soda, 20) == 0 and inv.count_of(soda) == 23, "stacks split at max_stack 10")
	inv.remove_item(soda, 100)
	inv.add_item(soda, 3)

	var nelle := GameState.girls.get_by_id(&"nelle")
	nelle.set_stat(&"energy", 50)
	var soda_index := -1
	for i in inv.get_size():
		if inv.get_slot_stack(i) and inv.get_slot_stack(i).item == soda:
			soda_index = i
	check(not await inv.use_at(soda_index, InteractionContext.new()), "soda needs a girl")
	check(await inv.use_at(soda_index, InteractionContext.new().with_girl(nelle)), "soda used on Nelle")
	check(nelle.energy == 80 and inv.count_of(soda) == 2, "energy 80, 2 sodas left")
	nelle.set_stat(&"energy", 100)
	check(not await inv.use_at(soda_index, InteractionContext.new().with_girl(nelle)), "soda blocked at full energy")

	var coffee_index := 0
	for i in inv.get_size():
		if inv.get_slot_stack(i) and inv.get_slot_stack(i).item == coffee:
			coffee_index = i
	check(not await inv.use_at(coffee_index, InteractionContext.new()), "coffee blocked at full actions")
	GameState.player_stats.actions = 1
	check(await inv.use_at(coffee_index, InteractionContext.new()), "coffee used")
	check(GameState.player_stats.actions == 2, "+1 action")
	GameState.player_stats.refill_actions()

	inv.move(0, 23)
	check(inv.get_slot_stack(0) == null and inv.get_slot_stack(23) != null, "move to empty slot")
	inv.move(23, 0)


func _test_job_assignment() -> void:
	print("== Job assignment")
	var job := JobManager.get_current_job()
	check(job != null and job.id == &"repairing_old_pc", "current job")
	check(job.get_total_attack() == 25, "attack 20 + Overheating 5")
	job.assign(&"lidya", 0)
	job.assign(&"nelle", 1)
	check(job.get_slot(0) == &"lidya" and job.get_slot(1) == &"nelle", "assigned to slots")
	job.assign(&"lidya", 1)
	check(job.get_slot(0) == &"nelle" and job.get_slot(1) == &"lidya", "swap")
	job.unassign(&"nelle")
	check(not job.is_assigned(&"nelle") and job.get_assigned_girls(GameState.girls).size() == 1, "unassign")
	job.assign(&"nelle", 2)
	check(job.get_assigned_girls(GameState.girls).size() == 2, "2 assigned")


func _test_simulation() -> void:
	print("== Battle simulation")
	var job := JobManager.get_current_job()
	var girls := job.get_assigned_girls(GameState.girls)
	for girl in girls:
		girl.restore_energy()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var sim := BattleSimulation.new(job, girls, rng)
	var events := sim.run()
	check(events[0].type == BattleEvent.Type.BATTLE_START, "starts")
	var boss_attacks := events.filter(func(e: BattleEvent) -> bool: return e.type == BattleEvent.Type.BOSS_ATTACK).size()
	check(boss_attacks == 1, "boss attacks exactly once")
	var first_girl_attack := events.find_custom(func(e: BattleEvent) -> bool: return e.type == BattleEvent.Type.GIRL_ATTACK)
	var boss_attack := events.find_custom(func(e: BattleEvent) -> bool: return e.type == BattleEvent.Type.BOSS_ATTACK)
	check(boss_attack < first_girl_attack, "boss hits first")
	# Lidya: 100 - 25 = 75 energy, 15 per attack -> 5 attacks. Nelle: 75 / 20 -> 3 attacks.
	var attacks := {}
	for e in events:
		if e.type == BattleEvent.Type.GIRL_ATTACK:
			var id: StringName = sim.units[e.unit].girl.id
			attacks[id] = attacks.get(id, 0) + 1
	check(attacks.get(&"lidya") == 5 and attacks.get(&"nelle") == 3, "attack counts %s" % [attacks])
	check(sim.units.all(func(u: BattleUnit) -> bool: return u.exhausted), "everyone exhausted")
	check(not sim.victory and sim.boss_hp == 150 - sim.total_damage, "hp %d after %d dmg" % [sim.boss_hp, sim.total_damage])
	var abilities := events.filter(func(e: BattleEvent) -> bool: return e.type == BattleEvent.Type.ABILITY).size()
	check(abilities >= 1, "placeholder ability logged")
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 42
	var sim2 := BattleSimulation.new(job, girls, rng2)
	sim2.run()
	check(sim2.total_damage == sim.total_damage, "deterministic with seed")
	check(job.hp == 150, "simulation has no side effects before apply")


func _test_menus(base: Node) -> void:
	print("== Menus")
	var ui = base.get_node("GameUi")
	for button: Button in ui.menu_buttons:
		button.pressed.emit()
		await get_tree().process_frame
		check(ui.menu_buttons[button].is_open(), "%s opens" % ui.menu_buttons[button].name)
	check(ui.menu_buttons.values().filter(func(m: BaseMenu) -> bool: return m.is_open()).size() == 1, "only one menu open")
	var girls_menu = ui.get_node("%GirlsMenu")
	ui.toggle_menu(girls_menu)
	await get_tree().process_frame
	check(girls_menu.tabs.get_child_count() == 3, "2 bookmarks + template")
	check(girls_menu.name_label.text == "LIDYA", "first page Lidya")
	girls_menu.tabs.get_child(2).pressed.emit()
	check(girls_menu.name_label.text == "NELLE", "tab switches page")
	var inv_menu = ui.get_node("%InventoryMenu")
	ui.toggle_menu(inv_menu)
	await get_tree().process_frame
	check(inv_menu.grid.get_child_count() == 24, "24 slot views")
	var job_menu = ui.get_node("%JobMenu")
	ui.toggle_menu(job_menu)
	await get_tree().process_frame
	check(job_menu.slots_row.get_child_count() == 3, "3 assignment slots")
	check(job_menu.pool_zone.chips.get_child_count() == 0, "no free girls in pool")
	job_menu._on_girl_dropped(&"nelle", GirlDropZone.POOL)
	await get_tree().process_frame
	check(job_menu.pool_zone.chips.get_child_count() == 1, "drop to pool unassigns")
	job_menu._on_girl_dropped(&"nelle", 0)
	await get_tree().process_frame
	check(JobManager.get_current_job().get_slot(0) == &"nelle", "drop to slot assigns")
	ui.close_menus()


func _test_day_end_battle(base: Node) -> void:
	print("== Day-end battle")
	var world := GameState.world_info
	var job := JobManager.get_current_job()
	var window = base.get_node("BattleWindow")
	Engine.time_scale = 20.0
	var day := world.current_day
	world.current_time = Enums.TIME_STATE.EVENING
	var shown := [false]
	JobManager.battle_started.connect(func(_b): shown[0] = true, CONNECT_ONE_SHOT)
	await TimeManager.spend_actions(3)
	check(shown[0], "battle window shown")
	check(not window.visible, "window closed afterwards")
	check(world.current_day == (day + 1) % 7 and world.current_time == Enums.TIME_STATE.MORNING, "new day started")
	check(job.hp < 150 and not job.completed, "boss HP persists: %d" % job.hp)
	check(GameState.get_girls().all(func(g: GirlInfo) -> bool: return g.energy == g.max_energy), "energy restored overnight")

	print("== Victory")
	var money := GameState.player_stats.money
	job.set_hp(5)
	world.current_time = Enums.TIME_STATE.EVENING
	await TimeManager.spend_actions(3)
	check(job.completed and job.hp == 0, "job completed")
	check(GameState.player_stats.money == money + 100, "reward paid")
	check(JobManager.get_current_job() == null, "no more jobs")
	world.current_time = Enums.TIME_STATE.EVENING
	shown[0] = false
	JobManager.battle_started.connect(func(_b): shown[0] = true, CONNECT_ONE_SHOT)
	await TimeManager.spend_actions(3)
	check(not shown[0], "no battle without a job")
	Engine.time_scale = 1.0
