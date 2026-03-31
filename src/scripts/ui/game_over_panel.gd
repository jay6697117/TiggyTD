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

var _label_marks: Label
var _btn_temple: Button
var _label_unlock: Label = null


func _ready() -> void:
	visible = false
	GameState.state_changed.connect(_on_state_changed)
	btn_restart.pressed.connect(_on_restart_pressed)
	# 动态插入印记结算标签（在 BtnRestart 前）
	_label_marks = Label.new()
	_label_marks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_marks.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	_label_marks.add_theme_font_size_override("font_size", 18)
	var vbox := $Panel/VBox
	vbox.add_child(_label_marks)
	vbox.move_child(_label_marks, btn_restart.get_index())
	# 图腾神殿入口按钮
	_btn_temple = Button.new()
	_btn_temple.text = Localization.L("ui.totem_temple")
	_btn_temple.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_btn_temple.pressed.connect(_open_totem_temple)
	vbox.add_child(_btn_temple)
	vbox.move_child(_btn_temple, btn_restart.get_index())


func _on_state_changed(new_state: GameState.State) -> void:
	match new_state:
		GameState.State.WIN:
			_show(true)
		GameState.State.LOSE:
			_show(false)
		_:
			visible = false


func _show(is_win: bool) -> void:
	label_title.text = Localization.L("ui.victory") if is_win else Localization.L("ui.defeat")
	label_title.modulate = Color(0.2, 1.0, 0.3) if is_win else Color(1.0, 0.3, 0.2)
	label_hp.text = Localization.L("ui.base_hp_result", [GameState.base_hp, GameState.base_hp_max])
	label_kills.text = Localization.L("ui.kills", [GameState.kills_this_run])
	label_waves.text = Localization.L("ui.waves_survived", [GameState.current_wave, GameState.total_waves])
	_unlocked_level_name = ""
	if _label_unlock != null:
		_label_unlock.queue_free()
		_label_unlock = null
	var marks_earned := _settle_marks(is_win)
	_label_marks.text = Localization.L("ui.marks_earned", [marks_earned, GameState.ancient_marks])
	visible = true
	_save_result(is_win)
	if _unlocked_level_name != "":
		_label_unlock = Label.new()
		_label_unlock.text = Localization.L("ui.new_unlock", [_unlocked_level_name])
		_label_unlock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label_unlock.add_theme_font_size_override("font_size", 18)
		_label_unlock.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		$Panel/VBox.add_child(_label_unlock)
		$Panel/VBox.move_child(_label_unlock, _label_marks.get_index() + 1)


func _settle_marks(is_win: bool) -> int:
	# GDD meta-progression.md 结算规则
	var earned: int = 0
	if is_win:
		earned += 30
		# Boss 击杀（第10波通关即击杀了 boss）
		earned += 15
		# 首次通关额外奖励
		var levels: Array = SaveLoad.get_value("level_progress", [])
		for entry in levels:
			if entry.get("level_id") == GameState.current_level_id:
				if entry.get("best_result", {}).get("waves_survived", 0) < GameState.total_waves:
					earned += 20
				break
	else:
		if GameState.current_wave >= 5:
			earned += 10
		else:
			earned += 5
	GameState.add_ancient_marks(earned)
	var meta: Dictionary = SaveLoad.get_value("meta_progression", {})
	meta["ancient_marks"] = GameState.ancient_marks
	meta["total_marks_earned"] = meta.get("total_marks_earned", 0) + earned
	SaveLoad.set_value("meta_progression", meta)
	return earned


const _LEVEL_ORDER := ["ancient_savanna", "lava_canyon", "frozen_tundra"]


var _unlocked_level_name: String = ""


func _save_result(is_win: bool) -> void:
	var lid: String = GameState.current_level_id
	var levels: Array = SaveLoad.get_value("level_progress", [])
	for entry in levels:
		if entry.get("level_id") == lid:
			var best: Dictionary = entry.get("best_result", {})
			var prev_waves: int = best.get("waves_survived", 0)
			var cur_waves: int = GameState.current_wave
			var cur_hp: int = GameState.base_hp
			if cur_waves > prev_waves or (cur_waves == prev_waves and cur_hp > best.get("base_hp_remaining", -1)):
				entry["best_result"] = {"waves_survived": cur_waves, "base_hp_remaining": cur_hp}
			if is_win:
				entry["status"] = "CLEARED"
			break
	if is_win:
		var idx: int = _LEVEL_ORDER.find(lid)
		if idx >= 0 and idx + 1 < _LEVEL_ORDER.size():
			var next_id: String = _LEVEL_ORDER[idx + 1]
			for entry in levels:
				if entry.get("level_id") == next_id and entry.get("status") == "LOCKED":
					entry["status"] = "UNLOCKED"
					_unlocked_level_name = Localization.L("level." + next_id + ".name")
					break
	SaveLoad.set_value("level_progress", levels)
	SaveLoad.save_game()


func _open_totem_temple() -> void:
	var temple := CanvasLayer.new()
	temple.set_script(load("res://scripts/ui/totem_temple_panel.gd"))
	get_tree().root.add_child(temple)


func _on_restart_pressed() -> void:
	visible = false
	GameState.reset_run_data()
	get_tree().reload_current_scene()
