extends CanvasLayer

# ---------------------------------------------------------------------------
# InventoryPanel — 背包界面
# GDD: item-equipment.md
# BUILD 状态下按 I 键或 HUD 按钮开关；6格网格；点击道具→选择塔装备
# ---------------------------------------------------------------------------

const SLOTS := 6

var _slot_buttons: Array = []
var _slot_labels: Array = []
var _pending_item: String = ""
var _hint_label: Label


func _ready() -> void:
	layer = 75
	Inventory.inventory_changed.connect(_refresh)
	GameState.state_changed.connect(_on_state_changed)
	_build_ui()
	visible = false


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.65)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchor_and_offset(SIDE_LEFT,   0.20, 0.0)
	panel.set_anchor_and_offset(SIDE_RIGHT,  0.80, 0.0)
	panel.set_anchor_and_offset(SIDE_TOP,    0.25, 0.0)
	panel.set_anchor_and_offset(SIDE_BOTTOM, 0.75, 0.0)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = Localization.L("ui.inventory")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title)

	_hint_label = Label.new()
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 13)
	_hint_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	_hint_label.text = ""
	vbox.add_child(_hint_label)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox)

	for i in range(SLOTS):
		_build_slot(hbox, i)

	var btn_close := Button.new()
	btn_close.text = Localization.L("ui.close_i")
	btn_close.custom_minimum_size = Vector2(140, 40)
	btn_close.add_theme_font_size_override("font_size", 16)
	btn_close.pressed.connect(_close)
	vbox.add_child(btn_close)



func _build_slot(parent: Node, index: int) -> void:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(96, 96)
	parent.add_child(pc)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	pc.add_child(vb)

	var lbl := Label.new()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(88, 0)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8))
	vb.add_child(lbl)

	var btn := Button.new()
	btn.text = Localization.L("ui.equip")
	btn.custom_minimum_size = Vector2(80, 30)
	btn.add_theme_font_size_override("font_size", 12)
	btn.visible = false
	btn.pressed.connect(_on_equip_pressed.bind(index))
	vb.add_child(btn)

	_slot_labels.append(lbl)
	_slot_buttons.append(btn)


func _refresh() -> void:
	var items := Inventory.get_items()
	for i in range(SLOTS):
		var lbl: Label  = _slot_labels[i]
		var btn: Button = _slot_buttons[i]
		if i < items.size():
			var item_id: String = items[i]
			var item: Dictionary = ItemDB.get_item(item_id)
			lbl.text = item.get("name", item_id)
			lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8))
			btn.visible = true
		else:
			lbl.text = Localization.L("ui.empty_slot")
			lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			btn.visible = false
	# 如果正在选择目标，刷新时保持提示
	if _pending_item != "":
		_hint_label.text = Localization.L("ui.equip_hint")


func _on_equip_pressed(index: int) -> void:
	var items := Inventory.get_items()
	if index >= items.size():
		return
	var item_id: String = items[index]
	_pending_item = item_id
	_hint_label.text = Localization.L("ui.equip_hint_item", [ItemDB.get_item(item_id).get("name", item_id)])
	# 通知 TowerPlacementManager 进入装备模式
	var tpm := get_tree().get_first_node_in_group("tower_placement")
	if tpm and tpm.has_method("enter_equip_mode"):
		tpm.enter_equip_mode(item_id)
	_close()


func _on_state_changed(new_state: GameState.State) -> void:
	if new_state != GameState.State.BUILD:
		visible = false
		_pending_item = ""


func _input(event: InputEvent) -> void:
	if GameState.current_state != GameState.State.BUILD:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I:
			if visible:
				_close()
			else:
				_open()
			get_viewport().set_input_as_handled()


func _open() -> void:
	_pending_item = ""
	_hint_label.text = ""
	_refresh()
	visible = true


func _close() -> void:
	visible = false
