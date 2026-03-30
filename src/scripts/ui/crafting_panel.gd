extends CanvasLayer

# ---------------------------------------------------------------------------
# CraftingPanel — 道具合成台
# GDD: item-crafting.md
# BUILD/SHOP 状态下可通过背包 UI 打开；显示全部配方，可合成者高亮
# ---------------------------------------------------------------------------


func _ready() -> void:
	layer = 85
	Inventory.inventory_changed.connect(_refresh)
	_build_ui()
	_refresh()


var _recipes_container: VBoxContainer
var _label_inv: Label


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.80)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchor_and_offset(SIDE_LEFT,   0.15, 0.0)
	panel.set_anchor_and_offset(SIDE_RIGHT,  0.85, 0.0)
	panel.set_anchor_and_offset(SIDE_TOP,    0.08, 0.0)
	panel.set_anchor_and_offset(SIDE_BOTTOM, 0.92, 0.0)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "合  成  台"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title)

	_label_inv = Label.new()
	_label_inv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_inv.add_theme_font_size_override("font_size", 13)
	_label_inv.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(_label_inv)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 400)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_recipes_container = VBoxContainer.new()
	_recipes_container.add_theme_constant_override("separation", 8)
	scroll.add_child(_recipes_container)

	var btn_close := Button.new()
	btn_close.text = "关闭"
	btn_close.custom_minimum_size = Vector2(140, 40)
	btn_close.add_theme_font_size_override("font_size", 16)
	btn_close.pressed.connect(queue_free)
	vbox.add_child(btn_close)


func _refresh() -> void:
	if _label_inv == null:
		return
	var items := Inventory.get_items()
	_label_inv.text = "背包：%d / %d" % [items.size(), Inventory.CAPACITY]

	for child in _recipes_container.get_children():
		child.queue_free()

	var recipes: Array = ItemDB.get_crafting_recipes()
	for recipe in recipes:
		_build_recipe_row(recipe)


func _build_recipe_row(recipe: Dictionary) -> void:
	var mat_a: String = recipe.get("mat_a", "")
	var mat_b: String = recipe.get("mat_b", "")
	var result_id: String = recipe.get("result", "")

	var item_a: Dictionary = ItemDB.get_item(mat_a)
	var item_b: Dictionary = ItemDB.get_item(mat_b)
	var item_r: Dictionary = ItemDB.get_item(result_id)

	var has_a: bool = Inventory.has_item(mat_a)
	var has_b: bool = Inventory.has_item(mat_b)
	var both_same: bool = (mat_a == mat_b)
	var can_craft: bool
	if both_same:
		can_craft = Inventory.count_item(mat_a) >= 2 and Inventory.free_slots() >= 1
	else:
		can_craft = has_a and has_b and Inventory.free_slots() >= 1

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_recipes_container.add_child(row)

	# 配方说明标签
	var lbl := Label.new()
	var name_a: String = item_a.get("name", mat_a)
	var name_b: String = item_b.get("name", mat_b)
	var name_r: String = item_r.get("name", result_id)
	lbl.text = "%s + %s  →  %s" % [name_a, name_b, name_r]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 14)
	if can_craft:
		lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	else:
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		if not has_a:
			lbl.text += "  [缺 %s]" % name_a
		elif not has_b:
			lbl.text += "  [缺 %s]" % name_b
	row.add_child(lbl)

	# 合成按钮
	var btn := Button.new()
	btn.text = "合成"
	btn.custom_minimum_size = Vector2(70, 32)
	btn.disabled = not can_craft
	btn.pressed.connect(_on_craft_pressed.bind(mat_a, mat_b, result_id))
	row.add_child(btn)


func _on_craft_pressed(mat_a: String, mat_b: String, result_id: String) -> void:
	var both_same := (mat_a == mat_b)
	if both_same:
		if Inventory.count_item(mat_a) < 2 or Inventory.free_slots() < 1:
			return
		Inventory.remove_item(mat_a)
		Inventory.remove_item(mat_a)
	else:
		if not Inventory.has_item(mat_a) or not Inventory.has_item(mat_b) or Inventory.free_slots() < 1:
			return
		Inventory.remove_item(mat_a)
		Inventory.remove_item(mat_b)
	Inventory.add_item(result_id)
	CollectionManager.on_animal_placed(result_id)  # 合成道具也解锁图鉴（复用接口）
