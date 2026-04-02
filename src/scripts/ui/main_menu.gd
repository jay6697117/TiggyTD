extends CanvasLayer

# ---------------------------------------------------------------------------
# MainMenu — 主菜单
# MAIN_MENU 状态下显示；提供开始游戏/图腾神殿/图鉴/退出入口
# ---------------------------------------------------------------------------

var _marks_label: Label


func _ready() -> void:
	layer = 50
	_build_ui()
	GameState.state_changed.connect(_on_state_changed)
	_on_state_changed(GameState.current_state)


func _build_ui() -> void:
	# 背景图
	var bg := TextureRect.new()
	var bg_tex = load("res://assets/art/backgrounds/bg_main_menu.png")
	if bg_tex:
		bg.texture = bg_tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# 半透明遮罩，保证文字可读
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.45)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := VBoxContainer.new()
	center.set_anchor_and_offset(SIDE_LEFT,   0.3,  0.0)
	center.set_anchor_and_offset(SIDE_RIGHT,  0.7,  0.0)
	center.set_anchor_and_offset(SIDE_TOP,    0.2,  0.0)
	center.set_anchor_and_offset(SIDE_BOTTOM, 0.95, 0.0)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 20)
	add_child(center)

	# 标题
	var title := Label.new()
	title.text = "TiggyTD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	center.add_child(title)

	var subtitle := Label.new()
	subtitle.text = Localization.L("ui.main_menu.subtitle")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
	center.add_child(subtitle)

	# 古代印记显示
	_marks_label = Label.new()
	_marks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_marks_label.add_theme_font_size_override("font_size", 16)
	_marks_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	center.add_child(_marks_label)
	_refresh_marks()

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	center.add_child(spacer)

	_add_button(center, Localization.L("ui.main_menu.start"),  Color(0.2, 0.8, 0.3),  _on_start_pressed)
	_add_button(center, Localization.L("ui.totem_temple"),       Color(1.0, 0.75, 0.1), _on_temple_pressed)
	_add_button(center, Localization.L("ui.collection"),          Color(0.4, 0.7, 1.0),  _on_collection_pressed)
	var btn_settings_text = Localization.L("ui.settings")
	if btn_settings_text == "ui.settings": btn_settings_text = "设置"
	_add_button(center, btn_settings_text, Color(0.6, 0.6, 0.6), _on_settings_pressed)
	_add_button(center, Localization.L("ui.main_menu.quit"),     Color(0.7, 0.3, 0.3),  _on_quit_pressed)


func _add_button(parent: Node, text: String, color: Color, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(260, 52)
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", color)
	btn.pressed.connect(callback)
	parent.add_child(btn)


func _refresh_marks() -> void:
	var meta: Dictionary = SaveLoad.get_value("meta_progression", {})
	var marks: int = meta.get("ancient_marks", 0)
	_marks_label.text = Localization.L("ui.ancient_marks", [str(marks)])


func _on_state_changed(new_state: GameState.State) -> void:
	visible = (new_state == GameState.State.MAIN_MENU)
	if visible:
		_refresh_marks()


func _on_start_pressed() -> void:
	var panel := CanvasLayer.new()
	panel.set_script(load("res://scripts/ui/level_select_panel.gd"))
	get_tree().root.add_child(panel)


func _on_temple_pressed() -> void:
	var panel := CanvasLayer.new()
	panel.set_script(load("res://scripts/ui/totem_temple_panel.gd"))
	get_tree().root.add_child(panel)


func _on_collection_pressed() -> void:
	var panel := CanvasLayer.new()
	panel.set_script(load("res://scripts/ui/collection_panel.gd"))
	get_tree().root.add_child(panel)


func _on_settings_pressed() -> void:
	var panel := CanvasLayer.new()
	panel.set_script(load("res://scripts/ui/settings_panel.gd"))
	get_tree().root.add_child(panel)


func _on_quit_pressed() -> void:
	get_tree().quit()
