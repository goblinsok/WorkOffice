extends BaseMenu
## Job (boss) description plus girl assignment via drag & drop.

const CHIP_SCENE := preload("res://UI/Menus/Job/girl_chip.tscn")
const ZONE_SCENE := preload("res://UI/Menus/Job/girl_drop_zone.tscn")
const BUFF_COLOR := Color(0.2, 0.5, 0.2)
const DEBUFF_COLOR := Color(0.65, 0.18, 0.15)

@onready var job_body: Control = %JobBody
@onready var no_job_label: Label = %NoJobLabel
@onready var boss_icon: TextureRect = %BossIcon
@onready var boss_short_label: Label = %BossShortLabel
@onready var hp_bar: StatBar = %HpBar
@onready var reward_label: Label = %RewardLabel
@onready var job_name_label: Label = %JobNameLabel
@onready var flavor_label: Label = %FlavorLabel
@onready var attack_label: Label = %AttackLabel
@onready var attack_description_label: Label = %AttackDescriptionLabel
@onready var abilities_list: VBoxContainer = %AbilitiesList
@onready var status_list: VBoxContainer = %StatusList
@onready var slots_row: HBoxContainer = %SlotsRow
@onready var pool_zone: GirlDropZone = %PoolZone

var _job: JobData


func _ready() -> void:
	super._ready()
	pool_zone.girl_dropped.connect(_on_girl_dropped)


func _on_open() -> void:
	_job = JobManager.get_current_job()
	job_body.visible = _job != null
	no_job_label.visible = _job == null
	if _job == null:
		return
	_job.assignment_changed.connect(_refresh_assignment)
	_refresh_description()
	_build_slots()
	_refresh_assignment()


func _on_close() -> void:
	if _job and _job.assignment_changed.is_connected(_refresh_assignment):
		_job.assignment_changed.disconnect(_refresh_assignment)


func _refresh_description() -> void:
	boss_icon.texture = _job.icon
	boss_short_label.text = _job.short_name
	boss_short_label.visible = _job.icon == null
	hp_bar.set_values(_job.hp, _job.max_hp)
	reward_label.text = "Reward: $%d, +%d fame" % [_job.reward_money, _job.reward_fame]
	job_name_label.text = _job.display_name
	flavor_label.text = _job.flavor_text
	var bonus := _job.get_total_attack() - _job.attack
	attack_label.text = "%s: %d energy to each girl%s" % [
		_job.attack_name, _job.get_total_attack(), " (%+d)" % bonus if bonus != 0 else ""]
	attack_description_label.text = _job.attack_description

	_clear(abilities_list)
	for ability in _job.abilities:
		_add_entry(abilities_list, "◆ " + ability.display_name, ability.description)
	if _job.abilities.is_empty():
		_add_entry(abilities_list, "None", "")

	_clear(status_list)
	for effect in _job.get_buffs():
		_add_entry(status_list, "▲ " + effect.display_name, effect.description, BUFF_COLOR)
	for effect in _job.get_debuffs():
		_add_entry(status_list, "▼ " + effect.display_name, effect.description, DEBUFF_COLOR)
	if _job.status_effects.is_empty():
		_add_entry(status_list, "None", "")


func _build_slots() -> void:
	_clear(slots_row)
	for i in _job.max_assigned:
		var zone: GirlDropZone = ZONE_SCENE.instantiate()
		zone.slot_index = i
		slots_row.add_child(zone)
		zone.girl_dropped.connect(_on_girl_dropped)


func _refresh_assignment() -> void:
	for zone: GirlDropZone in slots_row.get_children():
		_clear(zone.chips)
		var girl_id := _job.get_slot(zone.slot_index)
		zone.set_placeholder_visible(girl_id.is_empty())
		if not girl_id.is_empty():
			_add_chip(zone, GameState.girls.get_by_id(girl_id))

	_clear(pool_zone.chips)
	var any_free := false
	for girl in GameState.get_girls():
		if not _job.is_assigned(girl.id):
			_add_chip(pool_zone, girl)
			any_free = true
	pool_zone.set_placeholder_visible(not any_free)


func _on_girl_dropped(girl_id: StringName, slot_index: int) -> void:
	if slot_index == GirlDropZone.POOL:
		_job.unassign(girl_id)
	else:
		_job.assign(girl_id, slot_index)


func _add_chip(zone: GirlDropZone, girl: GirlInfo) -> void:
	var chip: GirlChip = CHIP_SCENE.instantiate()
	zone.chips.add_child(chip)
	chip.setup(girl)


func _add_entry(list: VBoxContainer, heading: String, body: String, color: Color = Color(0.16, 0.13, 0.1)) -> void:
	var title := Label.new()
	title.text = heading
	title.add_theme_color_override("font_color", color)
	list.add_child(title)
	if not body.is_empty():
		var text := Label.new()
		text.text = body
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size.x = 380
		text.add_theme_font_size_override("font_size", 13)
		text.add_theme_color_override("font_color", Color(0.35, 0.31, 0.26))
		list.add_child(text)


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
