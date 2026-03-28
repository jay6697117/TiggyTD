extends CanvasLayer

# ---------------------------------------------------------------------------
# HUD — 游戏主界面
# 显示：金币、波次、基地血量；提供「开始下一波」按钮
# 依赖：GameState
# ---------------------------------------------------------------------------

@onready var label_gold: Label       = $Panel/HBox/LabelGold
@onready var label_hp: Label         = $Panel/HBox/LabelHP
@onready var label_wave: Label       = $Panel/HBox/LabelWave
@onready var label_marks: Label      = $Panel/HBox/LabelMarks
@onready var label_countdown: Label  = $Panel/HBox/LabelCountdown
@onready var btn_start: Button       = $Panel/HBox/BtnStart
@onready var btn_q: Button           = $SkillBar/HBox/SkillQ/BtnApexRoar
@onready var btn_w: Button           = $SkillBar/HBox/SkillW/BtnNaturesCall
@onready var btn_e: Button           = $SkillBar/HBox/SkillE/BtnEraJudgement
@onready var label_cd_q: Label       = $SkillBar/HBox/SkillQ/LabelCdQ
@onready var label_cd_w: Label       = $SkillBar/HBox/SkillW/LabelCdW
@onready var label_cd_e: Label       = $SkillBar/HBox/SkillE/LabelCdE


@onready var _synergy_banner: Label = _make_synergy_banner()

func _make_synergy_banner() -> Label:
	var lbl := Label.new()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	lbl.anchor_left = 0.0
	lbl.anchor_right = 1.0
	lbl.anchor_top = 0.3
	lbl.anchor_bottom = 0.45
	lbl.visible = false
	add_child(lbl)
	return lbl


func show_synergy_banner(text: String) -> void:
	_synergy_banner.text = text
	_synergy_banner.visible = true
	var t := get_tree().create_timer(1.5)
	t.timeout.connect(func(): _synergy_banner.visible = false)


func _ready() -> void:
	add_to_group("hud")
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.base_hp_changed.connect(_on_hp_changed)
	GameState.wave_changed.connect(_on_wave_changed)
	GameState.state_changed.connect(_on_state_changed)
	GameState.ancient_marks_changed.connect(_on_marks_changed)
	btn_start.pressed.connect(_on_btn_start_pressed)
	call_deferred("_connect_wave_manager")
	call_deferred("_connect_hero")
	_refresh()


func _connect_wave_manager() -> void:
	var wm := get_tree().get_first_node_in_group("wave_manager")
	if wm:
		wm.prepare_tick.connect(_on_prepare_tick)


func _connect_hero() -> void:
	var heroes := get_tree().get_nodes_in_group("hero")
	if heroes.is_empty():
		return
	var hero := heroes[0]
	hero.skill_cd_updated.connect(_on_skill_cd_updated)
	btn_q.pressed.connect(func(): hero.activate_skill("apex_roar"))
	btn_w.pressed.connect(func(): hero.activate_skill("natures_call"))
	btn_e.pressed.connect(func(): hero.activate_skill("era_judgement"))


func _refresh() -> void:
	label_gold.text  = "金币：%d" % GameState.gold
	label_hp.text    = "基地：%d / %d" % [GameState.base_hp, GameState.base_hp_max]
	label_wave.text  = "波次：%d / %d" % [GameState.current_wave, GameState.total_waves]
	label_marks.text = "印记：%d" % GameState.ancient_marks
	_update_btn_visibility()


func _update_btn_visibility() -> void:
	btn_start.visible = (GameState.current_state == GameState.State.BUILD)


func _on_gold_changed(amount: int) -> void:
	label_gold.text = "金币：%d" % amount


func _on_hp_changed(new_hp: int) -> void:
	label_hp.text = "基地：%d / %d" % [new_hp, GameState.base_hp_max]


func _on_wave_changed(new_wave: int) -> void:
	label_wave.text = "波次：%d / %d" % [new_wave, GameState.total_waves]


func _on_marks_changed(amount: int) -> void:
	label_marks.text = "印记：%d" % amount


func _on_prepare_tick(seconds_left: int) -> void:
	if seconds_left > 0:
		label_countdown.text = "准备：%ds" % seconds_left
		label_countdown.visible = true
	else:
		label_countdown.visible = false


func _on_state_changed(new_state: GameState.State) -> void:
	_update_btn_visibility()
	if new_state == GameState.State.BUILD:
		label_countdown.visible = false


func _on_skill_cd_updated(skill: String, remaining: float, max_cd: float) -> void:
	var label: Label
	var btn: Button
	match skill:
		"apex_roar":    label = label_cd_q; btn = btn_q
		"natures_call": label = label_cd_w; btn = btn_w
		"era_judgement":label = label_cd_e; btn = btn_e
		_: return
	if remaining > 0.0:
		label.text = "%.0fs" % remaining
		btn.disabled = true
	else:
		label.text = ""
		btn.disabled = false


func _on_btn_start_pressed() -> void:
	if GameState.current_state == GameState.State.BUILD:
		GameState.change_state(GameState.State.WAVE)


# ── Boss HP 条 ──────────────────────────────────────────────────────────────

var _boss_bar_container: PanelContainer = null
var _boss_hp_bar: ProgressBar = null
var _boss_name_label: Label = null
var _boss_enemy: Enemy = null


func show_boss_bar(enemy: Enemy) -> void:
	_boss_enemy = enemy
	if _boss_bar_container == null:
		_build_boss_bar()
	_boss_hp_bar.max_value = enemy.max_hp
	_boss_hp_bar.value = enemy.hp
	_boss_name_label.text = "沧龙霸主"
	_boss_bar_container.visible = true
	enemy.died.connect(_on_boss_died)


func _build_boss_bar() -> void:
	_boss_bar_container = PanelContainer.new()
	_boss_bar_container.anchor_left = 0.2
	_boss_bar_container.anchor_right = 0.8
	_boss_bar_container.anchor_top = 0.0
	_boss_bar_container.anchor_bottom = 0.0
	_boss_bar_container.offset_top = 4.0
	_boss_bar_container.offset_bottom = 44.0
	add_child(_boss_bar_container)
	var vbox := VBoxContainer.new()
	_boss_bar_container.add_child(vbox)
	_boss_name_label = Label.new()
	_boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_boss_name_label)
	_boss_hp_bar = ProgressBar.new()
	_boss_hp_bar.custom_minimum_size = Vector2(0, 18)
	_boss_hp_bar.show_percentage = false
	vbox.add_child(_boss_hp_bar)


func update_boss_bar(hp: float) -> void:
	if _boss_hp_bar != null:
		_boss_hp_bar.value = hp


func on_boss_shield_changed(active: bool) -> void:
	if _boss_hp_bar == null:
		return
	if active:
		_boss_hp_bar.modulate = Color(0.3, 0.6, 1.0)
		_boss_name_label.text = "沧龙霸主  【护盾中】"
	else:
		_boss_hp_bar.modulate = Color.WHITE
		_boss_name_label.text = "沧龙霸主"


func _on_boss_died(_enemy: Enemy) -> void:
	if _boss_bar_container != null:
		_boss_bar_container.visible = false
