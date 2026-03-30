extends CanvasLayer

# ---------------------------------------------------------------------------
# ItemShopPanel — 道具商店
# GDD: shop.md / item-database.md
# SHOP 状态下显示，提供4件随机道具可花金币购买，购买后进入背包
# ---------------------------------------------------------------------------

const REFRESH_COST := 30

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
		_generate_items()
		_refresh_ui()
		visible = true
	else:
		visible = false


func _on_gold_changed(_amount: int) -> void:
	if _label_gold:
		_label_gold.text = "金币：%d" % GameState.gold
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
	title.text = "道具商店"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title)

	_label_gold = Label.new()
	_label_gold.text = "金币：%d" % GameState.gold
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
	_btn_refresh.text = "刷新（%dg）" % REFRESH_COST
	_btn_refresh.custom_minimum_size = Vector2(160, 44)
	_btn_refresh.add_theme_font_size_override("font_size", 16)
	_btn_refresh.pressed.connect(_on_refresh_pressed)
	btn_row.add_child(_btn_refresh)

	var btn_close := Button.new()
	btn_close.text = "继续建造"
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
		_label_gold.text = "金币：%d" % GameState.gold
	_refresh_slots()
	_refresh_slot_states()


func _refresh_slots() -> void:
	for i in range(4):
		var item_id: String = _shop_items[i] if i < _shop_items.size() else ""
		var lbl_name: Label = _slot_labels_name[i]
		var lbl_fx: Label   = _slot_labels_fx[i]
		var btn: Button     = _slot_buttons[i]
		if item_id == "":
			lbl_name.text = "— 无货 —"
			lbl_fx.text   = ""
			btn.text      = "已售"
			btn.disabled  = true
			continue
		var item: Dictionary = ItemDB.get_item(item_id)
		lbl_name.text = item.get("name", item_id)
		lbl_fx.text = _describe_effects(item.get("effects", []))
		btn.text = "购买 %dg" % item.get("price", 0)


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
		_btn_refresh.disabled = GameState.gold < REFRESH_COST


func _describe_effects(effects: Array) -> String:
	var parts: Array = []
	for ef in effects:
		var t: String = ef.get("type", "")
		match t:
			"base_atk":           parts.append("攻击 +%d" % ef.get("value", 0))
			"atk_speed":          parts.append("攻速 +%.0f%%" % (ef.get("value", 0) * 100))
			"hp":                 parts.append("生命 +%d" % ef.get("value", 0))
			"range":              parts.append("射程 +%.1f" % ef.get("value", 0))
			"armor_rate":         parts.append("护甲 +%.0f%%" % (ef.get("value", 0) * 100))
			"pierce_rate":        parts.append("穿透 +%.0f%%" % (ef.get("value", 0) * 100))
			"crit_rate":          parts.append("暴击率 +%.0f%%" % (ef.get("value", 0) * 100))
			"crit_mult":          parts.append("暴伤 +%.0f%%" % (ef.get("value", 0) * 100))
			"on_hit_poison":      parts.append("攻击附毒(%.0f/s)" % ef.get("dps", 0))
			"on_hit_slow":        parts.append("攻击减速 %.0f%%" % (ef.get("ratio", 0) * 100))
			"on_hit_armor_break": parts.append("攻击破甲")
			"on_hit_chain":       parts.append("连锁攻击 %.0f%%" % (ef.get("chance", 0) * 100))
			"on_hit_double":      parts.append("双击 %.0f%%" % (ef.get("chance", 0) * 100))
			"on_hit_mark":        parts.append("标记+伤害")
			"aoe_attack":         parts.append("范围攻击")
			"thorns":             parts.append("反伤 %.0f%%" % (ef.get("ratio", 0) * 100))
			"regen":              parts.append("回血 %d/%.0fs" % [ef.get("hp", 0), ef.get("interval", 5)])
			"ally_aura":          parts.append("光环:攻击+%.0f%%" % (ef.get("atk_bonus", 0) * 100))
			"on_kill_gold":       parts.append("击杀+%d金" % ef.get("value", 0))
			"cooldown_reduction": parts.append("技能CD -%.0f%%" % (ef.get("value", 0) * 100))
			"move_speed":         parts.append("移速 +%.1f" % ef.get("value", 0))
			"last_stand":         parts.append("绝地反击")
			"taunt":              parts.append("嘲讽")
			"soul_link":          parts.append("灵魂链接")
			"wild_instinct":      parts.append("野性本能")
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
	if not GameState.spend_gold(price):
		return
	if not Inventory.add_item(item_id):
		GameState.add_gold(price)
		return
	_shop_items[index] = ""
	_refresh_slots()
	_refresh_slot_states()


func _on_refresh_pressed() -> void:
	if not GameState.spend_gold(REFRESH_COST):
		return
	_generate_items()
	_refresh_slots()
	_refresh_slot_states()


func _on_close_pressed() -> void:
	GameState.change_state(GameState.State.BUILD)
