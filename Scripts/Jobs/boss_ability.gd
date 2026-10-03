class_name BossAbility extends Resource
## Placeholder for special boss abilities. Listed in the job menu and triggered by
## BattleSimulation. For now, activation only produces a log event. Subclass it and
## override activate() to give an ability real mechanics.

enum Trigger {
	BATTLE_START,
	ROUND_START,
	## Once, when boss HP drops below hp_threshold_percent.
	LOW_HP,
}

@export var display_name: String
@export_multiline var description: String
@export var trigger: Trigger = Trigger.BATTLE_START
@export_range(0, 100) var hp_threshold_percent: int = 30


## Called by the simulation when the trigger fires.
func activate(battle: BattleSimulation) -> void:
	battle.log_ability(self)
