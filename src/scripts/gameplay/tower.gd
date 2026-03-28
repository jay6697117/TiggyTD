extends CharacterBody2D
class_name Tower

# ---------------------------------------------------------------------------
# Tower — 动物塔基类
# GDD：tower-attack.md
# 依赖：GridManager, Constants
# ---------------------------------------------------------------------------

# 内嵌动物数据库（MVP 占位，后期替换为 AnimalDB autoload）
const ANIMAL_DB: Dictionary = {
	"tiger":      {"cost": 120, "hp": 300, "atk": 60,  "atk_speed": 1.2, "range": 2.0, "armor_rate": 0.20},
	"lion":       {"cost": 150, "hp": 260, "atk": 80,  "atk_speed": 0.8, "range": 2.5, "armor_rate": 0.15},
	"elephant":   {"cost": 130, "hp": 450, "atk": 45,  "atk_speed": 0.5, "range": 1.5, "armor_rate": 0.30},
	"cheetah":    {"cost": 100, "hp": 150, "atk": 25,  "atk_speed": 2.5, "range": 3.0, "armor_rate": 0.05},
	"eagle":      {"cost": 160, "hp": 130, "atk": 50,  "atk_speed": 1.0, "range": 7.0, "armor_rate": 0.0},
	"wolf_pack":  {"cost": 110, "hp": 150, "atk": 22,  "atk_speed": 1.8, "range": 2.5, "armor_rate": 0.0},
	"owl":        {"cost": 110, "hp": 140, "atk": 20,  "atk_speed": 1.0, "range": 5.0, "armor_rate": 0.0},
	"otter":      {"cost": 80,  "hp": 160, "atk": 10,  "atk_speed": 1.5, "range": 3.0, "armor_rate": 0.10},
	"peacock":    {"cost": 90,  "hp": 120, "atk": 15,  "atk_speed": 0.8, "range": 3.5, "armor_rate": 0.0},
	"chameleon":  {"cost": 80,  "hp": 120, "atk": 12,  "atk_speed": 1.8, "range": 2.0, "armor_rate": 0.0},
	"honey_badger":{"cost": 110,"hp": 250, "atk": 35,  "atk_speed": 1.2, "range": 1.5, "armor_rate": 0.25},
	"pangolin":   {"cost": 160, "hp": 350, "atk": 40,  "atk_speed": 0.7, "range": 1.5, "armor_rate": 0.45},
}

# ── 运行时状态 ──────────────────────────────────────────────────────────────
var animal_id: String = "cheetah"
var _data: Dictionary

var hp: float
var max_hp: float
var _atk: float
var _atk_speed: float
var _range_px: float      # range in pixels
var armor_rate: float     # 敌人攻击时读取

var _attack_timer: float = 0.0
var _current_target: Enemy = null

# 格子坐标（放置时记录，回收时用）
var grid_cell: Vector2i = Vector2i(-1, -1)

# buff 叠加字典：{ buff_id -> {duration, atk_mult, speed_mult} }
var _buffs: Dictionary = {}

# 升级
const MAX_LEVEL := 3
var level: int = 1

signal tower_destroyed(tower: Tower)

# 各动物占位色（无美术资源时可视区分）
const ANIMAL_COLORS: Dictionary = {
	"cheetah":     Color(0.95, 0.80, 0.20),
	"wolf_pack":   Color(0.50, 0.50, 0.70),
	"honey_badger":Color(0.30, 0.30, 0.30),
	"elephant":    Color(0.60, 0.60, 0.65),
	"pangolin":    Color(0.70, 0.55, 0.35),
	"tiger":       Color(0.90, 0.50, 0.10),
	"lion":        Color(0.95, 0.75, 0.30),
	"eagle":       Color(0.30, 0.50, 0.90),
	"owl":         Color(0.55, 0.40, 0.70),
	"otter":       Color(0.40, 0.70, 0.60),
	"peacock":     Color(0.10, 0.75, 0.60),
	"chameleon":   Color(0.30, 0.80, 0.30),
}


func _draw() -> void:
	var col: Color = ANIMAL_COLORS.get(animal_id, Color(0.8, 0.8, 0.8))
	# 高等级颜色加深
	if level == 2:
		col = col.darkened(0.25)
	elif level == 3:
		col = col.darkened(0.45)
	var half := Constants.TILE_SIZE * 0.5 - 6.0
	draw_rect(Rect2(-half, -half, half * 2.0, half * 2.0), col)
	draw_rect(Rect2(-half, -half, half * 2.0, half * 2.0), Color.WHITE, false, 2.0)
	# 等级角标（右上角小圆点）
	if level > 1:
		for i in level:
			draw_circle(Vector2(half - 5.0 - i * 9.0, -half + 5.0), 4.0, Color.YELLOW)


func setup(id: String, cell: Vector2i) -> void:
	add_to_group("towers")
	animal_id = id
	grid_cell  = cell
	_data = ANIMAL_DB[id]
	hp         = float(_data["hp"])
	max_hp     = hp
	_atk       = float(_data["atk"])
	_atk_speed = float(_data["atk_speed"])
	_range_px  = float(_data["range"]) * Constants.TILE_SIZE
	armor_rate = float(_data["armor_rate"])


func upgrade_cost() -> int:
	return int(_data["cost"]) * level


func can_upgrade() -> bool:
	return level < MAX_LEVEL


func upgrade() -> void:
	if not can_upgrade():
		return
	level += 1
	_atk   *= 1.3
	max_hp *= 1.2
	hp      = minf(hp * 1.2, max_hp)
	queue_redraw()


func _process(delta: float) -> void:
	if hp <= 0.0:
		return
	_process_buffs(delta)
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	_find_target()
	if _current_target != null and is_instance_valid(_current_target):
		_fire()


func _process_buffs(delta: float) -> void:
	for id in _buffs.keys():
		_buffs[id]["duration"] -= delta
		if _buffs[id]["duration"] <= 0.0:
			_buffs.erase(id)


func apply_buff(buff_id: String, duration: float, atk_mult: float = 1.0, speed_mult: float = 1.0) -> void:
	_buffs[buff_id] = {"duration": duration, "atk_mult": atk_mult, "speed_mult": speed_mult}


# ── 攻击 ────────────────────────────────────────────────────────────────────

func _find_target() -> void:
	var space := get_world_2d().direct_space_state
	var params := PhysicsShapeQueryParameters2D.new()
	var shape  := CircleShape2D.new()
	shape.radius = _range_px
	params.shape = shape
	params.transform = Transform2D(0.0, position)
	params.collision_mask = Constants.LAYER_ENEMIES
	var results := space.intersect_shape(params, 16)

	var best: Enemy = null
	var best_progress: int = -1
	for r in results:
		var body = r["collider"]
		if not (body is Enemy):
			continue
		var e := body as Enemy
		# 翼龙只被 range >= 3 的塔命中
		if e.is_flying and _data["range"] < 3.0:
			continue
		# First 策略：选路径进度最靠前的
		if e._waypoint_index > best_progress:
			best_progress = e._waypoint_index
			best = e
	_current_target = best


func _fire() -> void:
	var aura_bonus: float = _get_aura_bonus()
	var eff_speed := _atk_speed * (1.0 + aura_bonus)
	var eff_atk := _atk
	for buff in _buffs.values():
		eff_speed *= buff.get("speed_mult", 1.0)
		eff_atk   *= buff.get("atk_mult",   1.0)
	_attack_timer = 1.0 / eff_speed
	var final_dmg := eff_atk * (1.0 - clampf(_current_target._armor_rate, 0.0, 1.0))
	_current_target.take_damage(final_dmg)


func _get_aura_bonus() -> float:
	var heroes := get_tree().get_nodes_in_group("hero")
	for h in heroes:
		if h.has_method("get_aura_bonus_for"):
			var bonus: float = h.get_aura_bonus_for(position)
			if bonus > 0.0:
				return bonus
	return 0.0


# ── 受伤（被敌人攻击） ──────────────────────────────────────────────────────

func take_damage(amount: float, _source = null) -> void:
	var dmg := amount * (1.0 - clampf(armor_rate, 0.0, 1.0))
	hp -= dmg
	if hp <= 0.0:
		hp = 0.0
		_on_destroyed()


func apply_bleed(dps: float, duration: float) -> void:
	# 简单实现：创建一次性 Timer 每秒造成伤害
	var elapsed := 0.0
	var ticks := int(duration)
	for i in ticks:
		var t := Timer.new()
		t.wait_time = float(i + 1)
		t.one_shot = true
		add_child(t)
		t.timeout.connect(func(): take_damage(dps); t.queue_free())
		t.start()


func _on_destroyed() -> void:
	GridManager.grid.vacate(grid_cell.x, grid_cell.y)
	GridManager.obstacle_changed.emit()
	tower_destroyed.emit(self)
	queue_free()
