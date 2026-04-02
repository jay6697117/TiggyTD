extends CanvasLayer

# ---------------------------------------------------------------------------
# ShopPanel — 波次间商店
# SHOP 状态时显示，消耗古代印记购买增益
# ---------------------------------------------------------------------------

@onready var label_marks: Label   = $Panel/VBox/LabelMarks
@onready var btn_hp_up: Button    = $Panel/VBox/BtnHpUp
@onready var btn_gold_up: Button  = $Panel/VBox/BtnGoldUp
@onready var btn_cd_reset: Button = $Panel/VBox/BtnCdReset
@onready var btn_close: Button    = $Panel/VBox/BtnClose

const COST_HP_UP    := 2
const COST_GOLD_UP  := 1
const COST_CD_RESET := 3


func _ready() -> void:
	GameState.state_changed.connect(_on_state_changed)
	GameState.ancient_marks_changed.connect(_on_marks_changed)
	btn_hp_up.pressed.connect(_on_hp_up)
	btn_gold_up.pressed.connect(_on_gold_up)
	btn_cd_reset.pressed.connect(_on_cd_reset)
	btn_close.pressed.connect(_on_close)
	_build_icons()
	visible = false

func _build_icons() -> void:
	var vbox = $Panel/VBox
	var mark_hbox = HBoxContainer.new()
	mark_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	var mark_icon = TextureRect.new()
	mark_icon.texture = load("res://assets/art/ui/icon_mark.png")
	mark_icon.custom_minimum_size = Vector2(32, 32)
	mark_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark_hbox.add_child(mark_icon)
	vbox.add_child(mark_hbox)
	vbox.move_child(mark_hbox, label_marks.get_index())
	label_marks.get_parent().remove_child(label_marks)
	mark_hbox.add_child(label_marks)


func _on_state_changed(new_state: GameState.State) -> void:
	if new_state == GameState.State.SHOP:
		_refresh()
		visible = true
	else:
		visible = false


func _refresh() -> void:
	label_marks.text = Localization.L("ui.ancient_marks", [GameState.ancient_marks])
	btn_hp_up.text    = Localization.L("ui.shop_hp_up", [COST_HP_UP])
	btn_gold_up.text  = Localization.L("ui.shop_gold_up", [COST_GOLD_UP])
	btn_cd_reset.text = Localization.L("ui.shop_cd_reset", [COST_CD_RESET])
	_update_btn_states()


func _update_btn_states() -> void:
	var marks := GameState.ancient_marks
	btn_hp_up.disabled    = marks < COST_HP_UP
	btn_gold_up.disabled  = marks < COST_GOLD_UP
	btn_cd_reset.disabled = marks < COST_CD_RESET


func _on_marks_changed(_amount: int) -> void:
	label_marks.text = Localization.L("ui.ancient_marks", [GameState.ancient_marks])
	_update_btn_states()


func _on_hp_up() -> void:
	if not GameState.spend_ancient_marks(COST_HP_UP):
		return
	AudioSystem.play_sfx("ui_buy")
	for t in get_tree().get_nodes_in_group("towers"):
		if t is Tower:
			t.hp = minf(t.hp * 1.2, t.max_hp * 1.2)
			t.max_hp *= 1.2


func _on_gold_up() -> void:
	if not GameState.spend_ancient_marks(COST_GOLD_UP):
		return
	AudioSystem.play_sfx("ui_buy")
	GameState.add_gold(50)


func _on_cd_reset() -> void:
	if not GameState.spend_ancient_marks(COST_CD_RESET):
		return
	AudioSystem.play_sfx("ui_buy")
	for h in get_tree().get_nodes_in_group("hero"):
		if h is Hero:
			h.reset_cooldowns()


func _on_close() -> void:
	AudioSystem.play_sfx("ui_click")
	GameState.change_state(GameState.State.BUILD)
