extends CanvasLayer

# ---------------------------------------------------------------------------
# LevelSelectPanel — 关卡选择面板
# GDD: level-select.md
# 从存档读取 level_progress，显示3张地图；已解锁可进入，锁定置灰
# ---------------------------------------------------------------------------

const LEVEL_NAMES: Dictionary = {
	"ancient_savanna": "远古草原",
	"lava_canyon":     "熔岩峡谷",
	"frozen_tundra":   "冰封冻原",
}

const LEVEL_DESCS: Dictionary = {
	"ancient_savanna": "10波史前生物，经典入门关卡",
	"lava_canyon":     "地形复杂，熔岩地带限制建造（待解锁）",
	"frozen_tundra":   "极寒环境，敌人移速加成（待解锁）",
}


func _ready() -> void:
	layer = 80
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.82)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchor_and_offset(SIDE_LEFT,   0.15, 0.0)
	panel.set_anchor_and_offset(SIDE_RIGHT,  0.85, 0.0)
	panel.set_anchor_and_offset(SIDE_TOP,    0.1,  0.0)
	panel.set_anchor_and_offset(SIDE_BOTTOM, 0.9,  0.0)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "选择关卡"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title)

	var levels: Array = SaveLoad.get_value("level_progress", [])
	var level_map: Dictionary = {}
	for entry in levels:
		level_map[entry.get("level_id", "")] = entry

	for lid in ["ancient_savanna", "lava_canyon", "frozen_tundra"]:
		var entry: Dictionary = level_map.get(lid, {"level_id": lid, "status": "LOCKED", "best_result": {}})
		_add_level_card(vbox, lid, entry)

	var btn_back := Button.new()
	btn_back.text = "返回主菜单"
	btn_back.custom_minimum_size = Vector2(200, 44)
	btn_back.add_theme_font_size_override("font_size", 18)
	btn_back.pressed.connect(queue_free)
	vbox.add_child(btn_back)


func _add_level_card(parent: Node, lid: String, entry: Dictionary) -> void:
	var unlocked: bool = entry.get("status", "LOCKED") == "UNLOCKED"
	var best: Dictionary = entry.get("best_result", {})

	var card := PanelContainer.new()
	parent.add_child(card)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	card.add_child(hbox)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = LEVEL_NAMES.get(lid, lid)
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color",
		Color(1.0, 0.9, 0.5) if unlocked else Color(0.5, 0.5, 0.5))
	info.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = LEVEL_DESCS.get(lid, "")
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(desc_lbl)

	if unlocked and best.get("waves_survived", 0) > 0:
		var best_lbl := Label.new()
		best_lbl.text = "最佳：%d波 基地HP %d" % [
			best.get("waves_survived", 0), best.get("base_hp_remaining", 0)]
		best_lbl.add_theme_font_size_override("font_size", 13)
		best_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
		info.add_child(best_lbl)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(120, 44)
	btn.add_theme_font_size_override("font_size", 18)
	if unlocked:
		btn.text = "进入"
		btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
		btn.pressed.connect(_on_level_selected.bind(lid))
	else:
		btn.text = "锁定"
		btn.disabled = true
		btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hbox.add_child(btn)


func _on_level_selected(lid: String) -> void:
	GameState.current_level_id = lid
	queue_free()
	GameState.change_state(GameState.State.BUILD)
