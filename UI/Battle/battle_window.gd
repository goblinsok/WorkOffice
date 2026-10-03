extends CanvasLayer
## Plays back a BattleSimulation's events with simple effects (floating damage
## numbers, hops, shakes, bars). Clicking speeds the playback up.
## Calls JobManager.finish_presentation() when done.

const CARD_SCENE := preload("res://UI/Battle/battle_girl_card.tscn")
const FLOATING_TEXT := preload("res://UI/Components/floating_text.tscn")

const DAMAGE_COLOR := Color(1, 0.35, 0.3)
const ENERGY_COLOR := Color(1, 0.85, 0.3)
const INFO_COLOR := Color(0.8, 0.8, 0.85)
const FAST_SPEED := 4.0

## Seconds between girl attacks at normal speed.
@export var step_delay: float = 0.6

@onready var root: Control = %Root
@onready var title_label: Label = %TitleLabel
@onready var hp_bar: StatBar = %HpBar
@onready var boss_frame: Control = %BossFrame
@onready var boss_icon: TextureRect = %BossIcon
@onready var boss_short_label: Label = %BossShortLabel
@onready var round_label: Label = %RoundLabel
@onready var log_label: Label = %LogLabel
@onready var girls_row: HBoxContainer = %GirlsRow
@onready var banner: Label = %Banner
@onready var fx_layer: Control = %FxLayer
@onready var speed_hint: Label = %SpeedHint

var speed: float = 1.0
var _cards: Array[BattleGirlCard] = []
var _battle: BattleSimulation


func _ready() -> void:
	visible = false
	root.gui_input.connect(_on_root_input)
	JobManager.battle_started.connect(_on_battle_started)


func _on_battle_started(battle: BattleSimulation) -> void:
	_play(battle)


func _play(battle: BattleSimulation) -> void:
	_battle = battle
	speed = 1.0
	_setup(battle)
	visible = true
	root.modulate.a = 0.0
	await create_tween().tween_property(root, "modulate:a", 1.0, 0.3).finished

	for event in battle.events:
		await _play_event(event)

	await _wait(2.0)
	await create_tween().tween_property(root, "modulate:a", 0.0, 0.3).finished
	visible = false
	_battle = null
	JobManager.finish_presentation()


func _setup(battle: BattleSimulation) -> void:
	var job := battle.job
	title_label.text = job.display_name
	boss_icon.texture = job.icon
	boss_short_label.text = job.short_name
	boss_short_label.visible = job.icon == null
	boss_frame.modulate = Color.WHITE
	boss_frame.scale = Vector2.ONE
	hp_bar.set_values(job.hp, job.max_hp)
	round_label.text = ""
	log_label.text = ""
	banner.visible = false
	speed_hint.visible = true

	for card in _cards:
		card.queue_free()
	_cards.clear()
	for unit in battle.units:
		var card: BattleGirlCard = CARD_SCENE.instantiate()
		girls_row.add_child(card)
		card.setup(unit.girl, unit.girl.energy, unit.max_energy)
		_cards.append(card)


func _play_event(event: BattleEvent) -> void:
	match event.type:
		BattleEvent.Type.BATTLE_START:
			await _show_banner("Work begins!", 1.0)
		BattleEvent.Type.ABILITY:
			log_label.text = event.text
			_float(event.text.get_slice(":", 0), _boss_center() + Vector2(0, -60), INFO_COLOR)
			await _wait(1.2)
		BattleEvent.Type.BOSS_ATTACK:
			log_label.text = "%s uses %s!" % [_battle.job.display_name, _battle.job.attack_name]
			await _boss_lunge()
		BattleEvent.Type.ENERGY_LOST:
			var card := _cards[event.unit]
			card.play_hit()
			card.set_energy(event.value_after, _battle.units[event.unit].max_energy)
			_float("-%d" % event.amount, card.get_fx_position(), ENERGY_COLOR)
			await _wait(0.15)
		BattleEvent.Type.ROUND_START:
			round_label.text = "Round %d" % event.round_number
			await _wait(0.4)
		BattleEvent.Type.GIRL_ATTACK:
			var card := _cards[event.unit]
			card.play_attack()
			card.set_energy(event.energy_after, _battle.units[event.unit].max_energy)
			log_label.text = "%s deals %d damage." % [_battle.units[event.unit].girl.display_name, event.amount]
			_float("-%d" % event.amount, _boss_center() + Vector2(randf_range(-40, 40), -20), DAMAGE_COLOR)
			hp_bar.animate_to(event.value_after, _battle.boss_max_hp)
			_boss_shake()
			await _wait(step_delay)
		BattleEvent.Type.GIRL_EXHAUSTED:
			var card := _cards[event.unit]
			card.set_exhausted()
			_float("Exhausted", card.get_fx_position(), INFO_COLOR)
			await _wait(0.4)
		BattleEvent.Type.BOSS_DEFEATED:
			var tween := create_tween().set_parallel()
			tween.tween_property(boss_frame, "modulate:a", 0.0, 0.6)
			tween.tween_property(boss_frame, "scale", Vector2(0.6, 0.6), 0.6)
			await _wait(0.6)
		BattleEvent.Type.BATTLE_END:
			speed_hint.visible = false
			if _battle.victory:
				await _show_banner("JOB COMPLETE!\n+$%d  +%d fame" % [_battle.job.reward_money, _battle.job.reward_fame], 0.0)
			else:
				await _show_banner("Everyone is exhausted.\n%d damage dealt today (%d HP left)" % [_battle.total_damage, _battle.boss_hp], 0.0)


# ---------------------------------------------------------------- effects

func _float(text: String, center: Vector2, color: Color) -> void:
	var fx: FloatingText = FLOATING_TEXT.instantiate()
	fx_layer.add_child(fx)
	fx.play(text, color, center)


func _boss_center() -> Vector2:
	return boss_frame.get_global_rect().get_center()


func _boss_lunge() -> void:
	boss_frame.pivot_offset = boss_frame.size * 0.5
	var tween := create_tween()
	tween.tween_property(boss_frame, "scale", Vector2(1.25, 1.25), 0.15 / speed)
	tween.tween_property(boss_frame, "scale", Vector2.ONE, 0.2 / speed)
	await tween.finished


func _boss_shake() -> void:
	var tween := create_tween()
	tween.tween_property(boss_frame, "rotation", 0.06, 0.04)
	tween.tween_property(boss_frame, "rotation", -0.06, 0.06)
	tween.tween_property(boss_frame, "rotation", 0.0, 0.04)
	boss_frame.pivot_offset = boss_frame.size * 0.5
	var flash := create_tween()
	flash.tween_property(boss_frame, "self_modulate", Color(2, 2, 2), 0.05)
	flash.tween_property(boss_frame, "self_modulate", Color.WHITE, 0.15)


func _show_banner(text: String, hold: float) -> void:
	banner.text = text
	banner.visible = true
	banner.reset_size()
	banner.pivot_offset = banner.size * 0.5
	banner.scale = Vector2(0.7, 0.7)
	banner.modulate.a = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "modulate:a", 1.0, 0.2)
	await tween.finished
	if hold > 0.0:
		await _wait(hold)
		banner.visible = false


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds / speed).timeout


func _on_root_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		root.accept_event()
		speed = FAST_SPEED
