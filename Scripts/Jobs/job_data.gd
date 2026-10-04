class_name JobData extends Resource
## A job the girls work on, structured as a boss fight. The boss fights at the end of
## every day. Its HP persists between days until it is defeated (the job is completed).

signal assignment_changed()
signal hp_changed(hp: int, max_hp: int)

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
## Short text on the boss placeholder until there is real art.
@export var short_name: String
@export_multiline var flavor_text: String

@export_group("Boss")
@export var max_hp: int = 100
@export var hp: int = 100
## Energy drained from every assigned girl by the boss's attack at the start of the battle.
@export var attack: int = 10
@export var attack_name: String = "Attack"
@export_multiline var attack_description: String
## Placeholder: abilities are listed in the UI and triggered in battle, but have no mechanics yet.
@export var abilities: Array[BossAbility] = []
## Buffs and debuffs that are active on the boss.
@export var status_effects: Array[StatusEffectData] = []

@export_group("Assignment")
@export var max_assigned: int = 3

@export_group("Rewards")
@export var reward_money: int = 0
@export var reward_fame: int = 0

## Runtime: girl per slot, Ids.Girl.NONE for an empty slot.
var assigned: Array[Ids.Girl] = []
var completed: bool = false


func set_hp(value: int) -> void:
	hp = clampi(value, 0, max_hp)
	hp_changed.emit(hp, max_hp)


func get_buffs() -> Array[StatusEffectData]:
	return status_effects.filter(func(effect: StatusEffectData) -> bool: return not effect.is_debuff)


func get_debuffs() -> Array[StatusEffectData]:
	return status_effects.filter(func(effect: StatusEffectData) -> bool: return effect.is_debuff)


## Sum of a stat modifier over all active status effects.
func get_modifier(modifier: Ids.BossModifier) -> int:
	var total := 0
	for effect in status_effects:
		total += effect.get_modifier(modifier)
	return total


func get_total_attack() -> int:
	return maxi(attack + get_modifier(Ids.BossModifier.ATTACK), 0)


# ---------------------------------------------------------------- assignment

func get_slot(slot: int) -> Ids.Girl:
	_ensure_slots()
	return assigned[slot]


func is_assigned(girl_id: Ids.Girl) -> bool:
	_ensure_slots()
	return girl_id != Ids.Girl.NONE and girl_id in assigned


## Puts a girl in a slot. If she was in another slot, the girls swap places.
## A girl displaced from the pool side goes back to the pool.
func assign(girl_id: Ids.Girl, slot: int) -> void:
	_ensure_slots()
	if girl_id == Ids.Girl.NONE or slot < 0 or slot >= max_assigned:
		return
	var previous_slot := assigned.find(girl_id)
	var displaced := assigned[slot]
	assigned[slot] = girl_id
	if previous_slot >= 0 and previous_slot != slot:
		assigned[previous_slot] = displaced
	assignment_changed.emit()


func unassign(girl_id: Ids.Girl) -> void:
	_ensure_slots()
	if girl_id == Ids.Girl.NONE:
		return
	var slot := assigned.find(girl_id)
	if slot >= 0:
		assigned[slot] = Ids.Girl.NONE
		assignment_changed.emit()


func clear_assignment() -> void:
	assigned.clear()
	_ensure_slots()
	assignment_changed.emit()


func get_assigned_girls(repo: GirlsRepo) -> Array[GirlInfo]:
	_ensure_slots()
	var result: Array[GirlInfo] = []
	for girl_id in assigned:
		if girl_id != Ids.Girl.NONE:
			var girl := repo.get_by_id(girl_id)
			if girl:
				result.append(girl)
	return result


func _ensure_slots() -> void:
	while assigned.size() < max_assigned:
		assigned.append(Ids.Girl.NONE)
