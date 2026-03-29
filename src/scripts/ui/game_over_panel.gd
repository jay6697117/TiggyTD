extends CanvasLayer

# ---------------------------------------------------------------------------
# GameOverPanel — 胜负结算面板
# WIN/LOSE 状态时全屏显示，展示战绩，提供「再来一局」
# ---------------------------------------------------------------------------

@onready var panel: PanelContainer  = $Panel
@onready var label_title: Label     = $Panel/VBox/LabelTitle
@onready var label_hp: Label        = $Panel/VBox/LabelHP
@onready var label_kills: Label     = $Panel/VBox/LabelKills
@onready var label_waves: Label     = $Panel/VBox/LabelWaves
@onready var btn_restart: Button    = $Panel/VBox/BtnRestart


func _ready() -> void:
	visible = false
	GameState.state_changed.connect(_on_state_changed)
	btn_restart.pressed.connect(_on_restart_pressed)


func _on_state_changed(new_state: GameState.State) -> void:
	match new_state:
		GameState.State.WIN:
			_show(true)
		GameState.State.LOSE:
			_show(false)
		_:
			visible = false


func _show(is_win: bool) -> void:
	label_title.text  = "胜利！" if is_win else "失败"
	label_title.modulate = Color(0.2, 1.0, 0.3) if is_win else Color(1.0, 0.3, 0.2)
	label_hp.text     = "基地残余 HP：%d / %d" % [GameState.base_hp, GameState.base_hp_max]
	label_kills.text  = "击杀数：%d" % GameState.kills_this_run
	label_waves.text  = "抵御波次：%d / %d" % [GameState.current_wave, GameState.total_waves]
	visible = true
	_save_result(is_win)


func _save_result(is_win: bool) -> void:
	var levels: Array = SaveLoad.get_value("level_progress", [])
	for entry in levels:
		if entry.get("level_id") == "ancient_savanna":
			var best: Dictionary = entry.get("best_result", {})
			var prev_waves: int = best.get("waves_survived", 0)
			var cur_waves: int = GameState.current_wave
			var cur_hp: int = GameState.base_hp if is_win else GameState.base_hp
			if cur_waves > prev_waves or (cur_waves == prev_waves and cur_hp > best.get("base_hp_remaining", -1)):
				entry["best_result"] = {"waves_survived": cur_waves, "base_hp_remaining": cur_hp}
			break
	SaveLoad.set_value("level_progress", levels)
	SaveLoad.save_game()


func _on_restart_pressed() -> void:
	visible = false
	GameState.reset_run_data()
	get_tree().reload_current_scene()
