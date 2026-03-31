extends Control

# ---------------------------------------------------------------------------
# SkillTreePanel — 动物技能树面板
# 依赖：Tower, GameState, Constants
# ---------------------------------------------------------------------------

var _tower: Tower = null
var _buttons: Array = []  # Array[Button]


func show_for(tower: Tower) -> void:
	_tower = tower
	_build_ui()
	visible = true


func _build_ui() -> void:
	for c in get_children():
		c.free()
	_buttons.clear()

	var panel := PanelContainer.new()
	panel.anchor_left   = 0.5
	panel.anchor_right  = 0.5
	panel.anchor_top    = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left   = -130.0
	panel.offset_right  =  130.0
	panel.offset_top    = -110.0
	panel.offset_bottom =  110.0
	add_child(panel)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	# 标题行
	var title_row := HBoxContainer.new()
	vbox.add_child(title_row)
	var title := Label.new()
	title.text = Localization.L("ui.skill_tree", [Localization.L("animal." + _tower.animal_id + ".name")])
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.pressed.connect(_on_close)
	title_row.add_child(close_btn)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# 已装备道具
	var equip_lbl := Label.new()
	if _tower.equipped_item != "":
		var item: Dictionary = ItemDB.get_item(_tower.equipped_item)
		equip_lbl.text = Localization.L("ui.equipped", [item.get("name", _tower.equipped_item)])
		equip_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	else:
		equip_lbl.text = Localization.L("ui.no_equip")
		equip_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(equip_lbl)

	# 升级按钮
	var upgrade_btn := Button.new()
	if _tower.can_upgrade():
		var ucost := _tower.upgrade_cost()
		upgrade_btn.text = Localization.L("ui.upgrade_btn", [_tower.level + 1, ucost])
		upgrade_btn.disabled = GameState.gold < ucost
		upgrade_btn.pressed.connect(_on_upgrade)
	else:
		upgrade_btn.text = Localization.L("ui.max_level_btn", [_tower.level])
		upgrade_btn.disabled = true
	vbox.add_child(upgrade_btn)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	if not Tower.SKILL_TREE_DB.has(_tower.animal_id):
		var lbl := Label.new()
		lbl.text = Localization.L("ui.no_skill_tree")
		vbox.add_child(lbl)
		return

	var nodes: Array = Tower.SKILL_TREE_DB[_tower.animal_id]
	for node_def in nodes:
		var btn := Button.new()
		_configure_button(btn, node_def)
		vbox.add_child(btn)
		_buttons.append({"btn": btn, "def": node_def})



func _configure_button(btn: Button, node_def: Dictionary) -> void:
	var nid: String    = node_def["id"]
	var label: String  = node_def["label"]
	var cost: int      = node_def["cost"]
	if GameState.has_meta_node("build_skill_disc"):
		cost = int(cost * 0.9)
	var prereq: String = node_def["prereq"]
	var mutex: String  = node_def["mutex"]

	var unlocked: bool = nid in _tower.unlocked_skills
	var prereq_ok: bool = prereq == "" or prereq in _tower.unlocked_skills
	var mutex_ok: bool  = mutex == "" or not (mutex in _tower.unlocked_skills)
	var can_afford: bool = GameState.gold >= cost

	if unlocked:
		btn.text = Localization.L("ui.unlocked_skill", [label])
		btn.disabled = true
		btn.modulate = Color(0.5, 1.0, 0.5)
	elif not prereq_ok or not mutex_ok:
		btn.text = "%s  (%dg)" % [label, cost]
		btn.disabled = true
		btn.modulate = Color(0.5, 0.5, 0.5)
	else:
		btn.text = "%s  (%dg)" % [label, cost]
		btn.disabled = not can_afford
		btn.modulate = Color.WHITE
		btn.pressed.connect(_on_unlock.bind(nid, cost))


func _on_unlock(node_id: String, cost: int) -> void:
	if not GameState.spend_gold(cost):
		return
	_tower.unlock_skill(node_id)
	# 重建 UI 刷新状态
	_build_ui()


func _on_upgrade() -> void:
	if not _tower.can_upgrade():
		return
	var cost := _tower.upgrade_cost()
	if GameState.spend_gold(cost):
		_tower.upgrade()
		_build_ui()


func _on_close() -> void:
	visible = false
	_tower = null
