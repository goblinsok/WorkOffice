class_name BattleUnit extends RefCounted
## A girl's working copy inside a BattleSimulation. The real GirlInfo is only
## updated when the simulation's results are applied.

var index: int
var girl: GirlInfo
var energy: int
var max_energy: int
var attack: int
var attack_energy_cost: int
var exhausted: bool = false


func _init(p_index: int, p_girl: GirlInfo) -> void:
	index = p_index
	girl = p_girl
	energy = girl.energy
	max_energy = girl.max_energy
	attack = girl.attack
	attack_energy_cost = maxi(girl.attack_energy_cost, 1)


func can_attack() -> bool:
	return not exhausted and energy >= attack_energy_cost
