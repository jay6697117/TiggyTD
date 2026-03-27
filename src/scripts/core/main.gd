extends Node2D

# ---------------------------------------------------------------------------
# Main — 游戏主场景根节点
# 负责：初始化各系统引用、连接全局信号
# ---------------------------------------------------------------------------

@onready var camera: Camera2D = $Camera2D
@onready var vfx_layer: Node2D = $VFXLayer


func _ready() -> void:
	VFXSystem.set_vfx_layer(vfx_layer)
	_connect_signals()
	# 根据存档决定首次进入状态
	var tutorial_done: bool = SaveLoad.get_value("tutorial", {}).get("tutorial_completed", false)
	if not tutorial_done:
		GameState.change_state(GameState.State.BUILD)  # TODO: 替换为 TUTORIAL
	else:
		GameState.change_state(GameState.State.BUILD)


func _connect_signals() -> void:
	GameState.state_changed.connect(_on_state_changed)
	GameState.base_hp_changed.connect(_on_base_hp_changed)


func _on_state_changed(new_state: GameState.State) -> void:
	match new_state:
		GameState.State.WIN:
			AudioSystem.play_bgm("victory")
			VFXSystem.play("victory", Vector2(640, 480))
		GameState.State.LOSE:
			AudioSystem.play_bgm("defeat")
			VFXSystem.play("defeat", Vector2(640, 480))


func _on_base_hp_changed(_new_hp: int) -> void:
	AudioSystem.play_sfx("base_damage")
	VFXSystem.screen_shake(5.0, 0.3, camera)
	VFXSystem.play("base_damage", Vector2(640, 480))
