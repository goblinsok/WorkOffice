extends Node
## TimeManager: owns the action economy and phase transitions.
## Spending the last action advances the phase: (day end steps), fade out, advance
## the clock, (new day setup), refill actions, re-place the girls, fade in.

## Strategy used to place girls every phase. Replace it to change placement rules.
var scheduler: GirlScheduler = GirlScheduler.new()

var is_transitioning: bool = false

## Awaitable callables run in order when the last phase of a day ends, before the
## fade (e.g. the job battle). Register them with register_day_end_step().
var _day_end_steps: Array[Callable] = []


func _ready() -> void:
	# The first phase of a new game starts without a transition.
	_start_phase()


func register_day_end_step(step: Callable) -> void:
	_day_end_steps.append(step)


func spend_actions(amount: int = 1) -> void:
	if amount <= 0:
		return
	var player := GameState.player_stats
	player.actions -= amount
	if player.actions <= 0:
		await advance_phase()


func advance_phase() -> void:
	if is_transitioning:
		return
	is_transitioning = true

	if GameState.world_info.is_last_phase_of_day():
		for step in _day_end_steps:
			await step.call()

	await ScreenFader.fade_out()

	if GameState.world_info.advance_time():
		_start_day()
	_start_phase()

	await ScreenFader.fade_in()
	is_transitioning = false


func _start_day() -> void:
	for girl in GameState.get_girls():
		girl.restore_energy()
	GlobalSignals.day_started.emit(GameState.world_info.current_day)


func _start_phase() -> void:
	var world := GameState.world_info
	GameState.player_stats.refill_actions()
	world.placements = scheduler.schedule(GameState.get_girls(), GameState.locations.locations, world)
	GlobalSignals.time_changed.emit(world.current_day, world.current_time)
	GlobalSignals.girls_placed.emit()
