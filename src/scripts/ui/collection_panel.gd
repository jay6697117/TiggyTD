extends CanvasLayer

# ---------------------------------------------------------------------------
# CollectionPanel — 图鉴面板
# GDD: collection.md
# 从存档读取已解锁条目，网格展示动物/敌人图鉴
# ---------------------------------------------------------------------------

const ANIMALS: Array = [
	{"id": "tiger",       "name": "老虎"},
	{"id": "lion",        "name": "狮子"},
	{"id": "elephant",   "name": "大象"},
	{"id": "cheetah",    "name": "猎豹"},
	{"id": "eagle",      "name": "鹰"},
	{"id": "wolf_pack",  "name": "狼群"},
	{"id": "owl",        "name": "猫头鹰"},
	{"id": "otter",      "name": "水獭"},
	{"id": "peacock",    "name": "孔雀"},
	{"id": "chameleon",  "name": "变色龙"},
	{"id": "honey_badger","name": "蜜獾"},
	{"id": "pangolin",   "name": "穿山甲"},
]

const ENEMIES: Array = [
	{"id": "raptor",      "name": "迅猛龙"},
	{"id": "triceratops", "name": "三角龙"},
	{"id": "mammoth",     "name": "猛犸象"},
	{"id": "pterodactyl", "name": "翼龙"},
	{"id": "ankylosaurus","name": "甲龙"},
	{"id": "sabre_tooth", "name": "剑齿虎"},
	{"id": "giant_sloth", "name": "大地懒"},
	{"id": "doedicurus",  "name": "雕齿兽"},
	{"id": "mosasaurus",  "name": "沧龙"},
	{"id": "ammonite",    "name": "菊石"},
	{"id": "trex_king",   "name": "霸王龙王"},
]

var _tab: int = 0  # 0=动物 1=敌人
var _unlocked: Array = []


func _ready() -> void:
	layer = 80
	var col: Dictionary = SaveLoad.get_value("collection", {})
	_unlocked = col.get("unlocked_entries", [])
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.82)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchor_and_offset(SIDE_LEFT,   0.1, 0.0)
	panel.set_anchor_and_offset(SIDE_RIGHT,  0.9, 0.0)
	panel.set_anchor_and_offset(SIDE_TOP,    0.05, 0.0)
	panel.set_anchor_and_offset(SIDE_BOTTOM, 0.95, 0.0)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "图  鉴"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title)

	var total := ANIMALS.size() + ENEMIES.size()
	var unlocked_count := 0
	for e in _unlocked:
		for a in ANIMALS:
			if a["id"] == e:
				unlocked_count += 1
				break
		for en in ENEMIES:
			if en["id"] == e:
				unlocked_count += 1
				break

	var progress_lbl := Label.new()
	progress_lbl.text = "已解锁 %d / %d" % [unlocked_count, total]
	progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_lbl.add_theme_font_size_override("font_size", 16)
	progress_lbl.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	vbox.add_child(progress_lbl)

	var tab_hbox := HBoxContainer.new()
	tab_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(tab_hbox)

	var btn_animals := Button.new()
	btn_animals.text = "动物（%d）" % ANIMALS.size()
	btn_animals.add_theme_font_size_override("font_size", 16)
	tab_hbox.add_child(btn_animals)

	var btn_enemies := Button.new()
	btn_enemies.text = "敌人（%d）" % ENEMIES.size()
	btn_enemies.add_theme_font_size_override("font_size", 16)
	tab_hbox.add_child(btn_enemies)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	_populate_grid(grid, ANIMALS)

	btn_animals.pressed.connect(func():
		_clear_grid(grid)
		_populate_grid(grid, ANIMALS))

	btn_enemies.pressed.connect(func():
		_clear_grid(grid)
		_populate_grid(grid, ENEMIES))

	var btn_back := Button.new()
	btn_back.text = "返回"
	btn_back.custom_minimum_size = Vector2(160, 40)
	btn_back.add_theme_font_size_override("font_size", 16)
	btn_back.pressed.connect(queue_free)
	vbox.add_child(btn_back)


func _populate_grid(grid: GridContainer, entries: Array) -> void:
	for entry in entries:
		var eid: String = entry["id"]
		var unlocked: bool = eid in _unlocked

		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(140, 80)
		grid.add_child(cell)

		var lbl := Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 15)
		if unlocked:
			lbl.text = entry["name"]
			lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
		else:
			lbl.text = "???"
			lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		cell.add_child(lbl)


func _clear_grid(grid: GridContainer) -> void:
	for child in grid.get_children():
		child.queue_free()
