extends PanelContainer

# ---------------------------------------------------------------------------
# BuildPanel — 底部建造面板
# MVP 5只动物：cheetah/wolf_pack/honey_badger/elephant/pangolin
# ---------------------------------------------------------------------------

const Tower := preload("res://scripts/gameplay/tower.gd")

const ANIMALS: Array = [
	{"id": "cheetah"},
	{"id": "wolf_pack"},
	{"id": "honey_badger"},
	{"id": "elephant"},
	{"id": "pangolin"},
	{"id": "tiger"},
	{"id": "lion"},
	{"id": "eagle"},
	{"id": "owl"},
	{"id": "otter"},
	{"id": "peacock"},
	{"id": "chameleon"},
]

var _selected_id: String = ""
var _buttons: Array = []

# 升级提示标签（动态创建）
var _info_label: Label = null


func _ready() -> void:
	_build_buttons()
	_build_info_label()
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.state_changed.connect(_on_state_changed)
	_refresh_buttons()
	call_deferred("_connect_placement_manager")


func _connect_placement_manager() -> void:
	var pm := get_tree().get_first_node_in_group("tower_placement")
	if pm:
		pm.tower_focused.connect(_on_tower_focused)


func _build_info_label() -> void:
	_info_label = Label.new()
	_info_label.visible = false
	_info_label.add_theme_font_size_override("font_size", 14)
	add_child(_info_label)


func _build_buttons() -> void:
	var hbox := $HBox
	for entry in ANIMALS:
		var btn := Button.new()
		var cost: int = Tower.ANIMAL_DB[entry["id"]]["cost"]
		var animal_name = Localization.L("animal." + entry["id"] + ".name")
		btn.text = "%s\n%dg" % [animal_name, cost]
		btn.custom_minimum_size = Vector2(100, 80)
		btn.pressed.connect(_on_btn_pressed.bind(entry["id"]))
		hbox.add_child(btn)
		_buttons.append({"btn": btn, "id": entry["id"], "cost": cost})


func _on_btn_pressed(animal_id: String) -> void:
	if GameState.current_state != GameState.State.BUILD:
		return
	var cost: int = Tower.ANIMAL_DB[animal_id]["cost"]
	if GameState.gold < cost:
		return
	if _selected_id == animal_id:
		_selected_id = ""
	else:
		_selected_id = animal_id
	_update_selection()
	var pm := get_tree().get_first_node_in_group("tower_placement")
	if pm:
		if _selected_id == "":
			pm.cancel_placement()
		else:
			pm.select_animal(_selected_id)


func _update_selection() -> void:
	for entry in _buttons:
		var btn: Button = entry["btn"]
		if entry["id"] == _selected_id:
			btn.modulate = Color(0.4, 1.0, 0.4)
		else:
			btn.modulate = Color.WHITE


func _refresh_buttons() -> void:
	var gold := GameState.gold
	for entry in _buttons:
		var btn: Button = entry["btn"]
		var affordable: bool = gold >= entry["cost"]
		btn.disabled = not affordable
		if not affordable:
			btn.modulate = Color(1.0, 0.4, 0.4)
		elif entry["id"] == _selected_id:
			btn.modulate = Color(0.4, 1.0, 0.4)
		else:
			btn.modulate = Color.WHITE


func _on_tower_focused(tower: Tower) -> void:
	if not is_instance_valid(tower):
		_info_label.visible = false
		return
	var cost := tower.upgrade_cost()
	if tower.can_upgrade():
		_info_label.text = Localization.L("ui.upgrade_cost", [tower.level, tower.level + 1, cost])
	else:
		_info_label.text = Localization.L("ui.max_level", [tower.level])
	_info_label.visible = true
	# 3秒后自动隐藏
	var t := get_tree().create_timer(3.0)
	t.timeout.connect(func(): if is_instance_valid(_info_label): _info_label.visible = false)


func _on_gold_changed(_amount: int) -> void:
	_refresh_buttons()


func _on_state_changed(new_state: GameState.State) -> void:
	visible = (new_state == GameState.State.BUILD)
	if new_state != GameState.State.BUILD:
		_selected_id = ""
		_update_selection()
