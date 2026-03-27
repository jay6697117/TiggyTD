# ---------------------------------------------------------------------------
# MapGrid — 关卡/地图系统核心数据结构
# GDD：level-map.md
# 依赖：constants.gd
# ---------------------------------------------------------------------------
class_name MapGrid

enum CellType { PATH, BUILD, BLOCKED, SPAWN, BASE }

const WIDTH  := Constants.MAP_WIDTH   # 20
const HEIGHT := Constants.MAP_HEIGHT  # 15
const TILE   := Constants.TILE_SIZE   # 64 px

# 路径 waypoints（格子坐标）
const WAYPOINTS: Array[Vector2i] = [
	Vector2i(0,  2),
	Vector2i(7,  2),
	Vector2i(7,  9),
	Vector2i(13, 9),
	Vector2i(13, 12),
	Vector2i(19, 12),
]

# 地图格子数据：type 和 占用状态
var _types: Array         # Array[Array[CellType]]  [x][y]
var _occupied: Array      # Array[Array[int]]  tower_id or -1


func _init() -> void:
	_types    = []
	_occupied = []
	for x in WIDTH:
		_types.append([])
		_occupied.append([])
		for y in HEIGHT:
			_types[x].append(CellType.BUILD)
			_occupied[x].append(-1)
	_apply_layout()


# ── 公开查询接口 ────────────────────────────────────────────────────────────

func get_cell_type(x: int, y: int) -> CellType:
	if not _in_bounds(x, y):
		return CellType.BLOCKED
	return _types[x][y]


func is_buildable(x: int, y: int) -> bool:
	if not _in_bounds(x, y):
		return false
	return _types[x][y] == CellType.BUILD and _occupied[x][y] == -1


func is_walkable(x: int, y: int) -> bool:
	"""寻路/敌人使用：PATH/SPAWN/BASE 可通行。"""
	if not _in_bounds(x, y):
		return false
	var t: CellType = _types[x][y]
	return t == CellType.PATH or t == CellType.SPAWN or t == CellType.BASE


func occupy(x: int, y: int, tower_id: int) -> bool:
	if not is_buildable(x, y):
		return false
	_occupied[x][y] = tower_id
	return true


func vacate(x: int, y: int) -> void:
	if _in_bounds(x, y):
		_occupied[x][y] = -1


# ── 坐标转换 ────────────────────────────────────────────────────────────────

func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / TILE), int(world_pos.y / TILE))


func cell_to_world(cell: Vector2i) -> Vector2:
	"""返回格子中心的世界坐标。"""
	return Vector2(cell.x * TILE + TILE * 0.5, cell.y * TILE + TILE * 0.5)


func waypoint_world_positions() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for wp in WAYPOINTS:
		result.append(cell_to_world(wp))
	return result


# ── 内部布局生成 ─────────────────────────────────────────────────────────────

func _apply_layout() -> void:
	# 1. 标记路径格（连接相邻 waypoint 的线段）
	for i in WAYPOINTS.size() - 1:
		_mark_segment(WAYPOINTS[i], WAYPOINTS[i + 1])

	# 2. 起点和终点
	_set_cell(WAYPOINTS[0].x, WAYPOINTS[0].y, CellType.SPAWN)
	_set_cell(WAYPOINTS[-1].x, WAYPOINTS[-1].y, CellType.BASE)

	# 3. 路径边缘格（紧贴路径的格子）不可建造 → BLOCKED
	for x in WIDTH:
		for y in HEIGHT:
			if _types[x][y] == CellType.BUILD and _adjacent_to_path(x, y):
				_set_cell(x, y, CellType.BLOCKED)

	# 4. 四角装饰封锁区（2×2）
	for corner: Vector2i in [Vector2i(0,0), Vector2i(18,0), Vector2i(0,13), Vector2i(18,13)]:
		for dx in 2:
			for dy in 2:
				var cx: int = corner.x + dx
				var cy: int = corner.y + dy
				if _types[cx][cy] == CellType.BUILD:
					_set_cell(cx, cy, CellType.BLOCKED)


func _mark_segment(from: Vector2i, to: Vector2i) -> void:
	var x := from.x
	var y := from.y
	var dx: int = sign(to.x - from.x)
	var dy: int = sign(to.y - from.y)
	while x != to.x or y != to.y:
		_set_cell(x, y, CellType.PATH)
		x += dx
		y += dy
	_set_cell(to.x, to.y, CellType.PATH)


func _adjacent_to_path(x: int, y: int) -> bool:
	for offset: Vector2i in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		var nx: int = x + offset.x
		var ny: int = y + offset.y
		if _in_bounds(nx, ny):
			var t: CellType = _types[nx][ny]
			if t == CellType.PATH or t == CellType.SPAWN or t == CellType.BASE:
				return true
	return false


func _set_cell(x: int, y: int, t: CellType) -> void:
	if _in_bounds(x, y):
		_types[x][y] = t


func _in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < WIDTH and y >= 0 and y < HEIGHT
