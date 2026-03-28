extends PanelContainer

# ---------------------------------------------------------------------------
# BuildPanel — 底部建造面板
# MVP 5只动物：cheetah/wolf_pack/honey_badger/elephant/pangolin
# ---------------------------------------------------------------------------

const Tower := preload("res://scripts/gameplay/tower.gd")

const ANIMALS: Array = [
	{"id": "cheetah",      "name": "猎豹"},
	{"id": "wolf_pack",    "name": "狼群"},
	{"id": "honey_badger", "name": "蜜獾"},
	{"id": "elephant",    "name": "大象"},
	{"id": "pangolin",    "name": "穿山甲"},
	{"id": "tiger",       "name": "老虎"},
	{"id": "lion",        "name": "狮子"},
	{"id": "eagle",       "name": "鹰"},
	{"id": "owl",         "name": "猫头鹰"},
	{"id": "otter",       "name": "水獭"},
	{"id": "peacock",     "name": "孔雀"},
	{"id": "chameleon",   "name": "变色龙"},
]

var _selected_id: String = ""
var _buttons: Array = []


func _ready() -> void:
	_build_buttons()
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.state_changed.connect(_on_state_changed)
	_refresh_buttons()


func _build_buttons() -> void:
	var hbox := $HBox
	for entry in ANIMALS:
		var btn := Button.new()
		var cost: int = Tower.ANIMAL_DB[entry["id"]]["cost"]
		btn.text = "%s\n%dg" % [entry["name"], cost]
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


func _on_gold_changed(_amount: int) -> void:
	_refresh_buttons()


func _on_state_changed(new_state: GameState.State) -> void:
	visible = (new_state == GameState.State.BUILD)
	if new_state != GameState.State.BUILD:
		_selected_id = ""
		_update_selection()
