extends CanvasLayer

# ---------------------------------------------------------------------------
# TotemTemplePanel — 图腾神殿：跨局永久解锁面板
# GDD: meta-progression.md
# 由 GameOverPanel 调用显示；购买后立即持久化，下局生效
# ---------------------------------------------------------------------------

const TOTEM_NODES: Array = [
	{"id": "eco_gold",         "label": "初始金币 +20",       "cost": 15,  "category": "经济"},
	{"id": "eco_shop_discount","label": "商店刷新费 30→25",   "cost": 25,  "category": "经济"},
	{"id": "eco_kill_gold",    "label": "击杀金币 +1/敌",     "cost": 30,  "category": "经济"},
	{"id": "combat_base_hp",   "label": "初始基地 HP +2",     "cost": 20,  "category": "战斗"},
	{"id": "combat_hero_speed","label": "英雄移速 +10%",      "cost": 15,  "category": "战斗"},
	{"id": "combat_skill_cd",  "label": "技能 CD -10%",       "cost": 30,  "category": "战斗"},
	{"id": "build_skill_disc", "label": "技能树费用 -10%",    "cost": 25,  "category": "Build"},
	{"id": "build_free_item",  "label": "商店首件道具免费",   "cost": 40,  "category": "Build"},
	{"id": "build_bag_slot",   "label": "初始背包 +1 格",     "cost": 20,  "category": "Build"},
	{"id": "unlock_map2",      "label": "解锁第2张地图",      "cost": 50,  "category": "解锁"},
	{"id": "unlock_hard",      "label": "解锁困难难度",       "cost": 60,  "category": "解锁"},
	{"id": "unlock_hero2",     "label": "解锁新英雄（预留）", "cost": 80,  "category": "解锁"},
]

var _label_marks: Label
var _buttons: Array = []


func _ready() -> void:
	layer = 90
	_build_ui()


func _build_ui() -> void:
	# 半透明背景
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.03, 0.92)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# 主容器
	var panel := PanelContainer.new()
	panel.anchor_left   = 0.05
	panel.anchor_right  = 0.95
	panel.anchor_top    = 0.04
	panel.anchor_bottom = 0.96
	add_child(panel)

	var root_vbox := VBoxContainer.new()
	panel.add_child(root_vbox)

	# 标题行
	var title := Label.new()
	title.text = "图腾神殿"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	root_vbox.add_child(title)

	# 印记余额
	_label_marks = Label.new()
	_label_marks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_marks.add_theme_font_size_override("font_size", 18)
	root_vbox.add_child(_label_marks)

	# 节点网格（4列×3行）
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(grid)

	for node_data in TOTEM_NODES:
		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		btn.text = "[%s]\n%s\n花费：%d 印记" % [
			node_data["category"],
			node_data["label"],
			node_data["cost"]
		]
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.pressed.connect(_on_node_pressed.bind(node_data["id"], node_data["cost"]))
		grid.add_child(btn)
		_buttons.append({"id": node_data["id"], "btn": btn, "cost": node_data["cost"]})

	# 关闭按钮
	var btn_close := Button.new()
	btn_close.text = "关闭"
	btn_close.add_theme_font_size_override("font_size", 20)
	btn_close.pressed.connect(queue_free)
	root_vbox.add_child(btn_close)

	_refresh()


func _refresh() -> void:
	var meta: Dictionary = SaveLoad.get_value("meta_progression", {})
	var marks: int = meta.get("ancient_marks", GameState.ancient_marks)
	var unlocked: Array = meta.get("unlocked_nodes", [])
	_label_marks.text = "古代印记余额：%d" % marks
	for entry in _buttons:
		var btn: Button = entry["btn"]
		var is_unlocked: bool = entry["id"] in unlocked
		var can_afford: bool = marks >= entry["cost"]
		btn.disabled = is_unlocked or not can_afford
		if is_unlocked:
			btn.modulate = Color(0.5, 0.5, 0.5)
			# 已解锁标记
			if not btn.text.ends_with(" ✓"):
				btn.text += "\n✓ 已解锁"
		else:
			btn.modulate = Color.WHITE if can_afford else Color(0.7, 0.7, 0.7)


func _on_node_pressed(node_id: String, cost: int) -> void:
	var meta: Dictionary = SaveLoad.get_value("meta_progression", {})
	var marks: int = meta.get("ancient_marks", GameState.ancient_marks)
	var unlocked: Array = meta.get("unlocked_nodes", [])
	if node_id in unlocked or marks < cost:
		return
	marks -= cost
	unlocked.append(node_id)
	meta["ancient_marks"] = marks
	meta["unlocked_nodes"] = unlocked
	SaveLoad.set_value("meta_progression", meta)
	SaveLoad.save_game()
	# 同步运行时印记显示
	GameState.ancient_marks = marks
	GameState.ancient_marks_changed.emit(marks)
	_refresh()
