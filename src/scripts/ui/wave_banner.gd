extends Control

# ---------------------------------------------------------------------------
# WaveBanner — 波次提示横幅
# BUILD→WAVE 切换时屏幕中央显示「第 X 波」，1.5秒淡出
# ---------------------------------------------------------------------------

@onready var label: Label = $Label

var _tween: Tween


func _ready() -> void:
	modulate.a = 0.0
	GameState.state_changed.connect(_on_state_changed)


func _on_state_changed(new_state: GameState.State) -> void:
	if new_state == GameState.State.WAVE:
		_show_banner()


func _show_banner() -> void:
	label.text = "第 %d 波" % GameState.current_wave
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.2)
	_tween.tween_interval(1.0)
	_tween.tween_property(self, "modulate:a", 0.0, 0.3)
