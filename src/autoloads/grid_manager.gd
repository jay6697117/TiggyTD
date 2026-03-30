extends Node

# ---------------------------------------------------------------------------
# GridManager — 全局网格单例
# 职责：持有唯一 MapGrid 实例，供所有系统共享访问
# 依赖：MapGrid, Constants, GameState
# ---------------------------------------------------------------------------

# 各关卡 waypoints 定义
const LEVEL_WAYPOINTS: Dictionary = {
	"ancient_savanna": [
		Vector2i(0,  2), Vector2i(7,  2), Vector2i(7,  9),
		Vector2i(13, 9), Vector2i(13, 12), Vector2i(19, 12),
	],
	# 熔岩峡谷：Z 形三折路
	"lava_canyon": [
		Vector2i(0,  1), Vector2i(5,  1), Vector2i(5,  7),
		Vector2i(14, 7), Vector2i(14, 13), Vector2i(19, 13),
	],
	# 冰封冻原：U 形长路
	"frozen_tundra": [
		Vector2i(0,  1), Vector2i(18, 1), Vector2i(18, 7),
		Vector2i(1,  7), Vector2i(1,  13), Vector2i(19, 13),
	],
}

var grid: MapGrid = MapGrid.new()

# 塔放置/移除后触发，敌人AI/寻路等系统监听以更新状态
signal obstacle_changed()


func _ready() -> void:
	GameState.state_changed.connect(_on_state_changed)


func _on_state_changed(new_state: GameState.State) -> void:
	if new_state == GameState.State.BUILD and GameState.current_wave == 0:
		load_level(GameState.current_level_id)


func load_level(level_id: String) -> void:
	var wps: Array = LEVEL_WAYPOINTS.get(level_id, LEVEL_WAYPOINTS["ancient_savanna"])
	var typed: Array[Vector2i] = []
	for v in wps:
		typed.append(v)
	grid = MapGrid.new(typed)
	obstacle_changed.emit()
