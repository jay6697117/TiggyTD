extends CanvasLayer

# ---------------------------------------------------------------------------
# TalentPanel — 英雄升级天赋选择面板
# 游戏暂停期间显示，玩家3选1
# ---------------------------------------------------------------------------

const TALENT_TEXT: Dictionary = {
	"apex_duration": {"name": "猛虎咆哮强化", "desc": "百兽怒吼持续时间 +4秒"},
	"apex_cd":       {"name": "猛虎咆哮扩散", "desc": "百兽怒吼冷却 -10秒"},
	"natures_atk":   {"name": "自然之召强化", "desc": "自然之召攻击加成 +10%"},
	"natures_range": {"name": "自然之召扩散", "desc": "自然之召范围 +2格"},
	"era_dmg":       {"name": "纪元审判强化", "desc": "纪元审判伤害 +150"},
	"era_cd":        {"name": "纪元审判扩散", "desc": "纪元审判冷却 -30秒"},
	"aura_range":    {"name": "光环扩展",     "desc": "英雄光环半径 +2格"},
	"aura_bonus":    {"name": "光环增幅",     "desc": "英雄光环攻速加成 +10%"},
	"speed":         {"name": "迅捷图腾",     "desc": "英雄移动速度 +30%"},
	"vision":        {"name": "战场感知",     "desc": "英雄视野范围 +3格"},
	"gold_touch":    {"name": "黄金触碰",     "desc": "每击杀10只敌人额外+5金币"},
	"base_hp":       {"name": "韧性图腾",     "desc": "基地HP上限 +2"},
}

var _hero: Hero = null


func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func show_choices(choices: Array[String], hero: Hero) -> void:
	_hero = hero
	_build_ui(choices)
	visible = true
	get_tree().paused = true


func _build_ui(choices: Array[String]) -> void:
	for c in get_children():
		c.free()

	# 半透明遮罩
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.65)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(overlay)

	# 中央容器
	var center := PanelContainer.new()
	center.anchor_left   = 0.5
	center.anchor_right  = 0.5
	center.anchor_top    = 0.5
	center.anchor_bottom = 0.5
	center.offset_left   = -320.0
	center.offset_right  =  320.0
	center.offset_top    = -160.0
	center.offset_bottom =  160.0
	center.process_mode  = Node.PROCESS_MODE_ALWAYS
	add_child(center)

	var vbox := VBoxContainer.new()
	center.add_child(vbox)

	var title := Label.new()
	title.text = "英雄升级！选择天赋"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(hbox)

	for talent_id in choices:
		var card := _make_card(talent_id)
		hbox.add_child(card)


func _make_card(talent_id: String) -> PanelContainer:
	var info: Dictionary = TALENT_TEXT.get(talent_id, {"name": talent_id, "desc": ""})
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(160.0, 100.0)
	card.process_mode = Node.PROCESS_MODE_ALWAYS

	var inner := VBoxContainer.new()
	card.add_child(inner)

	var name_lbl := Label.new()
	name_lbl.text = info["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 15)
	inner.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = info["desc"]
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 12)
	inner.add_child(desc_lbl)

	var btn := Button.new()
	btn.text = "选择"
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.pressed.connect(_on_chosen.bind(talent_id))
	inner.add_child(btn)

	return card


func _on_chosen(talent_id: String) -> void:
	get_tree().paused = false
	visible = false
	if _hero != null:
		_hero.apply_talent(talent_id)
	_hero = null
