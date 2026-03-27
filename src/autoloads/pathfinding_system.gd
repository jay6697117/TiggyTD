extends Node

# ---------------------------------------------------------------------------
# PathfindingSystem — 英雄寻路单例（AStarGrid2D）
# 依赖：GridManager, Constants
# ---------------------------------------------------------------------------

var _astar: AStarGrid2D

func _ready() -> void:
	_astar = AStarGrid2D.new()
	_astar.region = Rect2i(0, 0, Constants.MAP_WIDTH, Constants.MAP_HEIGHT)
	_astar.cell_size = Vector2(1, 1)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.update()
	GridManager.obstacle_changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	for x in Constants.MAP_WIDTH:
		for y in Constants.MAP_HEIGHT:
			var t: MapGrid.CellType = GridManager.grid.get_cell_type(x, y)
			_astar.set_point_solid(Vector2i(x, y), t == MapGrid.CellType.BLOCKED)


func find_path(from_world: Vector2, to_world: Vector2) -> Array[Vector2]:
	var from_cell: Vector2i = GridManager.grid.world_to_cell(from_world)
	var to_cell: Vector2i   = GridManager.grid.world_to_cell(to_world)
	to_cell.x = clampi(to_cell.x, 0, Constants.MAP_WIDTH - 1)
	to_cell.y = clampi(to_cell.y, 0, Constants.MAP_HEIGHT - 1)
	var path_cells: Array[Vector2i] = _astar.get_id_path(from_cell, to_cell)
	var result: Array[Vector2] = []
	for cell in path_cells:
		result.append(GridManager.grid.cell_to_world(cell))
	return result
