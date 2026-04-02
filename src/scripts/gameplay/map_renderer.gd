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
const COLOR_BLOCKED        := Color(0.20, 0.35, 0.15)  # 深绿（丛林）
const COLOR_BLOCKED_LAVA   := Color(0.70, 0.25, 0.05)  # 橙红（熔岩）
const COLOR_BLOCKED_FROZEN := Color(0.55, 0.75, 0.95)  # 冰蓝（冻原）
const COLOR_SPAWN   := Color(0.90, 0.30, 0.20)  # 红色（刷怪点）
const COLOR_BASE    := Color(0.20, 0.60, 0.90)  # 蓝色（基地）
const COLOR_GRID    := Color(0.0, 0.0, 0.0, 0.15)  # 网格线（半透明黑）

const COLOR_HOVER_BUILD   := Color(0.50, 0.90, 0.30, 0.5)  # 绿色高亮（可建造）
const COLOR_HOVER_INVALID := Color(0.90, 0.20, 0.20, 0.5)  # 红色高亮（不可建造）

var _grid: MapGrid
var _hover_cell: Vector2i = Vector2i(-1, -1)
var _show_hover: bool = false
var _tileset_tex: Texture2D

const REGION_PATH := Rect2(64, 80, 384, 384)
const REGION_BUILD := Rect2(512 + 64, 80, 384, 384)
const REGION_BLOCKED := Rect2(64, 512 + 80, 384, 384)
const REGION_BASE := Rect2(512 + 64, 512 + 80, 384, 384)

signal cell_clicked(cell: Vector2i, cell_type: MapGrid.CellType)
signal cell_hovered(cell: Vector2i)

var _bg_tex: Texture2D


func _ready() -> void:
	_grid = GridManager.grid
	var level_id := GameState.current_level_id
	if level_id == "":
		level_id = "ancient_savanna"
	var tex_path := "res://assets/art/maps/tileset_%s.png" % level_id
	if ResourceLoader.exists(tex_path):
		_tileset_tex = load(tex_path)
	# 加载关卡背景图
	var bg_path := "res://assets/art/backgrounds/bg_%s.png" % level_id
	if ResourceLoader.exists(bg_path):
		_bg_tex = load(bg_path)
	GridManager.obstacle_changed.connect(_on_grid_changed)
	queue_redraw()


func _on_grid_changed() -> void:
	_grid = GridManager.grid
	queue_redraw()


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
	# 0. 绘制背景图（铺满整个地图区域）
	if _bg_tex != null:
		var map_w := MapGrid.WIDTH * tile
		var map_h := MapGrid.HEIGHT * tile
		draw_texture_rect(_bg_tex, Rect2(0, 0, map_w, map_h), false)
	# 1. 绘制所有格子
	for x in MapGrid.WIDTH:
		for y in MapGrid.HEIGHT:
			var rect := Rect2(x * tile, y * tile, tile, tile)
			var type := _grid.get_cell_type(x, y)
			
			if _tileset_tex != null:
				var src_region: Rect2
				match type:
					MapGrid.CellType.PATH:    src_region = REGION_PATH
					MapGrid.CellType.BUILD:   src_region = REGION_BUILD
					MapGrid.CellType.BLOCKED: src_region = REGION_BLOCKED
					MapGrid.CellType.SPAWN:   src_region = REGION_BASE
					MapGrid.CellType.BASE:    src_region = REGION_BASE
					_:                        src_region = REGION_BUILD
				draw_texture_rect_region(_tileset_tex, rect, src_region)
			else:
				var col := _cell_color(type)
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
		MapGrid.CellType.BLOCKED:
			match GameState.current_level_id:
				"lava_canyon":   return COLOR_BLOCKED_LAVA
				"frozen_tundra": return COLOR_BLOCKED_FROZEN
				_:               return COLOR_BLOCKED
		MapGrid.CellType.SPAWN:   return COLOR_SPAWN
		MapGrid.CellType.BASE:    return COLOR_BASE
		_:                        return COLOR_BUILD
