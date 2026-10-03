extends BaseMenu
## Personnel dossier: one page per girl, switched with bookmark tabs on top.
## Each stat is hard-linked to its own UI element, so every stat can have its own look.

@onready var tabs: HBoxContainer = %Tabs
@onready var tab_template: Button = %TabTemplate
@onready var photo: TextureRect = %Photo
@onready var photo_placeholder: Label = %PhotoPlaceholder
@onready var name_label: Label = %NameLabel
@onready var role_label: Label = %RoleLabel
@onready var location_label: Label = %LocationLabel
@onready var job_label: Label = %JobLabel
@onready var energy_bar: StatBar = %EnergyBar
@onready var affection_bar: StatBar = %AffectionBar
@onready var arousal_bar: StatBar = %ArousalBar
@onready var attack_label: Label = %AttackLabel
@onready var attack_cost_label: Label = %AttackCostLabel
@onready var bio_label: Label = %BioLabel

var _tab_group := ButtonGroup.new()
var _current: GirlInfo


func _ready() -> void:
	super._ready()
	tab_template.visible = false


func _on_open() -> void:
	_build_tabs()
	var girls := GameState.get_girls()
	if _current == null or not _current in girls:
		_current = girls[0] if not girls.is_empty() else null
	show_girl(_current)


func _on_close() -> void:
	_watch(null)


func show_girl(girl: GirlInfo) -> void:
	_watch(girl)
	_current = girl
	for tab: Button in tabs.get_children():
		if tab != tab_template:
			tab.set_pressed_no_signal(tab.get_meta(&"girl") == girl)
	if girl == null:
		return

	name_label.text = girl.display_name.to_upper()
	role_label.text = "Position: %s" % (girl.role if not girl.role.is_empty() else "-")
	location_label.text = "Last seen: %s" % _describe_location(girl)
	job_label.text = "Assigned job: %s" % _describe_job(girl)
	photo.texture = girl.portrait
	photo_placeholder.visible = girl.portrait == null
	bio_label.text = girl.bio
	_refresh_stats()


func _refresh_stats(_stat: StringName = &"", _value: int = 0) -> void:
	var girl := _current
	energy_bar.set_values(girl.energy, girl.max_energy)
	affection_bar.set_values(girl.affection, girl.max_affection)
	arousal_bar.set_values(girl.arousal, girl.max_arousal)
	attack_label.text = "Attack: %d" % girl.attack
	attack_cost_label.text = "Energy per attack: %d" % girl.attack_energy_cost


func _build_tabs() -> void:
	for tab in tabs.get_children():
		if tab != tab_template:
			tab.queue_free()
	for girl in GameState.get_girls():
		var tab := tab_template.duplicate() as Button
		tab.visible = true
		tab.text = girl.display_name
		tab.button_group = _tab_group
		tab.set_meta(&"girl", girl)
		tab.pressed.connect(show_girl.bind(girl))
		tabs.add_child(tab)


## Keeps the page live while it is open.
func _watch(girl: GirlInfo) -> void:
	if _current and _current.stats_changed.is_connected(_refresh_stats):
		_current.stats_changed.disconnect(_refresh_stats)
	if girl:
		girl.stats_changed.connect(_refresh_stats)


func _describe_location(girl: GirlInfo) -> String:
	var placement: GirlPlacement = GameState.world_info.placements.get(girl.id)
	if placement == null:
		return "Unknown"
	return "%s (%s)" % [placement.location.display_name, String(placement.poi.id).capitalize()]


func _describe_job(girl: GirlInfo) -> String:
	var job := GameState.jobs.get_current()
	return job.display_name if job and job.is_assigned(girl.id) else "None"
