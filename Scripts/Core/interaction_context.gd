class_name InteractionContext extends RefCounted
## Everything an interaction, condition, effect or dialog needs to know about "who/where".
## Its public methods are also the function API available inside script expressions.

var girl: GirlInfo
var location: LocationInfo
var poi: PoiInfo
## World node of the girl (for bubbles and menu positioning). May be null for non-world dialogs.
var view: BaseGirlLocation
## Set by cutscenes: true makes the triggering interaction be skipped (no effects, no actions spent).
var action_cancelled: bool = false


## Pass a girl view to fill girl/location/poi from its placement.
func _init(girl_view: BaseGirlLocation = null) -> void:
	view = girl_view
	if girl_view and girl_view.placement:
		var placement := girl_view.placement
		girl = placement.girl
		location = placement.location
		poi = placement.poi


## Sets the girl without a world view (items, menus, battles). Returns self for chaining.
func with_girl(p_girl: GirlInfo) -> InteractionContext:
	girl = p_girl
	return self


## The girl's own interactions, then the extras of her setup at this point (no duplicates).
func get_interactions() -> Array[InteractionData]:
	var result: Array[InteractionData] = []
	if view == null or view.placement == null:
		return result
	var placement := view.placement
	for interaction in placement.girl.interactions + placement.setup.extra_interactions:
		if interaction != null and not interaction in result:
			result.append(interaction)
	return result


# --- Expression API (callable from dialogs / ExpressionCondition / ExpressionEffect) ---

## stat_name is a lowercase Ids.Stat key ("affection").
func add_stat(stat_name: String, amount: int) -> void:
	var stat_id := _parse_stat(stat_name)
	if girl and stat_id != Ids.Stat.NONE:
		girl.modify_stat(stat_id, amount)


func stat(stat_name: String) -> int:
	var stat_id := _parse_stat(stat_name)
	return girl.get_stat(stat_id) if girl and stat_id != Ids.Stat.NONE else 0


func add_money(amount: int) -> void:
	GameState.player_stats.money += amount


func add_actions(amount: int) -> void:
	GameState.player_stats.actions += amount


func flag(flag_name: String) -> Variant:
	return GameState.world_info.get_flag(flag_name)


func set_flag(flag_name: String, value: Variant = true) -> void:
	GameState.world_info.set_flag(flag_name, value)


func bubble(text: String, duration: float = 2.5) -> void:
	if is_instance_valid(view):
		DialogManager.show_bubble(view.bubble_anchor, GameExpression.interpolate(text, self), duration)


## Cutscene dialogs: the interaction that triggered the cutscene will NOT run afterwards.
func cancel_action() -> void:
	action_cancelled = true


## Cutscene dialogs: the interaction that triggered the cutscene will run afterwards.
func proceed_action() -> void:
	action_cancelled = false


func _parse_stat(stat_name: String) -> Ids.Stat:
	var stat_id := Ids.stat_from_name(stat_name)
	if stat_id == Ids.Stat.NONE:
		push_error("Unknown stat '%s' (see Ids.Stat)" % stat_name)
	return stat_id
