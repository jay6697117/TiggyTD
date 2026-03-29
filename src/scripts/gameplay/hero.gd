extends Node2D
class_name Hero

# ---------------------------------------------------------------------------
# Hero — 英雄（老虎）：移动 + 光环 + 三个主动技能
# Sprint 3 实现：百兽怒吼(Q)、自然之召(W)、纪元审判(E)
# ---------------------------------------------------------------------------

const SPEED                  := 3.5 * 64.0
const ARRIVAL_DIST           := 6.0
const AURA_RADIUS_PX         := 3.0 * 64.0
const NATURES_CALL_RADIUS_PX := 5.0 * 64.0

const CD_APEX_ROAR      := 30.0
const CD_NATURES_CALL   := 45.0
const CD_ERA_JUDGEMENT  := 120.0

enum State { IDLE, MOVING, CASTING, TARGET_SELECT }

var _state: State = State.IDLE
var _path: Array[Vector2] = []
var _path_idx: int = 0

# 施法
var _cast_timer: float = 0.0
var _cast_skill: String = ""
var _era_target: Enemy = null

# 冷却（剩余秒数，0 = 就绪）
var _cd_apex_roar: float     = 0.0
var _cd_natures_call: float  = 0.0
var _cd_era_judgement: float = 0.0

# 运行时可被天赋修改的参数
var _apex_roar_duration: float    = 8.0
var _apex_roar_cd_max: float      = CD_APEX_ROAR
var _natures_call_atk_mult: float = 1.3
var _natures_call_radius: float   = NATURES_CALL_RADIUS_PX
var _era_dmg: float               = 300.0
var _era_cd_max: float            = CD_ERA_JUDGEMENT
var _aura_radius: float           = AURA_RADIUS_PX
var _aura_bonus: float            = 0.20
var _hero_speed: float            = SPEED
var _gold_kill_counter: int       = 0

# EXP / 天赋
const EXP_THRESHOLDS: Array[int] = [50, 120, 250]
const ALL_TALENTS: Array[String] = [
	"apex_duration", "apex_cd", "natures_atk", "natures_range",
	"era_dmg", "era_cd", "aura_range", "aura_bonus",
	"speed", "vision", "gold_touch", "base_hp"
]
var exp: int = 0
var hero_level: int = 1
var _talent_pool: Array[String] = []
var selected_talents: Array[String] = []

# HUD 订阅此信号更新按钮显示
signal skill_cd_updated(skill: String, remaining: float, max_cd: float)
signal level_up_ready(choices: Array[String])
signal exp_changed(cur: int, threshold: int)


func _ready() -> void:
	add_to_group("hero")
	position = Vector2(64 * 1 + 32, 64 * 7 + 32)
	_talent_pool = ALL_TALENTS.duplicate()


func _process(delta: float) -> void:
	if _state == State.MOVING:
		_move_along_path(delta)
	elif _state == State.CASTING:
		_cast_timer -= delta
		if _cast_timer <= 0.0:
			_execute_skill(_cast_skill)
			_state = State.IDLE
	_tick_cooldowns(delta)
	queue_redraw()


func _tick_cooldowns(delta: float) -> void:
	if _cd_apex_roar > 0.0:
		_cd_apex_roar = maxf(_cd_apex_roar - delta, 0.0)
		skill_cd_updated.emit("apex_roar", _cd_apex_roar, CD_APEX_ROAR)
	if _cd_natures_call > 0.0:
		_cd_natures_call = maxf(_cd_natures_call - delta, 0.0)
		skill_cd_updated.emit("natures_call", _cd_natures_call, CD_NATURES_CALL)
	if _cd_era_judgement > 0.0:
		_cd_era_judgement = maxf(_cd_era_judgement - delta, 0.0)
		skill_cd_updated.emit("era_judgement", _cd_era_judgement, CD_ERA_JUDGEMENT)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		var world_pos := get_canvas_transform().affine_inverse() * mb.position
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if _state == State.CASTING:
				return
			if _state == State.TARGET_SELECT:
				# 右键取消选目标，不消耗 CD
				_state = State.IDLE
				return
			_set_destination(world_pos)
		elif mb.button_index == MOUSE_BUTTON_LEFT and _state == State.TARGET_SELECT:
			_try_era_judgement_target(world_pos)
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Q: activate_skill("apex_roar")
			KEY_W: activate_skill("natures_call")
			KEY_E: activate_skill("era_judgement")


# 供 HUD 技能按钮调用
func activate_skill(skill: String) -> void:
	if _state == State.CASTING or _state == State.TARGET_SELECT:
		return
	match skill:
		"apex_roar":
			if _cd_apex_roar > 0.0:
				return
			_state = State.CASTING
			_cast_skill = "apex_roar"
			_cast_timer = 0.5
		"natures_call":
			if _cd_natures_call > 0.0:
				return
			_state = State.CASTING
			_cast_skill = "natures_call"
			_cast_timer = 0.8
		"era_judgement":
			if _cd_era_judgement > 0.0:
				return
			_state = State.TARGET_SELECT


func _execute_skill(skill: String) -> void:
	match skill:
		"apex_roar":
			_do_apex_roar()
			_cd_apex_roar = _apex_roar_cd_max
			skill_cd_updated.emit("apex_roar", _cd_apex_roar, _apex_roar_cd_max)
		"natures_call":
			_do_natures_call()
			_cd_natures_call = CD_NATURES_CALL
			skill_cd_updated.emit("natures_call", _cd_natures_call, CD_NATURES_CALL)
		"era_judgement":
			_do_era_judgement()
			_cd_era_judgement = _era_cd_max
			skill_cd_updated.emit("era_judgement", _cd_era_judgement, _era_cd_max)


func _do_apex_roar() -> void:
	for t in get_tree().get_nodes_in_group("towers"):
		if t is Tower:
			t.apply_buff("apex_roar", _apex_roar_duration, 1.0, 1.5)


func _do_natures_call() -> void:
	for t in get_tree().get_nodes_in_group("towers"):
		if t is Tower and position.distance_to(t.position) <= _natures_call_radius:
			t.apply_buff("natures_call", 10.0, _natures_call_atk_mult, 1.0)


func _try_era_judgement_target(world_pos: Vector2) -> void:
	var space := get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = world_pos
	params.collision_mask = Constants.LAYER_ENEMIES
	var results := space.intersect_point(params, 4)
	var target: Enemy = null
	for r in results:
		if r["collider"] is Enemy:
			target = r["collider"] as Enemy
			break
	if target == null:
		# 点击空地取消，不消耗 CD
		_state = State.IDLE
		return
	_era_target = target
	_state = State.CASTING
	_cast_skill = "era_judgement"
	_cast_timer = 1.5


func _do_era_judgement() -> void:
	if _era_target != null and is_instance_valid(_era_target):
		if _era_target.has_method("break_shield") and _era_target._shield_active:
			_era_target.break_shield()
		else:
			_era_target.take_damage(_era_dmg, true)
	_era_target = null


func reset_cooldowns() -> void:
	_cd_apex_roar     = 0.0
	_cd_natures_call  = 0.0
	_cd_era_judgement = 0.0
	skill_cd_updated.emit("apex_roar",     0.0, CD_APEX_ROAR)
	skill_cd_updated.emit("natures_call",  0.0, CD_NATURES_CALL)
	skill_cd_updated.emit("era_judgement", 0.0, CD_ERA_JUDGEMENT)


func gain_exp(amount: int) -> void:
	if hero_level >= 4:
		return
	exp += amount
	var threshold := EXP_THRESHOLDS[hero_level - 1]
	exp_changed.emit(exp, threshold)
	if exp >= threshold:
		exp -= threshold
		hero_level += 1
		_trigger_level_up()


func _trigger_level_up() -> void:
	var count := mini(3, _talent_pool.size())
	if count == 0:
		return
	var pool_copy := _talent_pool.duplicate()
	pool_copy.shuffle()
	var choices := pool_copy.slice(0, count)
	level_up_ready.emit(choices)


func apply_talent(id: String) -> void:
	if id in selected_talents:
		return
	selected_talents.append(id)
	_talent_pool.erase(id)
	match id:
		"apex_duration": _apex_roar_duration += 4.0
		"apex_cd":       _apex_roar_cd_max = maxf(_apex_roar_cd_max - 10.0, 5.0)
		"natures_atk":   _natures_call_atk_mult += 0.1
		"natures_range":  _natures_call_radius += 2.0 * Constants.TILE_SIZE
		"era_dmg":        _era_dmg += 150.0
		"era_cd":         _era_cd_max = maxf(_era_cd_max - 30.0, 10.0)
		"aura_range":     _aura_radius += 2.0 * Constants.TILE_SIZE
		"aura_bonus":     _aura_bonus += 0.10
		"speed":          _hero_speed *= 1.3
		"vision":         pass  # MVP 无战争迷雾，无实际效果
		"gold_touch":     _gold_kill_counter = 0  # 激活计数（enemy.gd 侧检测）
		"base_hp":        GameState.base_hp_max += 2
	# 选完天赋后检查是否积累的EXP已达到下一级阈值
	gain_exp(0)


func on_enemy_killed() -> void:
	if "gold_touch" in selected_talents:
		_gold_kill_counter += 1
		if _gold_kill_counter >= 10:
			_gold_kill_counter = 0
			GameState.add_gold(5)


func reset_hero() -> void:
	_apex_roar_duration    = 8.0
	_apex_roar_cd_max      = CD_APEX_ROAR
	_natures_call_atk_mult = 1.3
	_natures_call_radius   = NATURES_CALL_RADIUS_PX
	_era_dmg               = 300.0
	_era_cd_max            = CD_ERA_JUDGEMENT
	_aura_radius           = AURA_RADIUS_PX
	_aura_bonus            = 0.20
	_hero_speed            = SPEED
	_gold_kill_counter     = 0
	exp            = 0
	hero_level     = 1
	_talent_pool   = ALL_TALENTS.duplicate()
	selected_talents.clear()
	reset_cooldowns()


# 供 Tower 查询光环加成
func get_aura_bonus_for(tower_pos: Vector2) -> float:
	if position.distance_to(tower_pos) <= _aura_radius:
		return _aura_bonus
	return 0.0


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
	position += diff.normalized() * _hero_speed * delta


func _draw() -> void:
	# 英雄色块
	draw_circle(Vector2.ZERO, 18.0, Color(1.0, 0.55, 0.0))
	draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 32, Color.WHITE, 2.0)
	# TARGET_SELECT 状态：准星颜色提示
	if _state == State.TARGET_SELECT:
		draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 32, Color.RED, 3.0)
	# 光环范围圆圈
	draw_arc(Vector2.ZERO, _aura_radius, 0.0, TAU, 64, Color(1.0, 0.85, 0.0, 0.25), 1.5)
