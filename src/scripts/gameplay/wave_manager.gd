extends Node

# ---------------------------------------------------------------------------
# WaveManager — 波次系统
# GDD：wave-system.md
# 依赖：GameState, GridManager, Constants
# ---------------------------------------------------------------------------

const PREPARE_TIME_FIRST := 30.0
const PREPARE_TIME       := 15.0
const SPAWN_INTERVAL     := 1.5

# 波次配置：每条为 [enemy_id, count]
const WAVE_CONFIG: Array = [
	# Wave 1
	[["raptor", 5]],
	# Wave 2
	[["raptor", 4], ["pterodactyl", 3]],
	# Wave 3
	[["triceratops", 3], ["raptor", 4]],
	# Wave 4
	[["brachiosaurus", 1], ["raptor", 6]],
	# Wave 5
	[["saber_tooth", 4], ["triceratops", 2]],
	# Wave 6
	[["mammoth", 3], ["saber_tooth", 3]],
	# Wave 7
	[["cave_bear", 3], ["mammoth", 2], ["saber_tooth", 2]],
	# Wave 8
	[["dunkleosteus", 3], ["mosasaurus", 4]],
	# Wave 9
	[["ammonite", 5], ["ammonite", 5], ["dunkleosteus", 3]],
	# Wave 10 (Boss)
	[["trex_king", 1]],
]

const EnemyScene := preload("res://scripts/gameplay/enemy.gd")

var _enemies_node: Node2D          # Main/Entities/Enemies
var _spawn_queue: Array = []       # 待生成的 enemy_id 列表
var _alive_count: int = 0
var _spawn_timer: float = 0.0
var _spawning: bool = false
var _prepare_timer: float = 0.0
var _preparing: bool = false

func _ready() -> void:
	add_to_group("wave_manager")


func setup(enemies_node: Node2D) -> void:
	_enemies_node = enemies_node
	GameState.state_changed.connect(_on_state_changed)


func _process(delta: float) -> void:
	if _preparing:
		_prepare_timer -= delta
		if _prepare_timer <= 0.0:
			_preparing = false
			_begin_spawn()
		return
	if _spawning and _spawn_queue.size() > 0:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_timer = SPAWN_INTERVAL
			var id: String = _spawn_queue.pop_front()
			_spawn_enemy(id, _get_spawn_position())
		if _spawn_queue.is_empty():
			_spawning = false
			if _alive_count <= 0:
				_wave_cleared()


# ── 公开接口 ────────────────────────────────────────────────────────────────

# 由 boss_phase 能力调用（召唤援军）
func spawn_reinforcements(id: String, count: int, near_pos: Vector2) -> void:
	for i in count:
		var e := _create_enemy(id)
		e.position = near_pos + Vector2(randf_range(-32, 32), randf_range(-32, 32))
		e.died.connect(_on_enemy_left.bind(e))
		e.reached_base.connect(_on_enemy_left.bind(e))
		_enemies_node.add_child(e)
		_alive_count += 1


# ── 内部流程 ────────────────────────────────────────────────────────────────

func _on_state_changed(new_state: GameState.State) -> void:
	if new_state == GameState.State.WAVE:
		_start_wave_prep()


func _start_wave_prep() -> void:
	var wave_idx := GameState.current_wave  # 0-based
	if wave_idx >= WAVE_CONFIG.size():
		return
	# 发放波次补贴（Boss 波不发）
	if wave_idx < 9:
		var bonus := 50 + wave_idx * 10
		GameState.add_gold(bonus)
	# 准备计时
	_prepare_timer = PREPARE_TIME_FIRST if wave_idx == 0 else PREPARE_TIME
	_preparing = true


func _begin_spawn() -> void:
	var wave_idx := GameState.current_wave
	_spawn_queue.clear()
	for group in WAVE_CONFIG[wave_idx]:
		var id: String = group[0]
		var count: int  = group[1]
		for _i in count:
			_spawn_queue.append(id)
	_alive_count = _spawn_queue.size()
	_spawning = true
	_spawn_timer = 0.0  # 立即生成第一个


func _spawn_enemy(id: String, pos: Vector2) -> void:
	var e := _create_enemy(id)
	e.position = pos
	e.died.connect(_on_enemy_left.bind(e))
	e.reached_base.connect(_on_enemy_left.bind(e))
	_enemies_node.add_child(e)


func _create_enemy(id: String) -> Enemy:
	var e := CharacterBody2D.new()
	e.set_script(EnemyScene)
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 20.0
	col.shape = shape
	e.add_child(col)
	e.collision_layer = Constants.LAYER_ENEMIES
	e.collision_mask  = Constants.LAYER_TOWERS | Constants.LAYER_PATH
	e.call_deferred("setup", id)
	return e


func _on_enemy_left(_enemy: Enemy) -> void:
	_alive_count -= 1
	if _alive_count <= 0 and not _spawning:
		_wave_cleared()


func _wave_cleared() -> void:
	var wave_idx := GameState.current_wave
	GameState.current_wave += 1
	GameState.wave_changed.emit(GameState.current_wave)
	if wave_idx >= 9:  # 最终波清场（胜负由 GameState.damage_base 或敌人死亡处理）
		GameState.change_state(GameState.State.WIN)
	else:
		GameState.change_state(GameState.State.BUILD)


func _get_spawn_position() -> Vector2:
	var spawn_cell := MapGrid.WAYPOINTS[0]
	return Vector2(
		spawn_cell.x * Constants.TILE_SIZE + Constants.TILE_SIZE * 0.5,
		spawn_cell.y * Constants.TILE_SIZE + Constants.TILE_SIZE * 0.5
	)
