extends CharacterBody2D
class_name Enemy

# ---------------------------------------------------------------------------
# Enemy — 敌人基类
# GDD：enemy-ai.md
# 依赖：GridManager, GameState, Constants
# ---------------------------------------------------------------------------

const DamageLabelScene := preload("res://scripts/ui/damage_label.gd")

# 内嵌敌人数据库（MVP 占位，后期替换为 EnemyDB autoload）
const ENEMY_DB: Dictionary = {
	"raptor":     {"hp": 80,   "atk": 15, "speed": 90.0,  "armor_rate": 0.0,  "abilities": ["dash"],         "reward": 10, "base_dmg": 1},
	"pterodactyl":{"hp": 60,   "atk": 12, "speed": 110.0, "armor_rate": 0.0,  "abilities": ["fly"],          "reward": 12, "base_dmg": 1},
	"triceratops": {"hp": 200, "atk": 25, "speed": 55.0,  "armor_rate": 0.10, "abilities": ["charge"],       "reward": 20, "base_dmg": 1},
	"brachiosaurus":{"hp": 400,"atk": 30, "speed": 35.0,  "armor_rate": 0.30, "abilities": ["trample"],      "reward": 40, "base_dmg": 2},
	"saber_tooth": {"hp": 150, "atk": 20, "speed": 85.0,  "armor_rate": 0.05, "abilities": ["bleed"],        "reward": 18, "base_dmg": 1},
	"mammoth":    {"hp": 350,  "atk": 40, "speed": 40.0,  "armor_rate": 0.35, "abilities": ["tusk_strike"],  "reward": 35, "base_dmg": 2},
	"cave_bear":  {"hp": 280,  "atk": 28, "speed": 50.0,  "armor_rate": 0.20, "abilities": ["ice_armor"],    "reward": 28, "base_dmg": 1},
	"dunkleosteus":{"hp": 300, "atk": 35, "speed": 60.0,  "armor_rate": 0.25, "abilities": ["steel_bite"],   "reward": 30, "base_dmg": 2},
	"mosasaurus": {"hp": 260,  "atk": 30, "speed": 70.0,  "armor_rate": 0.15, "abilities": ["aqua_dash"],    "reward": 25, "base_dmg": 1},
	"ammonite":   {"hp": 50,   "atk": 8,  "speed": 75.0,  "armor_rate": 0.0,  "abilities": ["swarm"],        "reward": 6,  "base_dmg": 1},
	"trex_king":  {"hp": 2000, "atk": 80, "speed": 45.0,  "armor_rate": 0.40, "abilities": ["boss_phase"],   "reward": 200,"base_dmg": 5},
}

# ── 运行时状态 ──────────────────────────────────────────────────────────────
var enemy_id: String = "raptor"
var _data: Dictionary

var hp: float
var max_hp: float
var _speed_base: float
var _speed_current: float
var _atk: float
var _armor_rate: float
var _base_dmg: int

# 路径跟随
var _waypoint_index: int = 0
const WAYPOINTS := MapGrid.WAYPOINTS

# 攻击计时
var _attack_timer: float = 0.0
const ATTACK_INTERVAL := 1.0

# 当前攻击目标（Tower 节点）
var _attack_target: Node = null
var _is_attacking: bool = false

# 特殊能力计时
var _ability_timer: float = 0.0
var is_flying: bool = false  # 翼龙标记，塔攻击时检查

# dash 状态
var _dash_active: bool = false
var _dash_timer: float = 0.0
const DASH_DURATION := 3.0
const DASH_CD       := 5.0

# charge 状态（三角龙）
var _charge_triggered: bool = false

# boss 阶段（霸王龙王）
var _boss_phase: int = 0
var is_boss: bool = false
var _shield_active: bool = false
var _shield_timer: float = 0.0

# 状态效果
var active_effects: Array = []  # Array[StatusEffect]
var _is_slowed: bool = false
var _is_feared: bool = false
var _is_stunned: bool = false
var _armor_broken: bool = false
var _poison_stacks: int = 0
var _poison_tick_timer: float = 0.0

signal died(enemy: Enemy)
signal reached_base(enemy: Enemy)


func setup(id: String) -> void:
	enemy_id = id
	_data = ENEMY_DB[id]
	hp           = float(_data["hp"])
	max_hp       = hp
	_speed_base  = float(_data["speed"])
	_speed_current = _speed_base
	_atk         = float(_data["atk"])
	_armor_rate  = float(_data["armor_rate"])
	_base_dmg    = int(_data["base_dmg"])
	is_flying    = "fly" in _data["abilities"]
	is_boss      = (id == "trex_king")
	_waypoint_index = 0
	# 起点位置
	position = _cell_center(WAYPOINTS[0])
	_add_sprite()


func _add_sprite() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/art/enemies/%s.png" % enemy_id)
	var s := float(Constants.TILE_SIZE) / 256.0
	sprite.scale = Vector2(s, s)
	add_child(sprite)


func _physics_process(delta: float) -> void:
	if hp <= 0.0:
		return
	_tick_status_effects(delta)
	_update_abilities(delta)
	if _is_attacking:
		_do_attack(delta)
	else:
		_move_along_path(delta)
		_check_attack_range()


# ── 移动 ────────────────────────────────────────────────────────────────────

func _move_along_path(delta: float) -> void:
	if _is_stunned:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if _waypoint_index >= WAYPOINTS.size():
		_on_reach_base()
		return
	var target_world: Vector2
	if _is_feared:
		# 恐惧：朝起点方向逃跑
		var flee_idx := maxi(0, _waypoint_index - 1)
		target_world = _cell_center(WAYPOINTS[flee_idx])
	else:
		target_world = _cell_center(WAYPOINTS[_waypoint_index])
	var dir := (target_world - position)
	if dir.length() < 4.0:
		if not _is_feared:
			_waypoint_index += 1
			if _waypoint_index >= WAYPOINTS.size():
				_on_reach_base()
				return
			target_world = _cell_center(WAYPOINTS[_waypoint_index])
			dir = target_world - position
	var spd := _speed_current
	if _is_slowed:
		spd = _speed_base * Constants.SLOW_FACTOR
	velocity = dir.normalized() * spd
	move_and_slide()


# ── 攻击检测 ────────────────────────────────────────────────────────────────

func _check_attack_range() -> void:
	var space := get_world_2d().direct_space_state
	var params := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = float(Constants.TILE_SIZE) * 1.2  # 约1格半径
	params.shape = shape
	params.transform = Transform2D(0.0, position)
	params.collision_mask = Constants.LAYER_TOWERS
	var results := space.intersect_shape(params, 4)
	for r in results:
		var body = r["collider"]
		if body != null and body.has_method("take_damage"):
			_attack_target = body
			_is_attacking = true
			_attack_timer = 0.0
			return


func _do_attack(delta: float) -> void:
	if _is_stunned:
		return
	if not is_instance_valid(_attack_target):
		_attack_target = null
		_is_attacking = false
		return
	# 检查目标是否还在范围内
	var dist := position.distance_to(_attack_target.position)
	if dist > float(Constants.TILE_SIZE) * 1.5:
		_attack_target = null
		_is_attacking = false
		return
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = ATTACK_INTERVAL
		var dmg := _calc_damage(_atk, 0.0)  # 敌人攻击塔，塔护甲由塔自己处理
		_attack_target.take_damage(dmg, self)
		_apply_on_hit_ability()


# ── 特殊能力 ────────────────────────────────────────────────────────────────

func _update_abilities(delta: float) -> void:
	var abilities: Array = _data["abilities"]
	_ability_timer += delta

	if "dash" in abilities:
		if _dash_active:
			_dash_timer -= delta
			if _dash_timer <= 0.0:
				_dash_active = false
				_speed_current = _speed_base
				_ability_timer = 0.0
		elif _ability_timer >= DASH_CD:
			_dash_active = true
			_dash_timer = DASH_DURATION
			_speed_current = _speed_base * 2.0
			_ability_timer = 0.0

	if "charge" in abilities and not _charge_triggered:
		_check_charge()

	if "boss_phase" in abilities:
		_update_boss_phases(delta)


func _check_charge() -> void:
	var cell := GridManager.grid.world_to_cell(position)
	var forward := _get_forward_cell(cell)
	if not GridManager.grid._in_bounds(forward.x, forward.y):
		return
	if GridManager.grid._occupied[forward.x][forward.y] != -1:
		_charge_triggered = true
		# 通知 TowerPlacementManager 处理推塔（由 main 场景连接）
		get_tree().call_group("tower_placement", "push_tower", forward, _get_move_direction())


func _get_forward_cell(cell: Vector2i) -> Vector2i:
	var dir := _get_move_direction()
	return Vector2i(cell.x + dir.x, cell.y + dir.y)


func _get_move_direction() -> Vector2i:
	if _waypoint_index < WAYPOINTS.size() - 1:
		var cur  := WAYPOINTS[_waypoint_index]
		var nxt  := WAYPOINTS[mini(_waypoint_index + 1, WAYPOINTS.size() - 1)]
		return Vector2i(sign(nxt.x - cur.x), sign(nxt.y - cur.y))
	return Vector2i(1, 0)


func _apply_on_hit_ability() -> void:
	var abilities: Array = _data["abilities"]
	if "bleed" in abilities and is_instance_valid(_attack_target):
		# 剑齿虎流血：对塔每秒造成 atk*0.3 真实伤害，持续3秒
		var bleed_dps := _atk * 0.3
		for i in 3:
			var t := Timer.new()
			t.wait_time = float(i + 1)
			t.one_shot = true
			add_child(t)
			t.timeout.connect(func():
				if is_instance_valid(_attack_target):
					_attack_target.take_damage(bleed_dps)
				t.queue_free())
			t.start()
	if "steel_bite" in abilities and is_instance_valid(_attack_target):
		var dmg := _atk * (1.0 - maxf(0.0, _attack_target.armor_rate - 0.2))
		_attack_target.take_damage(dmg - _calc_damage(_atk, 0.0), self)  # 额外的穿甲差值


# ── 状态效果 ────────────────────────────────────────────────────────────────

func apply_status(effect_id: String, duration: float, stacks: int = 1) -> void:
	# 查找是否已有同类效果
	for eff in active_effects:
		if eff.effect_id == effect_id:
			eff.duration_remaining = duration  # 刷新计时
			if effect_id == "poison" and eff.stack_count < Constants.POISON_MAX_STACKS:
				eff.stack_count += stacks
				eff.stack_count = mini(eff.stack_count, Constants.POISON_MAX_STACKS)
				_poison_stacks = eff.stack_count
			return
	# 新建效果
	var eff := StatusEffect.new()
	eff.init(effect_id, duration, stacks)
	active_effects.append(eff)
	_on_status_applied(effect_id)


func _on_status_applied(effect_id: String) -> void:
	match effect_id:
		"slow":
			_is_slowed = true
			_speed_current = _speed_base * Constants.SLOW_FACTOR
		"fear":
			_is_feared = true
		"stun":
			_is_stunned = true
		"poison":
			_poison_stacks = 1
		"armor_break":
			_armor_broken = true
			_armor_rate *= Constants.ARMOR_BREAK_FACTOR
	queue_redraw()


func _on_status_removed(effect_id: String) -> void:
	match effect_id:
		"slow":
			_is_slowed = false
			_speed_current = _speed_base
		"fear":
			_is_feared = false
		"stun":
			_is_stunned = false
		"poison":
			_poison_stacks = 0
		"armor_break":
			_armor_broken = false
			_armor_rate = float(_data["armor_rate"])  # 恢复原始值
	queue_redraw()


func _tick_status_effects(delta: float) -> void:
	var to_remove: Array = []
	for eff in active_effects:
		if eff.is_permanent:
			continue
		if eff.effect_id == "poison":
			eff._poison_tick_timer += delta
			if eff._poison_tick_timer >= 1.0:
				eff._poison_tick_timer -= 1.0
				var poison_dmg := Constants.POISON_DPS * float(_poison_stacks)
				take_damage(poison_dmg, true)  # 真实伤害，忽略护甲
		eff.duration_remaining -= delta
		if eff.duration_remaining <= 0.0:
			to_remove.append(eff)
	for eff in to_remove:
		active_effects.erase(eff)
		_on_status_removed(eff.effect_id)


func _update_boss_phases(delta: float) -> void:
	var hp_pct := hp / max_hp
	if _boss_phase == 0 and hp_pct <= 0.5:
		_boss_phase = 1
		_shield_active = true
		_shield_timer = Constants.BOSS_SHIELD_DURATION
		queue_redraw()
		get_tree().call_group("hud", "show_synergy_banner", "远古护盾已激活！")
		get_tree().call_group("hud", "on_boss_shield_changed", true)
	elif _boss_phase == 1 and _shield_active:
		_shield_timer -= delta
		if _shield_timer <= 0.0:
			_shield_active = false
			_speed_current *= 1.2
			_boss_phase = 2
			queue_redraw()
			get_tree().call_group("hud", "on_boss_shield_changed", false)


func break_shield() -> void:
	if not _shield_active:
		return
	_shield_active = false
	_boss_phase = 2
	queue_redraw()
	get_tree().call_group("hud", "on_boss_shield_changed", false)


func _notify_hud_boss_bar() -> void:
	get_tree().call_group("hud", "show_boss_bar", self)


# ── 受伤/死亡 ───────────────────────────────────────────────────────────────

func take_damage(amount: float, ignore_armor: bool = false) -> void:
	if hp <= 0.0:
		return
	# Boss 护盾：免疫所有非 ignore_armor 伤害
	if _shield_active and not ignore_armor:
		return
	# ice_armor（冰河巨熊）：20%概率伤害减半（无视护甲时跳过）
	if not ignore_armor and "ice_armor" in _data["abilities"] and randf() < 0.20:
		amount *= 0.5
	hp -= amount
	queue_redraw()
	_spawn_damage_label(amount)
	if is_boss:
		get_tree().call_group("hud", "update_boss_bar", hp)
	if hp <= 0.0:
		hp = 0.0
		_on_die()


func _spawn_label(text: String, color: Color, world_pos: Vector2, parent: Node) -> void:
	var lbl := DamageLabelScene.new()
	lbl.init(text, color, world_pos)
	parent.add_child(lbl)


func _spawn_damage_label(amount: float) -> void:
	var parent := get_parent()
	if parent == null:
		return
	_spawn_label(str(int(amount)), Color.WHITE, position, parent)


func _draw() -> void:
	var bar_w := 40.0
	var bar_h := 5.0
	var offset := Vector2(-bar_w * 0.5, -28.0)
	if hp < max_hp and max_hp > 0.0:
		draw_rect(Rect2(offset, Vector2(bar_w, bar_h)), Color(0.2, 0.2, 0.2))
		var fill := bar_w * clampf(hp / max_hp, 0.0, 1.0)
		draw_rect(Rect2(offset, Vector2(fill, bar_h)), Color(0.9, 0.15, 0.15))
	# 状态颜色点（HP条右侧）
	var dot_x := bar_w * 0.5 + 6.0
	var dot_y := -26.0
	if _is_slowed:
		draw_circle(Vector2(dot_x, dot_y), 3.0, Color(0.2, 0.4, 1.0))
		dot_x += 8.0
	if _is_stunned:
		draw_circle(Vector2(dot_x, dot_y), 3.0, Color(0.6, 0.6, 0.6))
		dot_x += 8.0
	if _poison_stacks > 0:
		draw_circle(Vector2(dot_x, dot_y), 3.0, Color(0.2, 0.8, 0.2))
		dot_x += 8.0
	if _is_feared:
		draw_circle(Vector2(dot_x, dot_y), 3.0, Color(0.6, 0.1, 0.8))
		dot_x += 8.0
	if _armor_broken:
		draw_circle(Vector2(dot_x, dot_y), 3.0, Color(1.0, 0.5, 0.1))
	# Boss 护盾光圈
	if _shield_active:
		draw_arc(Vector2.ZERO, float(Constants.TILE_SIZE) * 0.55, 0.0, TAU, 32, Color(0.3, 0.6, 1.0, 0.85), 3.0)


func _on_die() -> void:
	var reward := int(_data["reward"])
	GameState.add_gold(reward)
	GameState.kills_this_run += 1
	var parent := get_parent()
	if parent != null:
		_spawn_label("+%d" % reward, Color(1.0, 0.85, 0.1), position, parent)
		_spawn_death_particles(parent)
	died.emit(self)
	queue_free()


static var _death_vfx_this_frame: int = 0
static var _death_vfx_frame: int = -1

func _spawn_death_particles(parent: Node) -> void:
	# 同帧超过上限时随机跳过50%（GDD vfx.md 边缘情况）
	var cur_frame := Engine.get_process_frames()
	if cur_frame != Enemy._death_vfx_frame:
		Enemy._death_vfx_frame = cur_frame
		Enemy._death_vfx_this_frame = 0
	if Enemy._death_vfx_this_frame >= Constants.MAX_DEATH_VFX_PER_FRAME and randf() < 0.5:
		return
	Enemy._death_vfx_this_frame += 1
	_do_spawn_death_particles(parent)


func _do_spawn_death_particles(parent: Node) -> void:
	# 像素粒子：8个2×2色点向外散开，约20帧消失
	var dirs := [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1),
				 Vector2(1,1).normalized(), Vector2(-1,1).normalized(),
				 Vector2(1,-1).normalized(), Vector2(-1,-1).normalized()]
	for d in dirs:
		var p := ColorRect.new()
		p.size = Vector2(4, 4)
		p.color = Color(0.9, 0.5, 0.1)
		p.position = position - Vector2(2, 2)
		p.z_index = 9
		parent.add_child(p)
		var vel: Vector2 = d * randf_range(40.0, 90.0)
		# tween 驱动位移和淡出
		var tween := p.create_tween()
		tween.tween_property(p, "position", p.position + vel * 0.33, 0.33)
		tween.parallel().tween_property(p, "modulate:a", 0.0, 0.33)
		tween.tween_callback(p.queue_free)


func _on_reach_base() -> void:
	GameState.damage_base(_base_dmg)
	GameState.enemies_leaked += 1
	reached_base.emit(self)
	queue_free()


# ── 工具函数 ────────────────────────────────────────────────────────────────

func _calc_damage(atk: float, armor: float) -> float:
	return atk * (1.0 - clampf(armor, 0.0, 1.0))


func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * Constants.TILE_SIZE + Constants.TILE_SIZE * 0.5,
		cell.y * Constants.TILE_SIZE + Constants.TILE_SIZE * 0.5
	)
