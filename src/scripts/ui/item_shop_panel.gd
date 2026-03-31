extends CanvasLayer

# ---------------------------------------------------------------------------
# ItemShopPanel — 道具商店
# GDD: shop.md / item-database.md
# SHOP 状态下显示，提供4件随机道具可花金币购买，购买后进入背包
# ---------------------------------------------------------------------------

var _refresh_cost: int = 30
var _first_free_used: bool = false

var _shop_items: Array = []
var _slot_labels_name: Array = []
var _slot_labels_fx: Array = []
var _slot_buttons: Array = []
var _label_gold: Label
var _btn_refresh: Button


func _ready() -> void:
	layer = 70
	GameState.state_changed.connect(_on_state_changed)
	GameState.gold_changed.connect(_on_gold_changed)
	Inventory.inventory_changed.connect(_refresh_slot_states)
	_build_ui()
	_on_state_changed(GameState.current_state)


func _on_state_changed(new_state: GameState.State) -> void:
	if new_state == GameState.State.SHOP:
		_refresh_cost = 25 if GameState.has_meta_node("eco_shop_discount") else 30
		_first_free_used = false
		_generate_items()
		_refresh_ui()
		visible = true
	else:
		visible = false


func _on_gold_changed(_amount: int) -> void:
	if _label_gold:
		_label_gold.text = Localization.L("ui.gold_amount", [GameState.gold])
	_refresh_slot_states()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchor_and_offset(SIDE_LEFT,   0.1, 0.0)
	panel.set_anchor_and_offset(SIDE_RIGHT,  0.9, 0.0)
	panel.set_anchor_and_offset(SIDE_TOP,    0.15, 0.0)
	panel.set_anchor_and_offset(SIDE_BOTTOM, 0.85, 0.0)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = Localization.L("ui.item_shop.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title)

	_label_gold = Label.new()
	_label_gold.text = Localization.L("ui.gold_amount", [GameState.gold])
	_label_gold.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_gold.add_theme_font_size_override("font_size", 16)
	_label_gold.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	vbox.add_child(_label_gold)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(hbox)

	for i in range(4):
		_build_slot(hbox, i)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	_btn_refresh = Button.new()
	_btn_refresh.text = Localization.L("ui.shop_refresh", [_refresh_cost])
	_btn_refresh.custom_minimum_size = Vector2(160, 44)
	_btn_refresh.add_theme_font_size_override("font_size", 16)
	_btn_refresh.pressed.connect(_on_refresh_pressed)
	btn_row.add_child(_btn_refresh)

	var btn_close := Button.new()
	btn_close.text = Localization.L("ui.shop_continue")
	btn_close.custom_minimum_size = Vector2(160, 44)
	btn_close.add_theme_font_size_override("font_size", 16)
	btn_close.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	btn_close.pressed.connect(_on_close_pressed)
	btn_row.add_child(btn_close)


func _build_slot(parent: Node, index: int) -> void:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(168, 170)
	parent.add_child(pc)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 6)
	pc.add_child(vb)

	var lbl_name := Label.new()
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_name.add_theme_font_size_override("font_size", 14)
	lbl_name.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8))
	vb.add_child(lbl_name)

	var lbl_fx := Label.new()
	lbl_fx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_fx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_fx.custom_minimum_size = Vector2(150, 0)
	lbl_fx.add_theme_font_size_override("font_size", 11)
	lbl_fx.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vb.add_child(lbl_fx)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(120, 36)
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(_on_buy_pressed.bind(index))
	vb.add_child(btn)

	_slot_labels_name.append(lbl_name)
	_slot_labels_fx.append(lbl_fx)
	_slot_buttons.append(btn)


func _generate_items() -> void:
	_shop_items.clear()
	# 按 shop_weight 构建加权池，shuffle 后取前4个唯一道具
	var weighted_pool: Array = []
	for id in ItemDB.get_shop_pool():
		var w: int = ItemDB.get_item(id).get("shop_weight", 1)
		for _i in range(w):
			weighted_pool.append(id)
	weighted_pool.shuffle()
	var seen: Dictionary = {}
	for id in weighted_pool:
		if _shop_items.size() >= 4:
			break
		if id not in seen:
			seen[id] = true
			_shop_items.append(id)
	while _shop_items.size() < 4:
		_shop_items.append("")


func _refresh_ui() -> void:
	if _label_gold:
		_label_gold.text = Localization.L("ui.gold_amount", [GameState.gold])
	if _btn_refresh:
		_btn_refresh.text = Localization.L("ui.shop_refresh", [_refresh_cost])
	_refresh_slots()
	_refresh_slot_states()


func _refresh_slots() -> void:
	for i in range(4):
		var item_id: String = _shop_items[i] if i < _shop_items.size() else ""
		var lbl_name: Label = _slot_labels_name[i]
		var lbl_fx: Label   = _slot_labels_fx[i]
		var btn: Button     = _slot_buttons[i]
		if item_id == "":
			lbl_name.text = Localization.L("ui.item_shop.out_of_stock")
			lbl_fx.text   = ""
			btn.text      = Localization.L("ui.item_shop.sold_out")
			btn.disabled  = true
			continue
		var item: Dictionary = ItemDB.get_item(item_id)
		lbl_name.text = item.get("name", item_id)
		lbl_fx.text = _describe_effects(item.get("effects", []))
		btn.text = Localization.L("ui.item_shop.buy", [item.get("price", 0)])


func _refresh_slot_states() -> void:
	for i in range(4):
		var item_id: String = _shop_items[i] if i < _shop_items.size() else ""
		var btn: Button = _slot_buttons[i]
		if item_id == "":
			btn.disabled = true
			continue
		var item: Dictionary = ItemDB.get_item(item_id)
		var price: int = item.get("price", 0)
		var can_buy: bool = (GameState.gold >= price) and not Inventory.is_full()
		btn.disabled = not can_buy
		btn.modulate = Color.WHITE if can_buy else Color(0.6, 0.6, 0.6)
	if _btn_refresh:
		_btn_refresh.disabled = GameState.gold < _refresh_cost


func _describe_effects(effects: Array) -> String:
	var parts: Array = []
	for ef in effects:
		var t: String = ef.get("type", "")
		var key := "item.effect." + t
		match t:
			"base_atk":           parts.append(Localization.L(key, [str(ef.get("value", 0))]))
			"atk_speed":          parts.append(Localization.L(key, ["%.0f" % (ef.get("value", 0) * 100)]))
			"hp":                 parts.append(Localization.L(key, [str(ef.get("value", 0))]))
			"range":              parts.append(Localization.L(key, ["%.1f" % ef.get("value", 0)]))
			"armor_rate":         parts.append(Localization.L(key, ["%.0f" % (ef.get("value", 0) * 100)]))
			"pierce_rate":        parts.append(Localization.L(key, ["%.0f" % (ef.get("value", 0) * 100)]))
			"crit_rate":          parts.append(Localization.L(key, ["%.0f" % (ef.get("value", 0) * 100)]))
			"crit_mult":          parts.append(Localization.L(key, ["%.0f" % (ef.get("value", 0) * 100)]))
			"on_hit_poison":      parts.append(Localization.L(key, ["%.0f" % ef.get("dps", 0)]))
			"on_hit_slow":        parts.append(Localization.L(key, ["%.0f" % (ef.get("ratio", 0) * 100)]))
			"on_hit_armor_break": parts.append(Localization.L(key))
			"on_hit_chain":       parts.append(Localization.L(key, ["%.0f" % (ef.get("chance", 0) * 100)]))
			"on_hit_double":      parts.append(Localization.L(key, ["%.0f" % (ef.get("chance", 0) * 100)]))
			"on_hit_mark":        parts.append(Localization.L(key))
			"aoe_attack":         parts.append(Localization.L(key))
			"thorns":             parts.append(Localization.L(key, ["%.0f" % (ef.get("ratio", 0) * 100)]))
			"regen":              parts.append(Localization.L(key, [str(ef.get("hp", 0)), "%.0f" % ef.get("interval", 5)]))
			"ally_aura":          parts.append(Localization.L(key, ["%.0f" % (ef.get("atk_bonus", 0) * 100)]))
			"on_kill_gold":       parts.append(Localization.L(key, [str(ef.get("value", 0))]))
			"cooldown_reduction": parts.append(Localization.L(key, ["%.0f" % (ef.get("value", 0) * 100)]))
			"move_speed":         parts.append(Localization.L(key, ["%.1f" % ef.get("value", 0)]))
			"last_stand":         parts.append(Localization.L(key))
			"taunt":              parts.append(Localization.L(key))
			"soul_link":          parts.append(Localization.L(key))
			"wild_instinct":      parts.append(Localization.L(key))
			_:                    parts.append(t)
	return "\n".join(parts)


func _on_buy_pressed(index: int) -> void:
	if index >= _shop_items.size():
		return
	var item_id: String = _shop_items[index]
	if item_id == "":
		return
	var item: Dictionary = ItemDB.get_item(item_id)
	var price: int = item.get("price", 0)
	var is_free := GameState.has_meta_node("build_free_item") and not _first_free_used
	if not is_free and not GameState.spend_gold(price):
		return
	if not Inventory.add_item(item_id):
		if not is_free:
			GameState.add_gold(price)
		return
	if is_free:
		_first_free_used = true
	_shop_items[index] = ""
	_refresh_slots()
	_refresh_slot_states()


func _on_refresh_pressed() -> void:
	if not GameState.spend_gold(_refresh_cost):
		return
	_generate_items()
	_refresh_slots()
	_refresh_slot_states()


func _on_close_pressed() -> void:
	GameState.change_state(GameState.State.BUILD)
