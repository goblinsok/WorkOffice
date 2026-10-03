class_name InteractionContext extends RefCounted
## Everything an interaction, condition, effect or dialog needs to know about "who/where".
## Its public methods are also the function API available inside script expressions.

var girl: GirlInfo
var location: LocationInfo
var poi: PoiInfo
## World node of the girl (for bubbles and menu positioning). May be null for non-world dialogs.
var view: BaseGirlLocation


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


## Interactions available at the view's point of interest.
func get_interactions() -> Array[InteractionData]:
	if view == null or view.placement == null:
		return []
	return view.placement.setup.interactions


# --- Expression API (callable from dialogs / ExpressionCondition / ExpressionEffect) ---

func add_stat(stat_name: String, amount: int) -> void:
	if girl:
		girl.modify_stat(stat_name, amount)


func stat(stat_name: String) -> int:
	return girl.get_stat(stat_name) if girl else 0


func add_money(amount: int) -> void:
	GameState.player_stats.money += amount


func add_actions(amount: int) -> void:
	GameState.player_stats.actions += amount


func flag(flag_name: String) -> Variant:
	return GameState.world_info.get_flag(flag_name)


func set_flag(flag_name: String, value: Variant = true) -> void:
	GameState.world_info.set_flag(flag_name, value)


func bubble(text: String, duration: float = 2.5) -> void:
	if view:
		DialogManager.show_bubble(view.bubble_anchor, GameExpression.interpolate(text, self), duration)
