extends Node2D
class_name Hero

# ---------------------------------------------------------------------------
# Hero — 英雄（老虎）：移动 + 光环
# Sprint 2 实现：右键点击移动，光环被动
# ---------------------------------------------------------------------------

const SPEED              := 3.5 * 64.0   # px/s（64 = TILE_SIZE，避免循环依赖）
const ARRIVAL_DIST       := 6.0
const AURA_RADIUS_PX     := 3.0 * 64.0

enum State { IDLE, MOVING }

var _state: State = State.IDLE
var _path: Array[Vector2] = []
var _path_idx: int = 0


func _ready() -> void:
	add_to_group("hero")
	position = Vector2(64 * 1 + 32, 64 * 7 + 32)  # 地图左侧中段起始位置


func _process(delta: float) -> void:
	if _state == State.MOVING:
		_move_along_path(delta)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
		# 转换为世界坐标（考虑 Camera2D）
		var world_pos := get_canvas_transform().affine_inverse() * mb.position
		_set_destination(world_pos)


func _set_destination(world_pos: Vector2) -> void:
	var path := PathfindingSystem.find_path(position, world_pos)
	if path.size() == 0:
		return
	_path = path
	_path_idx = 0
	_state = State.MOVING


func _move_along_path(delta: float) -> void:
	if _path_idx >= _path.size():
		_state = State.IDLE
		return
	var target := _path[_path_idx]
	var diff   := target - position
	if diff.length() < ARRIVAL_DIST:
		_path_idx += 1
		return
	position += diff.normalized() * SPEED * delta


# 供 Tower 查询光环加成
func get_aura_bonus_for(tower_pos: Vector2) -> float:
	if position.distance_to(tower_pos) <= AURA_RADIUS_PX:
		return 0.20
	return 0.0


func _draw() -> void:
	# 英雄色块
	draw_circle(Vector2.ZERO, 18.0, Color(1.0, 0.55, 0.0))
	draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 32, Color.WHITE, 2.0)
	# 光环范围圆圈
	draw_arc(Vector2.ZERO, AURA_RADIUS_PX, 0.0, TAU, 64, Color(1.0, 0.85, 0.0, 0.25), 1.5)
