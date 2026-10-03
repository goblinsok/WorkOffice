class_name BattleEvent extends RefCounted
## One step of a simulated battle, played back by the battle view.

enum Type {
	BATTLE_START,
	ABILITY,          ## text = ability name + description
	BOSS_ATTACK,      ## the boss attacks all girls (followed by ENERGY_LOST events)
	ENERGY_LOST,      ## unit lost `amount` energy, now `value_after`
	ROUND_START,      ## round_number = the new round
	GIRL_ATTACK,      ## unit hit the boss for `amount`, boss HP is now `value_after`
	GIRL_EXHAUSTED,   ## unit can't act anymore
	BOSS_DEFEATED,
	BATTLE_END,
}

const BOSS := -1

var type: Type
## Index of the BattleUnit involved, or BOSS.
var unit: int = BOSS
var amount: int = 0
var value_after: int = 0
## For GIRL_ATTACK: the attacker's energy after paying the cost.
var energy_after: int = 0
var round_number: int = 0
var text: String = ""


func _init(p_type: Type, p_unit: int = BOSS) -> void:
	type = p_type
	unit = p_unit
