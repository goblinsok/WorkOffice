extends Node
## JobManager: runs the end-of-day boss battle for the current job.
## The battle is simulated first (BattleSimulation). A view (UI/Battle/battle_window)
## listens to battle_started, plays the events back, and calls finish_presentation().
## Without a view (tests, headless), results are applied right away.

signal battle_started(battle: BattleSimulation)
signal battle_finished(battle: BattleSimulation)
signal job_completed(job: JobData)
signal _presentation_finished()

var is_battle_running: bool = false


func _ready() -> void:
	TimeManager.register_day_end_step(run_day_end_battle)


func get_current_job() -> JobData:
	return GameState.jobs.get_current()


func run_day_end_battle() -> void:
	var job := get_current_job()
	if job == null:
		return
	var girls := job.get_assigned_girls(GameState.girls)
	if girls.is_empty():
		return
	await run_battle(job, girls)


func run_battle(job: JobData, girls: Array[GirlInfo], rng: RandomNumberGenerator = null) -> BattleSimulation:
	var battle := BattleSimulation.new(job, girls, rng)
	battle.run()

	is_battle_running = true
	var has_view := not battle_started.get_connections().is_empty()
	battle_started.emit(battle)
	if has_view:
		await _presentation_finished

	battle.apply_results()
	if battle.victory:
		_complete_job(job)
	is_battle_running = false
	battle_finished.emit(battle)
	return battle


## Called by the battle view when the playback is over.
func finish_presentation() -> void:
	_presentation_finished.emit()


func _complete_job(job: JobData) -> void:
	job.completed = true
	job.clear_assignment()
	var player := GameState.player_stats
	player.money += job.reward_money
	player.fame += job.reward_fame
	job_completed.emit(job)
