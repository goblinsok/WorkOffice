class_name PlayerStatCondition extends InteractionCondition
## Compares a player stat (money, actions, ...). Example: MONEY AT_LEAST 10, or
## ACTIONS BELOW_MAX for "the player has spent at least one action".

@export var stat: Ids.PlayerStat = Ids.PlayerStat.MONEY
@export var comparison: Comparison = Comparison.AT_LEAST
## Ignored by BELOW_MAX.
@export var amount: int = 0


func is_met(_context: InteractionContext) -> bool:
	var player := GameState.player_stats
	return compare(player.get_stat(stat), player.get_stat_max(stat), comparison, amount)
