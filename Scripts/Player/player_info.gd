class_name PlayerInfo extends Resource

var money: int:
	set(value):
		money = value
		money_update.emit()
		
var fame: int

signal money_update();
