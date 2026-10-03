class_name BattleGirlCard extends PanelContainer
## A girl's card at the bottom of the battle window: placeholder portrait, name, energy.

const EXHAUSTED_MODULATE := Color(0.45, 0.45, 0.45, 1)

@onready var portrait: TextureRect = %Portrait
@onready var portrait_placeholder: ColorRect = %PortraitPlaceholder
@onready var name_label: Label = %NameLabel
@onready var energy_bar: StatBar = %EnergyBar
@onready var exhausted_label: Label = %ExhaustedLabel


func setup(girl: GirlInfo, energy: int, max_energy: int) -> void:
	name_label.text = girl.display_name
	portrait.texture = girl.portrait
	portrait_placeholder.color = girl.name_color
	portrait_placeholder.visible = girl.portrait == null
	energy_bar.set_values(energy, max_energy)
	exhausted_label.visible = false
	modulate = Color.WHITE


func set_energy(energy: int, max_energy: int) -> void:
	energy_bar.animate_to(energy, max_energy)


func set_exhausted() -> void:
	exhausted_label.visible = true
	create_tween().tween_property(self, "modulate", EXHAUSTED_MODULATE, 0.3)


## Center of the portrait in the CanvasLayer's coordinates (for floating text).
func get_fx_position() -> Vector2:
	return portrait.get_global_rect().get_center()


## Small hop when attacking.
func play_attack() -> void:
	pivot_offset = size * 0.5
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.12, 1.12), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)


## Flash red when hit.
func play_hit() -> void:
	var tween := create_tween()
	tween.tween_property(self, "self_modulate", Color(1.6, 0.6, 0.6), 0.06)
	tween.tween_property(self, "self_modulate", Color.WHITE, 0.2)
