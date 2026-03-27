extends Node2D

# ---------------------------------------------------------------------------
# MapRenderer — 地图渲染层
# 职责：根据 MapGrid 数据渲染地图格子（颜色色块，无美术资源时也可运行）
# GDD：level-map.md
# 依赖：MapGrid, Constants
# ---------------------------------------------------------------------------

# 格子颜色（占位色块，后期替换为 TileMapLayer 贴图）
const COLOR_PATH    := Color(0.55, 0.42, 0.25)  # 泥土棕
const COLOR_BUILD   := Color(0.35, 0.60, 0.25)  # 草地绿
const COLOR_BLOCKED := Color(0.20, 0.35, 0.15)  # 深绿（丛林）
const COLOR_SPAWN   := Color(0.90, 0.30, 0.20)  # 红色（刷怪点）
const COLOR_BASE    := Color(0.20, 0.60, 0.90)  # 蓝色（基地）
const COLOR_GRID    := Color(0.0, 0.0, 0.0, 0.15)  # 网格线（半透明黑）

# 悬停高亮
const COLOR_HOVER_BUILD   := Color(0.50, 0.90, 0.30, 0.5)  # 绿色高亮（可建造）
const COLOR_HOVER_INVALID := Color(0.90, 0.20, 0.20, 0.5)  # 红色高亮（不可建造）

var _grid: MapGrid
var _hover_cell: Vector2i = Vector2i(-1, -1)
var _show_hover: bool = false

signal cell_clicked(cell: Vector2i, cell_type: MapGrid.CellType)
signal cell_hovered(cell: Vector2i)


func setup(grid: MapGrid) -> void:
	_grid = grid
	queue_redraw()


func set_hover(cell: Vector2i, show: bool = true) -> void:
	_hover_cell = cell
	_show_hover = show
	queue_redraw()


func clear_hover() -> void:
	_show_hover = false
	queue_redraw()


func _draw() -> void:
	if _grid == null:
		return
	var tile := float(Constants.TILE_SIZE)
	# 1. 绘制所有格子
	for x in MapGrid.WIDTH:
		for y in MapGrid.HEIGHT:
			var rect := Rect2(x * tile, y * tile, tile, tile)
			var col := _cell_color(_grid.get_cell_type(x, y))
			draw_rect(rect, col)
			# 网格线
			draw_rect(rect, COLOR_GRID, false, 1.0)
	# 2. 悬停高亮
	if _show_hover and _hover_cell.x >= 0:
		var hx := _hover_cell.x
		var hy := _hover_cell.y
		var rect := Rect2(hx * tile, hy * tile, tile, tile)
		var buildable := _grid.is_buildable(hx, hy)
		draw_rect(rect, COLOR_HOVER_BUILD if buildable else COLOR_HOVER_INVALID)


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouse):
		return
	var local_pos := get_local_mouse_position()
	var cell := _grid.world_to_cell(local_pos)
	if event is InputEventMouseMotion:
		if cell != _hover_cell:
			set_hover(cell)
			cell_hovered.emit(cell)
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if _grid != null and cell.x >= 0 and cell.x < MapGrid.WIDTH \
					and cell.y >= 0 and cell.y < MapGrid.HEIGHT:
				cell_clicked.emit(cell, _grid.get_cell_type(cell.x, cell.y))


func _cell_color(t: MapGrid.CellType) -> Color:
	match t:
		MapGrid.CellType.PATH:    return COLOR_PATH
		MapGrid.CellType.BUILD:   return COLOR_BUILD
		MapGrid.CellType.BLOCKED: return COLOR_BLOCKED
		MapGrid.CellType.SPAWN:   return COLOR_SPAWN
		MapGrid.CellType.BASE:    return COLOR_BASE
		_:                        return COLOR_BUILD
