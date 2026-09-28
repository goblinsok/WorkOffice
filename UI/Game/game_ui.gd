extends CanvasLayer

@onready var money_label: Label = %MoneyLabel
@onready var date_label: Label = %DateLabel

@onready var map_button: Button = %MapButton
@onready var map: CanvasLayer = %Map

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.player_stats.money_update.connect(update_money)
	money_label.text = str(GameState.player_stats.money)
	update_date()
	
	map_button.pressed.connect(open_map)
	map.closed.connect(func (): map_button.disabled = false)
	
func update_ui() -> void:
	pass
	
func open_map() -> void:
	map.show_map()
	map_button.disabled = true
	
func update_money() -> void:
	var diff = GameState.player_stats.money - int(money_label.text)
	
	print("Difference in money - %s" % diff)
	
	money_label.text = str(GameState.player_stats.money)

func update_date() -> void:
	var day_format : String
	var time_format : String
	
	match GameState.world_info.current_time:
		Enums.TIME_STATE.MORNING:
			time_format = 'Morning'
		Enums.TIME_STATE.AFTERNOON:
			time_format = 'Afternoon'
		Enums.TIME_STATE.EVENING:
			time_format = 'Evening'
			
	match GameState.world_info.current_day:
		Enums.WEEK_STATE.MONDAY:
			day_format = 'MON'
		Enums.WEEK_STATE.TUESDAY:
			day_format = 'TUE'
		Enums.WEEK_STATE.WEDNESDAY:
			day_format = 'WED'
			
	date_label.text = '%s, %s' % [day_format, time_format]
