extends BaseMenu
## Player stats styled as an employee ID card. Every value is hard-linked to its label.

@onready var photo: TextureRect = %Photo
@onready var photo_placeholder: Label = %PhotoPlaceholder
@onready var name_value: Label = %NameValue
@onready var position_value: Label = %PositionValue
@onready var id_value: Label = %IdValue
@onready var money_value: Label = %MoneyValue
@onready var fame_value: Label = %FameValue
@onready var charisma_value: Label = %CharismaValue
@onready var management_value: Label = %ManagementValue
@onready var actions_value: Label = %ActionsValue
@onready var days_value: Label = %DaysValue


func _on_open() -> void:
	var player := GameState.player_stats
	player.money_update.connect(_refresh)
	player.stats_changed.connect(_refresh)
	player.actions_changed.connect(_refresh_actions)
	_refresh()


func _on_close() -> void:
	var player := GameState.player_stats
	player.money_update.disconnect(_refresh)
	player.stats_changed.disconnect(_refresh)
	player.actions_changed.disconnect(_refresh_actions)


func _refresh() -> void:
	var player := GameState.player_stats
	photo.texture = player.photo
	photo_placeholder.visible = player.photo == null
	name_value.text = player.display_name
	position_value.text = player.position_title
	id_value.text = player.employee_id
	money_value.text = "$%d" % player.money
	fame_value.text = str(player.fame)
	charisma_value.text = str(player.charisma)
	management_value.text = str(player.management)
	days_value.text = str(GameState.world_info.day_count + 1)
	_refresh_actions(player.actions, player.max_actions)


func _refresh_actions(actions: int, max_actions: int) -> void:
	actions_value.text = "%d / %d" % [actions, max_actions]
