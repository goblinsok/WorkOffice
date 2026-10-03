class_name BattleSimulation extends RefCounted
## Resolves a whole job battle up front and records it as a list of BattleEvents.
## It has no UI and no side effects until apply_results(). This keeps it
## deterministic with a seeded RNG, testable, and independent of the presentation.
##
## Rules:
##   1. The boss attacks once at the start: every girl loses (boss attack) energy.
##   2. Rounds: active girls attack in a freshly shuffled order. Each attack costs
##      attack_energy_cost and deals attack x 0.8..1.2 (+ damage_taken modifiers).
##   3. A girl whose energy is below her attack cost is exhausted and stops acting.
##   4. The battle ends when every girl is exhausted or the boss reaches 0 HP.

const DAMAGE_VARIANCE := 0.2
const MAX_ROUNDS := 100

var job: JobData
var units: Array[BattleUnit] = []
var boss_hp: int
var boss_max_hp: int
var events: Array[BattleEvent] = []
var round_number: int = 0
var victory: bool = false
var total_damage: int = 0

var _rng: RandomNumberGenerator
var _low_hp_triggered: Array[BossAbility] = []


func _init(p_job: JobData, girls: Array[GirlInfo], rng: RandomNumberGenerator = null) -> void:
	job = p_job
	boss_hp = job.hp
	boss_max_hp = job.max_hp
	for i in girls.size():
		units.append(BattleUnit.new(i, girls[i]))
	_rng = rng if rng else RandomNumberGenerator.new()
	if rng == null:
		_rng.randomize()


func run() -> Array[BattleEvent]:
	_add(BattleEvent.new(BattleEvent.Type.BATTLE_START))
	_trigger_abilities(BossAbility.Trigger.BATTLE_START)

	_boss_attack()

	while _any_can_act() and boss_hp > 0 and round_number < MAX_ROUNDS:
		round_number += 1
		var start := BattleEvent.new(BattleEvent.Type.ROUND_START)
		start.round_number = round_number
		_add(start)
		_trigger_abilities(BossAbility.Trigger.ROUND_START)

		var order := units.filter(func(unit: BattleUnit) -> bool: return unit.can_attack())
		_shuffle(order)
		for unit: BattleUnit in order:
			_girl_attack(unit)
			if boss_hp <= 0:
				break

	victory = boss_hp <= 0
	if victory:
		_add(BattleEvent.new(BattleEvent.Type.BOSS_DEFEATED))
	_add(BattleEvent.new(BattleEvent.Type.BATTLE_END))
	return events


## Writes the outcome back to the real data (job HP and girl energy).
func apply_results() -> void:
	job.set_hp(boss_hp)
	for unit in units:
		unit.girl.set_stat(&"energy", unit.energy)


## Used by BossAbility placeholders to report that they fired.
func log_ability(ability: BossAbility) -> void:
	var event := BattleEvent.new(BattleEvent.Type.ABILITY)
	event.text = "%s: %s" % [ability.display_name, ability.description]
	_add(event)


# ---------------------------------------------------------------- steps

func _boss_attack() -> void:
	var damage := job.get_total_attack()
	_add(BattleEvent.new(BattleEvent.Type.BOSS_ATTACK))
	for unit in units:
		var lost := mini(damage, unit.energy)
		unit.energy -= lost
		var event := BattleEvent.new(BattleEvent.Type.ENERGY_LOST, unit.index)
		event.amount = lost
		event.value_after = unit.energy
		_add(event)
	for unit in units:
		_check_exhausted(unit)


func _girl_attack(unit: BattleUnit) -> void:
	unit.energy -= unit.attack_energy_cost
	var damage := _roll_damage(unit)
	boss_hp = maxi(boss_hp - damage, 0)
	total_damage += damage

	var event := BattleEvent.new(BattleEvent.Type.GIRL_ATTACK, unit.index)
	event.amount = damage
	event.value_after = boss_hp
	event.energy_after = unit.energy
	_add(event)

	_check_low_hp()
	_check_exhausted(unit)


func _roll_damage(unit: BattleUnit) -> int:
	var multiplier := _rng.randf_range(1.0 - DAMAGE_VARIANCE, 1.0 + DAMAGE_VARIANCE)
	var damage := roundi(unit.attack * multiplier) + job.get_modifier(&"damage_taken")
	return maxi(damage, 1)


func _check_exhausted(unit: BattleUnit) -> void:
	if not unit.exhausted and unit.energy < unit.attack_energy_cost:
		unit.exhausted = true
		_add(BattleEvent.new(BattleEvent.Type.GIRL_EXHAUSTED, unit.index))


func _check_low_hp() -> void:
	for ability in job.abilities:
		if ability.trigger != BossAbility.Trigger.LOW_HP or ability in _low_hp_triggered:
			continue
		if boss_hp * 100 <= boss_max_hp * ability.hp_threshold_percent:
			_low_hp_triggered.append(ability)
			ability.activate(self)


func _trigger_abilities(trigger: BossAbility.Trigger) -> void:
	for ability in job.abilities:
		if ability.trigger == trigger:
			ability.activate(self)


func _any_can_act() -> bool:
	return units.any(func(unit: BattleUnit) -> bool: return unit.can_attack())


## Fisher-Yates with the simulation's RNG (Array.shuffle() would ignore the seed).
func _shuffle(array: Array) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var temp: Variant = array[i]
		array[i] = array[j]
		array[j] = temp


func _add(event: BattleEvent) -> void:
	event.round_number = round_number if event.round_number == 0 else event.round_number
	events.append(event)
