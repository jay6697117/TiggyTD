extends CanvasLayer

# ---------------------------------------------------------------------------
# HUD — 游戏主界面
# 显示：金币、波次、基地血量；提供「开始下一波」按钮
# 依赖：GameState
# ---------------------------------------------------------------------------

@onready var label_gold: Label       = $Panel/HBox/LabelGold
@onready var label_wave: Label       = $Panel/HBox/LabelWave
@onready var label_hp: Label         = $Panel/HBox/LabelHP
@onready var label_countdown: Label  = $Panel/HBox/LabelCountdown
@onready var btn_start: Button       = $Panel/HBox/BtnStart


func _ready() -> void:
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.base_hp_changed.connect(_on_hp_changed)
	GameState.wave_changed.connect(_on_wave_changed)
	GameState.state_changed.connect(_on_state_changed)
	btn_start.pressed.connect(_on_btn_start_pressed)
	# 延迟一帧等 WaveManager 就绪
	call_deferred("_connect_wave_manager")
	_refresh()


func _connect_wave_manager() -> void:
	var wm := get_tree().get_first_node_in_group("wave_manager")
	if wm:
		wm.prepare_tick.connect(_on_prepare_tick)


func _refresh() -> void:
	label_gold.text = "金币：%d" % GameState.gold
	label_wave.text = "波次：%d / %d" % [GameState.current_wave, GameState.total_waves]
	label_hp.text   = "基地：%d / %d" % [GameState.base_hp, GameState.base_hp_max]
	_update_btn_visibility()


func _update_btn_visibility() -> void:
	btn_start.visible = (GameState.current_state == GameState.State.BUILD)


func _on_gold_changed(amount: int) -> void:
	label_gold.text = "金币：%d" % amount


func _on_hp_changed(new_hp: int) -> void:
	label_hp.text = "基地：%d / %d" % [new_hp, GameState.base_hp_max]


func _on_wave_changed(new_wave: int) -> void:
	label_wave.text = "波次：%d / %d" % [new_wave, GameState.total_waves]


func _on_prepare_tick(seconds_left: int) -> void:
	if seconds_left > 0:
		label_countdown.text = "准备：%ds" % seconds_left
		label_countdown.visible = true
	else:
		label_countdown.visible = false


func _on_state_changed(new_state: GameState.State) -> void:
	_update_btn_visibility()
	if new_state == GameState.State.BUILD:
		label_countdown.visible = false


func _on_btn_start_pressed() -> void:
	if GameState.current_state == GameState.State.BUILD:
		GameState.change_state(GameState.State.WAVE)
