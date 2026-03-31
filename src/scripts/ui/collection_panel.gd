extends CanvasLayer

# ---------------------------------------------------------------------------
# CollectionPanel — 图鉴面板
# GDD: collection.md
# 从存档读取已解锁条目，网格展示动物/敌人图鉴
# ---------------------------------------------------------------------------

const ANIMALS: Array = [
	"tiger", "lion", "elephant", "cheetah", "eagle",
	"wolf_pack", "owl", "otter", "peacock", "chameleon",
	"honey_badger", "pangolin",
]

const ENEMIES: Array = [
	"raptor", "triceratops", "mammoth", "pterodactyl", "ankylosaurus",
	"sabre_tooth", "giant_sloth", "doedicurus", "mosasaurus", "ammonite",
	"trex_king",
]

var _tab: int = 0  # 0=动物 1=敌人 2=道具
var _unlocked: Array = []
var _seen_items: Array = []


func _ready() -> void:
	layer = 80
	var col: Dictionary = SaveLoad.get_value("collection", {})
	_unlocked = col.get("unlocked_entries", [])
	_seen_items = col.get("seen_items", [])
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
	title.text = Localization.L("ui.collection")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title)

	var total := ANIMALS.size() + ENEMIES.size()
	var all_ids := ANIMALS + ENEMIES
	var unlocked_count := 0
	for e in _unlocked:
		if e in all_ids:
			unlocked_count += 1

	var progress_lbl := Label.new()
	progress_lbl.text = Localization.L("ui.collection_progress", [str(unlocked_count), str(total)])
	progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_lbl.add_theme_font_size_override("font_size", 16)
	progress_lbl.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	vbox.add_child(progress_lbl)

	var tab_hbox := HBoxContainer.new()
	tab_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(tab_hbox)

	var btn_animals := Button.new()
	btn_animals.text = Localization.L("ui.collection_tab_animals", [str(ANIMALS.size())])
	btn_animals.add_theme_font_size_override("font_size", 16)
	tab_hbox.add_child(btn_animals)

	var btn_enemies := Button.new()
	btn_enemies.text = Localization.L("ui.collection_tab_enemies", [str(ENEMIES.size())])
	btn_enemies.add_theme_font_size_override("font_size", 16)
	tab_hbox.add_child(btn_enemies)

	var btn_items := Button.new()
	btn_items.text = Localization.L("ui.collection_tab_items", [str(ItemDB.get_all_ids().size())])
	btn_items.add_theme_font_size_override("font_size", 16)
	tab_hbox.add_child(btn_items)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	_populate_grid(grid, ANIMALS, "animal.")

	btn_animals.pressed.connect(func():
		_clear_grid(grid)
		_populate_grid(grid, ANIMALS, "animal."))

	btn_enemies.pressed.connect(func():
		_clear_grid(grid)
		_populate_grid(grid, ENEMIES, "enemy."))

	btn_items.pressed.connect(func():
		_clear_grid(grid)
		_populate_items_grid(grid))

	var btn_back := Button.new()
	btn_back.text = Localization.L("ui.back")
	btn_back.custom_minimum_size = Vector2(160, 40)
	btn_back.add_theme_font_size_override("font_size", 16)
	btn_back.pressed.connect(queue_free)
	vbox.add_child(btn_back)


func _populate_grid(grid: GridContainer, entries: Array, prefix: String) -> void:
	for eid in entries:
		var unlocked: bool = eid in _unlocked

		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(140, 80)
		grid.add_child(cell)

		var lbl := Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 15)
		if unlocked:
			lbl.text = Localization.L(prefix + eid + ".name")
			lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
		else:
			lbl.text = "???"
			lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		cell.add_child(lbl)


func _populate_items_grid(grid: GridContainer) -> void:
	for item_id in ItemDB.get_all_ids():
		var item: Dictionary = ItemDB.get_item(item_id)
		var seen: bool = item_id in _seen_items
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(140, 80)
		grid.add_child(cell)
		var lbl := Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		if seen:
			var tier: int = item.get("tier", 1)
			if tier >= 2:
				lbl.text = item.get("name", item_id) + "\n★"
				lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
			else:
				lbl.text = item.get("name", item_id)
				lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
		else:
			lbl.text = "???"
			lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		cell.add_child(lbl)


func _clear_grid(grid: GridContainer) -> void:
	for child in grid.get_children():
		child.queue_free()
