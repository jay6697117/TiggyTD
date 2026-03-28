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

# HUD 订阅此信号更新按钮显示
signal skill_cd_updated(skill: String, remaining: float, max_cd: float)


func _ready() -> void:
	add_to_group("hero")
	position = Vector2(64 * 1 + 32, 64 * 7 + 32)


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
			_cd_apex_roar = CD_APEX_ROAR
			skill_cd_updated.emit("apex_roar", _cd_apex_roar, CD_APEX_ROAR)
		"natures_call":
			_do_natures_call()
			_cd_natures_call = CD_NATURES_CALL
			skill_cd_updated.emit("natures_call", _cd_natures_call, CD_NATURES_CALL)
		"era_judgement":
			_do_era_judgement()
			_cd_era_judgement = CD_ERA_JUDGEMENT
			skill_cd_updated.emit("era_judgement", _cd_era_judgement, CD_ERA_JUDGEMENT)


func _do_apex_roar() -> void:
	for t in get_tree().get_nodes_in_group("towers"):
		if t is Tower:
			t.apply_buff("apex_roar", 8.0, 1.0, 1.5)


func _do_natures_call() -> void:
	for t in get_tree().get_nodes_in_group("towers"):
		if t is Tower and position.distance_to(t.position) <= NATURES_CALL_RADIUS_PX:
			t.apply_buff("natures_call", 10.0, 1.3, 1.0)


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
			_era_target.take_damage(300.0, true)  # true = 无视护甲
	_era_target = null


func reset_cooldowns() -> void:
	_cd_apex_roar     = 0.0
	_cd_natures_call  = 0.0
	_cd_era_judgement = 0.0
	skill_cd_updated.emit("apex_roar",     0.0, CD_APEX_ROAR)
	skill_cd_updated.emit("natures_call",  0.0, CD_NATURES_CALL)
	skill_cd_updated.emit("era_judgement", 0.0, CD_ERA_JUDGEMENT)


# 供 Tower 查询光环加成
func get_aura_bonus_for(tower_pos: Vector2) -> float:
	if position.distance_to(tower_pos) <= AURA_RADIUS_PX:
		return 0.20
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
	position += diff.normalized() * SPEED * delta


func _draw() -> void:
	# 英雄色块
	draw_circle(Vector2.ZERO, 18.0, Color(1.0, 0.55, 0.0))
	draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 32, Color.WHITE, 2.0)
	# TARGET_SELECT 状态：准星颜色提示
	if _state == State.TARGET_SELECT:
		draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 32, Color.RED, 3.0)
	# 光环范围圆圈
	draw_arc(Vector2.ZERO, AURA_RADIUS_PX, 0.0, TAU, 64, Color(1.0, 0.85, 0.0, 0.25), 1.5)
