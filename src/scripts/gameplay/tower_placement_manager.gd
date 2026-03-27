extends Node

# ---------------------------------------------------------------------------
# TowerPlacementManager — 动物塔放置系统
# GDD：tower-placement.md
# 依赖：GridManager, GameState, Constants
# ---------------------------------------------------------------------------

const TowerScript := preload("res://scripts/gameplay/tower.gd")

const SELL_RATIO := 0.5

# 当前选中准备放置的动物ID（由 UI 设置）
var _pending_animal_id: String = ""

# 塔节点容器
var _towers_node: Node2D

# cell → Tower 的映射
var _placed_towers: Dictionary = {}  # Vector2i → Tower

func _ready() -> void:
	add_to_group("tower_placement")


func setup(towers_node: Node2D) -> void:
	_towers_node = towers_node


# ── 公开接口（由 MapRenderer.cell_clicked 信号触发） ──────────────────────

# 选择要放置的动物（从 UI 调用）
func select_animal(animal_id: String) -> void:
	if GameState.current_state != GameState.State.BUILD:
		return
	_pending_animal_id = animal_id


# 取消放置
func cancel_placement() -> void:
	_pending_animal_id = ""


# 点击格子：放置或回收
func on_cell_clicked(cell: Vector2i, _cell_type: MapGrid.CellType) -> void:
	if GameState.current_state != GameState.State.BUILD:
		return
	if _placed_towers.has(cell):
		_sell_tower(cell)
		return
	if _pending_animal_id != "":
		_try_place(_pending_animal_id, cell)


# 三角龙 charge 推塔（由 Enemy._check_charge 通过 call_group 触发）
func push_tower(from_cell: Vector2i, direction: Vector2i) -> void:
	if not _placed_towers.has(from_cell):
		return
	var tower: Tower = _placed_towers[from_cell]
	var to_cell := Vector2i(from_cell.x + direction.x, from_cell.y + direction.y)
	if GridManager.grid.is_buildable(to_cell.x, to_cell.y):
		# 移动塔
		GridManager.grid.vacate(from_cell.x, from_cell.y)
		GridManager.grid.occupy(to_cell.x, to_cell.y, _tower_id(tower))
		_placed_towers.erase(from_cell)
		_placed_towers[to_cell] = tower
		tower.grid_cell = to_cell
		tower.position = _cell_center(to_cell)
	else:
		# 摧毁，不返还金币
		GridManager.grid.vacate(from_cell.x, from_cell.y)
		_placed_towers.erase(from_cell)
		tower.queue_free()
	GridManager.obstacle_changed.emit()


# ── 内部逻辑 ────────────────────────────────────────────────────────────────

func _try_place(animal_id: String, cell: Vector2i) -> void:
	if not GridManager.grid.is_buildable(cell.x, cell.y):
		return
	var cost: int = Tower.ANIMAL_DB[animal_id]["cost"]
	if not GameState.spend_gold(cost):
		# 金币不足：UI 系统负责提示（TODO: 信号通知 UI）
		return
	var tower := _create_tower(animal_id, cell)
	_towers_node.add_child(tower)
	_placed_towers[cell] = tower
	GridManager.grid.occupy(cell.x, cell.y, _tower_id(tower))
	GridManager.obstacle_changed.emit()
	_pending_animal_id = ""  # 放置后清空选择


func _sell_tower(cell: Vector2i) -> void:
	var tower: Tower = _placed_towers[cell]
	var cost: int = Tower.ANIMAL_DB[tower.animal_id]["cost"]
	var refund := int(cost * SELL_RATIO)
	GameState.add_gold(refund)
	GridManager.grid.vacate(cell.x, cell.y)
	_placed_towers.erase(cell)
	tower.queue_free()
	GridManager.obstacle_changed.emit()


func _create_tower(animal_id: String, cell: Vector2i) -> Tower:
	var t := CharacterBody2D.new()
	t.set_script(TowerScript)
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 24.0
	col.shape = shape
	t.add_child(col)
	t.collision_layer = Constants.LAYER_TOWERS
	t.collision_mask  = Constants.LAYER_ENEMIES
	t.position = _cell_center(cell)
	t.call_deferred("setup", animal_id, cell)
	return t


func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * Constants.TILE_SIZE + Constants.TILE_SIZE * 0.5,
		cell.y * Constants.TILE_SIZE + Constants.TILE_SIZE * 0.5
	)


func _tower_id(tower: Tower) -> int:
	return tower.get_instance_id() % 100000
