extends CanvasLayer

# ---------------------------------------------------------------------------
# TutorialOverlay — 新手引导系统（8步序列）
# GDD: tutorial.md
# 首次启动自动触发；完成后写存档 tutorial_completed=true
# ---------------------------------------------------------------------------

const STEPS: Array = [
	{
		"text": "欢迎来到 TiggyTD！\n你是部落的图腾守护者，\n指挥史前动物守卫家园。",
		"advance": "ok",
		"arrow_pos": Vector2(-1, -1),
	},
	{
		"text": "右键点击地图上的空地，\n移动你的英雄到新位置！",
		"advance": "hero_moved",
		"arrow_pos": Vector2(620, 440),
	},
	{
		"text": "从底部面板点击「猎豹」，\n再点击地图空格\n放置第一座动物塔！",
		"advance": "tower_placed",
		"arrow_pos": Vector2(100, 870),
	},
	{
		"text": "太棒了！点击右上角\n「开始下一波」按钮，\n召唤史前生物！",
		"advance": "wave_start",
		"arrow_pos": Vector2(940, 20),
	},
	{
		"text": "动物塔正在战斗！\n英雄光环可以增强周围\n动物塔的攻击力。\n等待本波结束……",
		"advance": "wave_clear",
		"arrow_pos": Vector2(-1, -1),
	},
	{
		"text": "波次结束！\n按 [Q] 键使用英雄技能\n「百兽怒吼」！",
		"advance": "skill_q",
		"arrow_pos": Vector2(95, 880),
	},
	{
		"text": "进入商店！\n用「古代印记」购买强力道具，\n关闭商店后继续……",
		"advance": "shop_exit",
		"arrow_pos": Vector2(-1, -1),
	},
	{
		"text": "引导完成！\n坚守10波敌人的进攻，\n守护部落的图腾！",
		"advance": "ok_finish",
		"arrow_pos": Vector2(-1, -1),
	},
]

var _step: int = 0
var _overlay: ColorRect
var _bubble: PanelContainer
var _label: Label
var _btn_ok: Button
var _btn_skip: Button
var _arrow: Label
var _in_shop: bool = false


func _ready() -> void:
	layer = 100
	_build_ui()
	call_deferred("_connect_signals")
	_show_step(0)


func _build_ui() -> void:
	# 半透明暗色全屏遮罩
	_overlay = ColorRect.new()
	_overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	# 气泡面板（居中靠下，避开技能栏）
	_bubble = PanelContainer.new()
	_bubble.anchor_left   = 0.15
	_bubble.anchor_right  = 0.85
	_bubble.anchor_top    = 0.70
	_bubble.anchor_bottom = 0.94
	add_child(_bubble)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_bubble.add_child(vbox)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_label)

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(sep)

	_btn_ok = Button.new()
	_btn_ok.text = "知道了"
	_btn_ok.add_theme_font_size_override("font_size", 18)
	_btn_ok.pressed.connect(_on_ok)
	vbox.add_child(_btn_ok)

	# 跳过按钮（右上角固定）
	_btn_skip = Button.new()
	_btn_skip.text = "跳过引导"
	_btn_skip.anchor_left   = 0.80
	_btn_skip.anchor_right  = 1.00
	_btn_skip.anchor_top    = 0.0
	_btn_skip.anchor_bottom = 0.0
	_btn_skip.offset_left   = -10.0
	_btn_skip.offset_right  = -10.0
	_btn_skip.offset_top    = 10.0
	_btn_skip.offset_bottom = 50.0
	_btn_skip.pressed.connect(_finish)
	add_child(_btn_skip)

	# 指示箭头
	_arrow = Label.new()
	_arrow.text = "▼"
	_arrow.add_theme_font_size_override("font_size", 36)
	_arrow.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	_arrow.visible = false
	add_child(_arrow)


func _connect_signals() -> void:
	GameState.state_changed.connect(_on_state_changed)
	var hero := get_tree().get_first_node_in_group("hero")
	if hero:
		hero.hero_moved.connect(_on_hero_moved)
		hero.skill_cd_updated.connect(_on_skill_cd)
	var pm := get_tree().get_first_node_in_group("tower_placement")
	if pm:
		pm.tower_placed.connect(_on_tower_placed)


func _show_step(s: int) -> void:
	_step = s
	if s >= STEPS.size():
		_finish()
		return
	var step: Dictionary = STEPS[s]
	_label.text = step["text"]
	var adv: String = step["advance"]
	_btn_ok.visible = (adv == "ok" or adv == "ok_finish")
	var ap: Vector2 = step["arrow_pos"]
	if ap.x < 0.0:
		_arrow.visible = false
	else:
		_arrow.visible = true
		_arrow.position = ap - Vector2(18.0, 42.0)


func _on_ok() -> void:
	if STEPS[_step]["advance"] == "ok_finish":
		_finish()
	else:
		_show_step(_step + 1)


func _on_hero_moved() -> void:
	if _step == 1:
		_show_step(2)


func _on_tower_placed(_cell: Vector2i) -> void:
	if _step == 2:
		_show_step(3)


func _on_skill_cd(skill: String, _rem: float, _max: float) -> void:
	if _step == 5 and skill == "apex_roar":
		_show_step(6)


func _on_state_changed(s: GameState.State) -> void:
	match _step:
		3:
			if s == GameState.State.WAVE:
				_show_step(4)
		4:
			if s == GameState.State.SHOP or s == GameState.State.BUILD:
				_show_step(5)
		5:
			if s == GameState.State.SHOP:
				_in_shop = true
				_show_step(6)
			elif s == GameState.State.BUILD:
				# 无商店波次，跳过第6步
				_show_step(7)
		6:
			if s != GameState.State.SHOP and _in_shop:
				_in_shop = false
				_show_step(7)


func _finish() -> void:
	var tutorial: Dictionary = SaveLoad.get_value("tutorial", {})
	tutorial["tutorial_completed"] = true
	tutorial["current_step"] = 0
	SaveLoad.set_value("tutorial", tutorial)
	SaveLoad.save_game()
	queue_free()
