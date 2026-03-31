extends CanvasLayer

# ---------------------------------------------------------------------------
# PausePanel — 暂停菜单
# ESC 键触发；WAVE / BUILD 状态下生效；layer=90
# ---------------------------------------------------------------------------

var _prev_state: GameState.State


func _ready() -> void:
	layer = 90
	_build_ui()
	GameState.state_changed.connect(_on_state_changed)
	visible = false


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchor_and_offset(SIDE_LEFT,   0.35, 0.0)
	panel.set_anchor_and_offset(SIDE_RIGHT,  0.65, 0.0)
	panel.set_anchor_and_offset(SIDE_TOP,    0.30, 0.0)
	panel.set_anchor_and_offset(SIDE_BOTTOM, 0.70, 0.0)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = Localization.L("ui.paused")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title)

	var btn_resume := Button.new()
	btn_resume.text = Localization.L("ui.resume")
	btn_resume.custom_minimum_size = Vector2(200, 48)
	btn_resume.add_theme_font_size_override("font_size", 18)
	btn_resume.pressed.connect(_on_resume)
	vbox.add_child(btn_resume)

	var btn_menu := Button.new()
	btn_menu.text = Localization.L("ui.return_main_menu")
	btn_menu.custom_minimum_size = Vector2(200, 48)
	btn_menu.add_theme_font_size_override("font_size", 18)
	btn_menu.pressed.connect(_on_return_main_menu)
	vbox.add_child(btn_menu)



func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		var s := GameState.current_state
		if s == GameState.State.BUILD or s == GameState.State.WAVE:
			_open(s)
		elif s == GameState.State.PAUSED:
			_on_resume()


func _open(from_state: GameState.State) -> void:
	_prev_state = from_state
	visible = true
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.change_state(GameState.State.PAUSED)


func _on_resume() -> void:
	visible = false
	get_tree().paused = false
	GameState.change_state(_prev_state)


func _on_return_main_menu() -> void:
	get_tree().paused = false
	Inventory.clear()
	GameState.gold = 150
	GameState.base_hp = GameState.base_hp_max
	GameState.current_wave = 0
	GameState.kills_this_run = 0
	GameState.enemies_leaked = 0
	GameState.change_state(GameState.State.MAIN_MENU)
	queue_free()


func _on_state_changed(new_state: GameState.State) -> void:
	if new_state != GameState.State.PAUSED and visible:
		visible = false
