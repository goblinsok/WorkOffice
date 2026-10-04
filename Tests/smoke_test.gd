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
	check(loc.info.id == Ids.Location.WORKING_AREA, "starts in working area")

	# Force both girls into the working area so we can click them.
	var wa := GameState.locations.get_by_id(Ids.Location.WORKING_AREA)
	world.placements.clear()
	for poi_id: Ids.Poi in [Ids.Poi.WORKING_AREA_DESK_LEFT, Ids.Poi.WORKING_AREA_DESK_RIGHT]:
		var girl: GirlInfo = GameState.get_girls()[0 if poi_id == Ids.Poi.WORKING_AREA_DESK_LEFT else 1]
		var poi := wa.get_poi(poi_id)
		world.placements[girl.id] = GirlPlacement.new(girl, wa, poi, poi.get_setups_for(girl.id)[0])
	GlobalSignals.girls_placed.emit()
	await get_tree().process_frame
	var view: BaseGirlLocation = loc.get_point(Ids.Poi.WORKING_AREA_DESK_LEFT).girl_view
	check(view != null and view.get_girl().id == Ids.Girl.LIDYA, "lidya spawned at desk_left")
	check(view.animation_player.current_animation == "Standing", "animation Standing")

	print("== Interaction menu")
	var menu = base.get_node("InteractionMenu")
	GlobalSignals.girl_clicked.emit(view)
	check(menu.visible and menu.options_root.get_child_count() == 3, "menu open with 3 options")
	var ids := InteractionManager.get_visible_interactions(InteractionContext.new(view)).map(func(i: InteractionData) -> StringName: return i.id)
	check(ids == [&"lidya_talk", &"lidya_look", &"lidya_reward"], "Lidya's own Talk/Look + desk extra Reward: %s" % [ids])

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
	check(GameState.girls.get_by_id(Ids.Girl.LIDYA).affection == 1, "affection +1 from choice")
	check(GameState.player_stats.actions == 2, "action spent after talk")
	check(world.get_flag("met_lidya") == true, "flag set")

	print("== Reward")
	GlobalSignals.girl_clicked.emit(view)
	var reward: Button = menu.options_root.get_child(2)
	check(not reward.disabled, "reward enabled with $50")
	reward.pressed.emit()
	await get_tree().process_frame
	check(GameState.player_stats.money == 40, "money 40")
	check(GameState.girls.get_by_id(Ids.Girl.LIDYA).affection == 3, "affection 3")
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
	GlobalSignals.switch_location.emit(GameState.locations.get_by_id(Ids.Location.GYM))
	await get_tree().create_timer(1.5).timeout
	check(base.current_location.info.id == Ids.Location.GYM, "moved to gym")
	check(world.current_location.id == Ids.Location.GYM, "world location gym")
	GlobalSignals.switch_location.emit(GameState.locations.get_by_id(Ids.Location.KITCHEN))
	await get_tree().create_timer(1.5).timeout
	check(base.current_location.info.id == Ids.Location.GYM, "kitchen unavailable -> stays")

	print("== Nelle dialog")
	var ctx := InteractionContext.new()
	ctx.girl = GameState.girls.get_by_id(Ids.Girl.NELLE)
	lines.clear()
	DialogManager.start("res://Dialogs/nelle/talk.dlg", "", ctx)
	check(lines.size() == 1 and lines[0].text.begins_with("Hi! I'm Nelle"), "nelle first meeting: " + lines[0].text)
	DialogManager.advance()
	check(not DialogManager.is_active(), "=> END ends")

	_test_ids_and_validator()
	await _test_inventory()
	_test_job_assignment()
	_test_simulation()
	await _test_menus(base)
	_test_conditions()
	_test_placement_rules()
	_test_ui_input(base)
	await _test_day_end_battle(base)
	await _test_cutscene(base)
	await _test_affection_cutscene()

	print("\nRESULT: %s" % ("PASS" if failures == 0 else "%d FAILURES" % failures))
	get_tree().quit(failures)


func _test_ids_and_validator() -> void:
	print("== Ids and content validator")
	check(Ids.girl_from_key("Lidya") == Ids.Girl.LIDYA and Ids.girl_from_key("bob") == Ids.Girl.NONE, "girl_from_key")
	check(Ids.girl_key(Ids.Girl.NELLE) == "nelle", "girl_key")
	check(Ids.poi_location(Ids.Poi.GYM_MATS) == Ids.Location.GYM, "poi_location")
	check(Ids.poi_label(Ids.Poi.WORKING_AREA_DESK_LEFT) == "Desk Left", "poi_label: " + Ids.poi_label(Ids.Poi.WORKING_AREA_DESK_LEFT))
	check(Ids.stat_from_name("affection") == Ids.Stat.AFFECTION and Ids.stat_property(Ids.Stat.ENERGY) == &"energy", "stat helpers")

	var problems := ContentValidator.validate(GameState.girls, GameState.locations, GameState.cutscenes)
	check(problems.is_empty(), "shipped content is valid: %s" % [problems])

	# A staging at a POI of another location, and a girl setup without a girl.
	var bad := CutsceneData.new()
	bad.id = &"temp_bad"
	bad.trigger_after_action = true
	var step := CutsceneBackgroundStep.new()
	step.location = GameState.locations.get_by_id(Ids.Location.GYM)
	step.girls = [_staging(Ids.Girl.LIDYA, Ids.Poi.WORKING_AREA_DESK_LEFT)] as Array[CutsceneGirlStaging]
	bad.steps = [step] as Array[CutsceneStep]
	GameState.cutscenes.cutscenes.append(bad)
	var mats := GameState.locations.get_by_id(Ids.Location.GYM).get_poi(Ids.Poi.GYM_MATS)
	var empty_setup := PoiGirlSetup.new()
	mats.girl_setups.append(empty_setup)
	problems = ContentValidator.validate(GameState.girls, GameState.locations, GameState.cutscenes)
	GameState.cutscenes.cutscenes.erase(bad)
	mats.girl_setups.erase(empty_setup)
	check(problems.size() == 2, "2 problems reported: %s" % [problems])
	check(Array(problems).any(func(p: String) -> bool: return p.contains("WORKING_AREA_DESK_LEFT") and p.contains("not in location GYM")), "wrong-location staging reported")
	check(Array(problems).any(func(p: String) -> bool: return p.contains("GYM_MATS") and p.contains("NONE")), "setup without girl reported")

	var source := "Lydia: hi\ndo add_stat(\"afection\", 1)\nBoss: hi\nLidya: ok\n"
	var dialog_problems := ContentValidator.validate_dialog(DialogParser.new().parse(source, "temp"))
	check(dialog_problems.size() == 2, "dialog: typo speaker + unknown stat only: %s" % [dialog_problems])

	# The staging POI dropdown lists only the step location's points.
	var hint := ""
	for property in step.girls[0].get_property_list():
		if property.name == "poi":
			hint = property.hint_string
	check(hint.contains("GYM_TREADMILL") and hint.contains("GYM_MATS") and not hint.contains("WORKING_AREA"), "poi dropdown filtered: " + hint)


func _staging(girl: Ids.Girl, poi: Ids.Poi, animation: StringName = &"Standing") -> CutsceneGirlStaging:
	var staging := CutsceneGirlStaging.new()
	staging.girl = girl
	staging.poi = poi
	staging.animation = animation
	return staging


## Staged gym (Lidya jumping at the treadmill) -> part1 (chained) -> full-screen image -> part2.
func _make_test_cutscene() -> CutsceneData:
	var cutscene := CutsceneData.new()
	cutscene.id = &"temp_smoke"
	var stage := CutsceneBackgroundStep.new()
	stage.location = GameState.locations.get_by_id(Ids.Location.GYM)
	stage.girls = [_staging(Ids.Girl.LIDYA, Ids.Poi.GYM_TREADMILL, &"Jumping")] as Array[CutsceneGirlStaging]
	var part1 := CutsceneDialogStep.new()
	part1.dialog_path = "res://Dialogs/cutscenes/example.dlg"
	part1.label = "part1"
	part1.wait_for_click = false
	var image := CutsceneBackgroundStep.new()
	image.image = GameState.girls.get_by_id(Ids.Girl.LIDYA).portrait
	var part2 := CutsceneDialogStep.new()
	part2.dialog_path = "res://Dialogs/cutscenes/example.dlg"
	part2.label = "part2"
	cutscene.steps = [stage, part1, image, part2] as Array[CutsceneStep]
	return cutscene


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

	var nelle := GameState.girls.get_by_id(Ids.Girl.NELLE)
	nelle.set_stat(Ids.Stat.ENERGY, 50)
	var soda_index := -1
	for i in inv.get_size():
		if inv.get_slot_stack(i) and inv.get_slot_stack(i).item == soda:
			soda_index = i
	check(not await inv.use_at(soda_index, InteractionContext.new()), "soda needs a girl")
	check(await inv.use_at(soda_index, InteractionContext.new().with_girl(nelle)), "soda used on Nelle")
	check(nelle.energy == 80 and inv.count_of(soda) == 2, "energy 80, 2 sodas left")
	nelle.set_stat(Ids.Stat.ENERGY, 100)
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
	check(job.get_slot(0) == Ids.Girl.NONE and not job.is_assigned(Ids.Girl.NONE), "empty slots are NONE")
	job.assign(Ids.Girl.LIDYA, 0)
	job.assign(Ids.Girl.NELLE, 1)
	check(job.get_slot(0) == Ids.Girl.LIDYA and job.get_slot(1) == Ids.Girl.NELLE, "assigned to slots")
	job.assign(Ids.Girl.LIDYA, 1)
	check(job.get_slot(0) == Ids.Girl.NELLE and job.get_slot(1) == Ids.Girl.LIDYA, "swap")
	job.unassign(Ids.Girl.NELLE)
	check(not job.is_assigned(Ids.Girl.NELLE) and job.get_assigned_girls(GameState.girls).size() == 1, "unassign")
	job.assign(Ids.Girl.NONE, 2)
	check(job.get_slot(2) == Ids.Girl.NONE, "NONE can't be assigned")
	job.assign(Ids.Girl.NELLE, 2)
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
			var id: Ids.Girl = sim.units[e.unit].girl.id
			attacks[id] = attacks.get(id, 0) + 1
	check(attacks.get(Ids.Girl.LIDYA) == 5 and attacks.get(Ids.Girl.NELLE) == 3, "attack counts %s" % [attacks])
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
	job_menu._on_girl_dropped(Ids.Girl.NELLE, GirlDropZone.POOL)
	await get_tree().process_frame
	check(job_menu.pool_zone.chips.get_child_count() == 1, "drop to pool unassigns")
	job_menu._on_girl_dropped(Ids.Girl.NELLE, 0)
	await get_tree().process_frame
	check(JobManager.get_current_job().get_slot(0) == Ids.Girl.NELLE, "drop to slot assigns")
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


func _test_conditions() -> void:
	print("== Typed conditions")
	var player := GameState.player_stats
	var money := player.money
	var has_10 := PlayerStatCondition.new()
	has_10.stat = Ids.PlayerStat.MONEY
	has_10.amount = 10
	player.money = 9
	check(not has_10.is_met(null), "money 9: AT_LEAST 10 not met")
	player.money = 10
	check(has_10.is_met(null), "money 10: AT_LEAST 10 met")
	player.money = money

	var spent_action := PlayerStatCondition.new()
	spent_action.stat = Ids.PlayerStat.ACTIONS
	spent_action.comparison = InteractionCondition.Comparison.BELOW_MAX
	player.refill_actions()
	check(not spent_action.is_met(null), "actions full: BELOW_MAX not met")
	player.actions -= 1
	check(spent_action.is_met(null), "action spent: BELOW_MAX met")
	player.refill_actions()

	var nelle := GameState.girls.get_by_id(Ids.Girl.NELLE)
	var tired := GirlStatCondition.new()
	tired.stat = Ids.Stat.ENERGY
	tired.comparison = InteractionCondition.Comparison.BELOW_MAX
	var nelle_ctx := InteractionContext.new().with_girl(nelle)
	nelle.restore_energy()
	check(not tired.is_met(nelle_ctx), "full energy: BELOW_MAX not met")
	nelle.set_stat(Ids.Stat.ENERGY, 40)
	check(tired.is_met(nelle_ctx) and not tired.is_met(InteractionContext.new()), "context girl used, none -> not met")
	var low := GirlStatCondition.new()
	low.stat = Ids.Stat.ENERGY
	low.comparison = InteractionCondition.Comparison.AT_MOST
	low.amount = 40
	check(low.is_met(nelle_ctx), "AT_MOST 40 met at 40")
	nelle.restore_energy()

	var world := GameState.world_info
	var time := world.current_time
	var evening := TimeCondition.new()
	evening.phases = 1 << Enums.TIME_STATE.EVENING
	world.current_time = Enums.TIME_STATE.MORNING
	check(not evening.is_met(null) and TimeCondition.new().is_met(null), "evening-only fails in the morning; empty = any")
	world.current_time = Enums.TIME_STATE.EVENING
	check(evening.is_met(null), "evening-only met in the evening")
	world.current_time = time


func _test_placement_rules() -> void:
	print("== Placement rules")
	var world := GameState.world_info
	var time := world.current_time
	var lidya := GameState.girls.get_by_id(Ids.Girl.LIDYA)
	var nelle := GameState.girls.get_by_id(Ids.Girl.NELLE)
	var gym := GameState.locations.get_by_id(Ids.Location.GYM)
	var treadmill := gym.get_poi(Ids.Poi.GYM_TREADMILL)
	var mats := gym.get_poi(Ids.Poi.GYM_MATS)
	var evening := TimeCondition.new()
	evening.phases = 1 << Enums.TIME_STATE.EVENING

	# Several setups for one girl at one point; conditions decide which are available.
	var night_setup := PoiGirlSetup.new()
	night_setup.girl = Ids.Girl.LIDYA
	night_setup.animation = &"Jumping"
	night_setup.conditions = [evening] as Array[InteractionCondition]
	mats.girl_setups.append(night_setup)
	world.current_time = Enums.TIME_STATE.MORNING
	check(mats.get_setups_for(Ids.Girl.LIDYA).size() == 2 and mats.get_available_setups(lidya, gym).size() == 1, "morning: evening setup unavailable")
	world.current_time = Enums.TIME_STATE.EVENING
	check(mats.get_available_setups(lidya, gym).size() == 2, "evening: both setups available")
	mats.girl_setups.erase(night_setup)

	# A point where all of a girl's setups fail is not a candidate.
	var nelle_treadmill := treadmill.get_setups_for(Ids.Girl.NELLE)[0]
	nelle_treadmill.conditions = [evening] as Array[InteractionCondition]
	world.current_time = Enums.TIME_STATE.MORNING
	var scheduler := GirlScheduler.new()
	var pois := scheduler._get_candidates(nelle, GameState.locations.locations).map(func(p: GirlPlacement) -> PoiInfo: return p.poi)
	check(not treadmill in pois and mats in pois, "morning: Nelle can't be at the treadmill")
	world.current_time = Enums.TIME_STATE.EVENING
	pois = scheduler._get_candidates(nelle, GameState.locations.locations).map(func(p: GirlPlacement) -> PoiInfo: return p.poi)
	check(treadmill in pois, "evening: Nelle can be at the treadmill")
	nelle_treadmill.conditions = [] as Array[InteractionCondition]
	world.current_time = time

	# Girls always move to another point when one is free.
	var saved := world.placements.duplicate()
	var always_moved := true
	var always_placed := true
	for i in 30:
		var next := scheduler.schedule(GameState.get_girls(), GameState.locations.locations, world)
		always_placed = always_placed and next.size() == 2
		for girl_id in next:
			if world.placements.has(girl_id) and world.placements[girl_id].poi == next[girl_id].poi:
				always_moved = false
		world.placements = next
	check(always_placed and always_moved, "30 phases: every girl placed and moved every time")
	world.placements = saved


func _test_ui_input(base: Node) -> void:
	print("== UI input")
	var ui = base.get_node("GameUi")
	var girls_menu: BaseMenu = ui.get_node("%GirlsMenu")
	var map: BaseMenu = ui.get_node("%Map")
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true

	ui.toggle_menu(girls_menu)
	girls_menu._on_background_input(wheel)
	check(girls_menu.is_open(), "mouse wheel doesn't close a menu")
	girls_menu._on_background_input(click)
	check(not girls_menu.is_open(), "click outside closes a menu")

	var map_button: Button = ui.get_node("%MapButton")
	map_button.pressed.emit()
	check(map.is_open() and not map_button.disabled, "map button opens the map (button stays enabled)")
	map._on_background_input(wheel)
	check(map.is_open(), "mouse wheel doesn't close the map")
	ui.get_node("%GirlsButton").pressed.emit()
	check(girls_menu.is_open() and not map.is_open(), "opening a menu closes the map")
	map_button.pressed.emit()
	check(map.is_open() and not girls_menu.is_open(), "opening the map closes the menu")
	map_button.pressed.emit()
	check(not map.is_open(), "map button toggles the map closed")
	map_button.pressed.emit()
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	map._unhandled_input(esc)
	check(not map.is_open(), "Esc closes the map")
	map_button.pressed.emit()
	map._on_background_input(click)
	check(not map.is_open(), "click outside closes the map")


func _wait_for(cond: Callable, timeout_sec: float = 10.0) -> bool:
	var start := Time.get_ticks_msec()
	while not cond.call():
		if Time.get_ticks_msec() - start > timeout_sec * 1000.0:
			return false
		await get_tree().process_frame
	return true


func _test_cutscene(base: Node) -> void:
	print("== Cutscene")
	Engine.time_scale = 10.0
	GameState.player_stats.refill_actions()
	var ui = base.get_node("GameUi")
	var overlay = base.get_node("CutsceneOverlay")
	var world := GameState.world_info
	var real_location := world.current_location
	var example := _make_test_cutscene()
	check(GameState.cutscenes.cutscenes.size() == 1 and GameState.cutscenes.cutscenes[0].id == &"example", "repo has the example cutscene")

	var result: Array = [null]
	var ctx := InteractionContext.new().with_girl(GameState.girls.get_by_id(Ids.Girl.LIDYA))
	(func() -> void: result[0] = await CutsceneManager.play(example, ctx)).call()
	check(CutsceneManager.is_playing(), "cutscene playing")
	var dialog_up := await _wait_for(func() -> bool: return DialogManager.is_active())
	check(dialog_up, "part1 dialog active after the staged background")
	check(not ui.get_node("%TopMenu").visible, "toolbar hidden")
	check(ui.get_node("VBoxContainer/TopInfo").visible, "top info bar visible")
	check(overlay.blocker.is_visible_in_tree() and overlay.skip_button.is_visible_in_tree(), "blocker and skip button visible")
	check(base.current_location.info.id == Ids.Location.GYM, "staged gym shown")
	var staged_view: BaseGirlLocation = base.current_location.get_point(Ids.Poi.GYM_TREADMILL).girl_view
	check(staged_view != null and staged_view.get_girl().id == Ids.Girl.LIDYA, "lidya staged at treadmill")
	check(staged_view != null and staged_view.animation_player.current_animation == "Jumping", "staged animation Jumping")
	check(world.current_location == real_location, "world location unchanged while staged")
	check(not ui.get_node("%GirlsMenu").is_open(), "no menu open")

	while DialogManager.is_active():
		DialogManager.advance()
	await get_tree().process_frame
	check(CutsceneManager.is_playing() and CutsceneManager.is_waiting_for_click(), "after part1: still playing, waiting for click")
	CutsceneManager.advance()
	var image_up := await _wait_for(func() -> bool: return overlay.image_layer.visible and overlay.stage_image.texture != null)
	check(image_up, "image step shows the stage image")
	check(await _wait_for(func() -> bool: return CutsceneManager.is_waiting_for_click()), "waits for click after image")
	CutsceneManager.advance()
	check(await _wait_for(func() -> bool: return DialogManager.is_active()), "part2 dialog active")
	while DialogManager.is_active():
		DialogManager.advance()
	check(await _wait_for(func() -> bool: return not CutsceneManager.is_playing() and result[0] != null), "cutscene ended")
	check(ui.get_node("%TopMenu").visible, "toolbar visible again")
	check(not overlay.blocker.is_visible_in_tree() and not overlay.image_layer.visible, "overlay hidden again")
	check(base.current_location.info == real_location and world.current_location == real_location, "location restored")
	check(world.get_flag(example.seen_flag()) == true, "seen flag set")

	# Skip right away, and skip in the middle of a dialog.
	result[0] = null
	(func() -> void: result[0] = await CutsceneManager.play(example)).call()
	CutsceneManager.skip()
	check(await _wait_for(func() -> bool: return not CutsceneManager.is_playing() and result[0] != null), "skip ends the cutscene")
	check(result[0] == true and not DialogManager.is_active(), "skip: proceed, no dialog")
	check(base.current_location.info == real_location, "skip: location restored")
	result[0] = null
	(func() -> void: result[0] = await CutsceneManager.play(example)).call()
	await _wait_for(func() -> bool: return DialogManager.is_active())
	CutsceneManager.skip()
	check(await _wait_for(func() -> bool: return not CutsceneManager.is_playing() and result[0] != null), "skip during dialog ends the cutscene")
	check(result[0] == true and not DialogManager.is_active(), "skip during dialog: no dialog left")
	check(base.current_location.info == real_location, "skip during dialog: location restored")

	# Trigger before an interaction.
	var temp := CutsceneData.new()
	temp.id = &"temp_talk"
	temp.trigger_interaction = load("res://Resources/Interactions/lidya/talk.tres")
	temp.cancels_action = true
	var step := CutsceneDialogStep.new()
	step.dialog_path = "res://Dialogs/cutscenes/example.dlg"
	step.label = "part1"
	temp.steps = [step] as Array[CutsceneStep]
	GameState.cutscenes.cutscenes.append(temp)
	var talk: InteractionData = load("res://Resources/Interactions/lidya/talk.tres")
	var actions := GameState.player_stats.actions
	var done := [false]
	var talk_ctx := InteractionContext.new().with_girl(GameState.girls.get_by_id(Ids.Girl.LIDYA))
	(func() -> void:
		await InteractionManager.run(talk, talk_ctx)
		done[0] = true).call()
	check(CutsceneManager.is_playing(), "talk triggers the cutscene")
	check(await _wait_for(func() -> bool: return DialogManager.is_active()), "cutscene dialog active")
	check(not InteractionManager.can_interact(), "no interaction during a cutscene")
	CutsceneManager.skip()
	check(await _wait_for(func() -> bool: return done[0]), "run() returned after skip")
	check(GameState.player_stats.actions == actions, "cancelled: no actions spent")
	check(not DialogManager.is_active() and not InteractionManager.is_busy, "cancelled: no dialog, not busy")
	done[0] = false
	(func() -> void:
		await InteractionManager.run(talk, talk_ctx)
		done[0] = true).call()
	await get_tree().process_frame
	check(not CutsceneManager.is_playing() and DialogManager.is_active(), "play_once: talk dialog starts")
	DialogManager.stop()
	check(await _wait_for(func() -> bool: return done[0]), "talk settled")
	check(GameState.player_stats.actions == actions - 1, "talk spent its action")
	GameState.cutscenes.cutscenes.erase(temp)
	check(not temp in GameState.cutscenes.cutscenes, "temporary cutscene removed")

	# A staged cutscene frees the world views: the context must be re-pointed to the new view.
	var lidya := GameState.girls.get_by_id(Ids.Girl.LIDYA)
	var real_info: LocationInfo = base.current_location.info
	var spot: PoiInfo = null
	for poi in real_info.points_of_interest:
		if not poi.get_setups_for(Ids.Girl.LIDYA).is_empty():
			spot = poi
	world.placements.clear()
	world.placements[lidya.id] = GirlPlacement.new(lidya, real_info, spot, spot.get_setups_for(Ids.Girl.LIDYA)[0])
	GlobalSignals.girls_placed.emit()
	await get_tree().process_frame
	var old_view: BaseGirlLocation = base.current_location.get_point(spot.id).girl_view
	check(old_view != null and old_view.is_in_group(&"girl_views"), "real view is in group girl_views")
	var rctx := InteractionContext.new(old_view)
	var reward: InteractionData = load("res://Resources/Interactions/lidya/reward.tres")
	var stale := CutsceneData.new()
	stale.id = &"temp_reward"
	stale.trigger_interaction = load("res://Resources/Interactions/lidya/reward.tres")
	stale.cancels_action = false
	var stage := CutsceneBackgroundStep.new()
	stage.location = GameState.locations.get_by_id(Ids.Location.GYM)
	stage.fade = false
	stage.girls = [_staging(Ids.Girl.LIDYA, Ids.Poi.GYM_TREADMILL)] as Array[CutsceneGirlStaging]
	var line := CutsceneDialogStep.new()
	line.dialog_path = "res://Dialogs/cutscenes/example.dlg"
	line.label = "part1"
	line.wait_for_click = false
	stale.steps = [stage, line] as Array[CutsceneStep]
	GameState.cutscenes.cutscenes.append(stale)
	GameState.player_stats.money += 100
	var money := GameState.player_stats.money
	done[0] = false
	(func() -> void:
		await InteractionManager.run(reward, rctx)
		done[0] = true).call()
	check(await _wait_for(func() -> bool: return DialogManager.is_active()), "reward cutscene dialog active")
	check(get_tree().get_nodes_in_group(&"girl_views").size() == 0, "staged views are not in group girl_views")
	while DialogManager.is_active():
		DialogManager.advance()
	check(await _wait_for(func() -> bool: return done[0]), "reward run() finished")
	check(GameState.player_stats.money == money - 10, "reward proceeded: money -10")
	check(is_instance_valid(rctx.view) and rctx.view != old_view, "context view re-pointed to the new view")
	check(rctx.view != null and rctx.view.bubble_anchor.get_child_count() == 1, "bubble spawned on the new view")
	GameState.cutscenes.cutscenes.erase(stale)
	GameState.player_stats.refill_actions()
	Engine.time_scale = 1.0


func _test_affection_cutscene() -> void:
	print("== After-action cutscene (Nelle affection 10)")
	Engine.time_scale = 10.0
	var example: CutsceneData = load("res://Resources/Cutscenes/example_cutscene.tres")
	var world := GameState.world_info
	var inv := GameState.player_stats.inventory
	var chocolate := _item("chocolate_box")
	inv.add_item(chocolate, 3)
	var nelle := GameState.girls.get_by_id(Ids.Girl.NELLE)
	var lidya := GameState.girls.get_by_id(Ids.Girl.LIDYA)
	var use_chocolate := func(girl: GirlInfo) -> void:
		for i in inv.get_size():
			if inv.get_slot_stack(i) and inv.get_slot_stack(i).item == chocolate:
				await inv.use_at(i, InteractionContext.new().with_girl(girl))
				return

	lidya.set_stat(Ids.Stat.AFFECTION, 15)
	nelle.set_stat(Ids.Stat.AFFECTION, 8)
	await use_chocolate.call(nelle)
	check(nelle.affection == 9 and not CutsceneManager.is_playing(), "affection 9: no cutscene (Lidya's 15 doesn't count)")

	var done := [false]
	(func() -> void:
		await use_chocolate.call(nelle)
		done[0] = true).call()
	check(nelle.affection == 10, "affection 10")
	check(CutsceneManager.is_playing() and CutsceneManager.current == example, "example cutscene plays after the item use")
	CutsceneManager.skip()
	check(await _wait_for(func() -> bool: return done[0]), "item use finished after the cutscene")
	check(world.get_flag(example.seen_flag()) == true, "seen flag set")

	await use_chocolate.call(nelle)
	check(nelle.affection == 11 and not CutsceneManager.is_playing(), "play_once: no replay at 11")
	Engine.time_scale = 1.0
