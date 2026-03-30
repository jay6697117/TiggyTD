extends CharacterBody2D
class_name Tower

# ---------------------------------------------------------------------------
# Tower — 动物塔基类
# GDD：tower-attack.md
# 依赖：GridManager, Constants
# ---------------------------------------------------------------------------

# 内嵌动物数据库（MVP 占位，后期替换为 AnimalDB autoload）
const ANIMAL_DB: Dictionary = {
	"tiger":      {"cost": 120, "hp": 300, "atk": 60,  "atk_speed": 1.2, "range": 2.0, "armor_rate": 0.20, "ability": "stun"},
	"lion":       {"cost": 150, "hp": 260, "atk": 80,  "atk_speed": 0.8, "range": 2.5, "armor_rate": 0.15, "ability": ""},
	"elephant":   {"cost": 130, "hp": 450, "atk": 45,  "atk_speed": 0.5, "range": 1.5, "armor_rate": 0.30, "ability": ""},
	"cheetah":    {"cost": 100, "hp": 150, "atk": 25,  "atk_speed": 2.5, "range": 3.0, "armor_rate": 0.05, "ability": ""},
	"eagle":      {"cost": 160, "hp": 130, "atk": 50,  "atk_speed": 1.0, "range": 7.0, "armor_rate": 0.0,  "ability": ""},
	"wolf_pack":  {"cost": 110, "hp": 150, "atk": 22,  "atk_speed": 1.8, "range": 2.5, "armor_rate": 0.0,  "ability": "fear"},
	"owl":        {"cost": 110, "hp": 140, "atk": 20,  "atk_speed": 1.0, "range": 5.0, "armor_rate": 0.0,  "ability": "slow"},
	"otter":      {"cost": 80,  "hp": 160, "atk": 10,  "atk_speed": 1.5, "range": 3.0, "armor_rate": 0.10, "ability": "slow"},
	"peacock":    {"cost": 90,  "hp": 120, "atk": 15,  "atk_speed": 0.8, "range": 3.5, "armor_rate": 0.0,  "ability": ""},
	"chameleon":  {"cost": 80,  "hp": 120, "atk": 12,  "atk_speed": 1.8, "range": 2.0, "armor_rate": 0.0,  "ability": "poison"},
	"honey_badger":{"cost": 110,"hp": 250, "atk": 35,  "atk_speed": 1.2, "range": 1.5, "armor_rate": 0.25, "ability": "armor_break"},
	"pangolin":   {"cost": 160, "hp": 350, "atk": 40,  "atk_speed": 0.7, "range": 1.5, "armor_rate": 0.45, "ability": "armor_break"},
}

const SKILL_TREE_DB: Dictionary = {
	"cheetah": [
		{"id": "cheetah_A",  "label": "攻速+15%",         "cost": 40, "prereq": "",          "mutex": ""},
		{"id": "cheetah_B1", "label": "暴击率20% 伤害×2",  "cost": 60, "prereq": "cheetah_A", "mutex": "cheetah_B2"},
		{"id": "cheetah_B2", "label": "命中30%概率减速2秒", "cost": 60, "prereq": "cheetah_A", "mutex": "cheetah_B1"},
	],
	"elephant": [
		{"id": "elephant_A",  "label": "攻击范围+1格",    "cost": 50, "prereq": "",           "mutex": ""},
		{"id": "elephant_B1", "label": "攻击附加恐惧2秒",  "cost": 80, "prereq": "elephant_A", "mutex": "elephant_B2"},
		{"id": "elephant_B2", "label": "踩踏群体减速",    "cost": 80, "prereq": "elephant_A", "mutex": "elephant_B1"},
	],
	"wolf_pack": [
		{"id": "wolf_A",  "label": "攻击力+20%",           "cost": 60, "prereq": "",       "mutex": ""},
		{"id": "wolf_B1", "label": "攻速+20%",             "cost": 80, "prereq": "wolf_A", "mutex": "wolf_B2"},
		{"id": "wolf_B2", "label": "群殴：33%触发+50%伤害", "cost": 80, "prereq": "wolf_A", "mutex": "wolf_B1"},
	],
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
# 协同 buff：{ buff_id -> {speed_mult, atk_mult} }（持续整局，无 duration）
var _synergy_buffs: Dictionary = {}
# 协同护甲加成
var _synergy_armor_bonus: float = 0.0
# 协同特殊标记
var synergy_stun_chance: float = 0.0
var synergy_on_hit_slow: bool = false

# 技能树
var unlocked_skills: Array[String] = []
var _skill_crit_chance: float = 0.0
var _skill_slow_on_hit_chance: float = 0.0
var _skill_trample_fear: bool = false
var _skill_trample_aoe_slow: bool = false
var _skill_wolf_rampage_chance: float = 0.0

# 道具装备（1槽位）
var equipped_item: String = ""
var _item_atk_bonus: float = 0.0
var _item_speed_bonus: float = 0.0
var _item_crit_chance: float = 0.0
var _item_crit_mult_bonus: float = 0.0
var _item_pierce_rate: float = 0.0
var _item_on_hit_poison: bool = false
var _item_on_hit_slow: bool = false
var _item_on_hit_armor_break: bool = false

# 升级
const MAX_LEVEL := 3
var level: int = 1

var _sprite: Sprite2D

signal tower_destroyed(tower: Tower)



func _draw() -> void:
	# 等级角标（右上角小圆点）
	if level > 1:
		var half := Constants.TILE_SIZE * 0.5 - 6.0
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
	_add_sprite()


func _add_sprite() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/art/towers/%s.png" % animal_id)
	var s := float(Constants.TILE_SIZE) / 256.0
	_sprite.scale = Vector2(s, s)
	add_child(_sprite)


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
	_update_sprite_modulate()
	queue_redraw()


func _update_sprite_modulate() -> void:
	if _sprite == null:
		return
	match level:
		2: _sprite.modulate = Color(0.75, 0.75, 0.75)
		3: _sprite.modulate = Color(0.55, 0.55, 0.55)
		_: _sprite.modulate = Color.WHITE


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


func apply_synergy_buff(buff_id: String, speed_mult: float, atk_mult: float) -> void:
	_synergy_buffs[buff_id] = {"speed_mult": speed_mult, "atk_mult": atk_mult}


func apply_synergy_armor(buff_id: String, bonus: float) -> void:
	_synergy_armor_bonus += bonus


func equip_item(item_id: String) -> bool:
	if equipped_item != "":
		return false  # 槽位已满
	var item: Dictionary = ItemDB.get_item(item_id)
	if item.is_empty():
		return false
	equipped_item = item_id
	_apply_item_effects(item)
	return true


func _apply_item_effects(item: Dictionary) -> void:
	for effect in item.get("effects", []):
		var t: String = effect.get("type", "")
		var v: float  = float(effect.get("value", 0))
		match t:
			"base_atk":         _item_atk_bonus += v
			"atk_speed":        _item_speed_bonus += v
			"hp":               max_hp += v; hp += v
			"armor_rate":       armor_rate = minf(armor_rate + v, 0.9)
			"range":            _range_px += v * Constants.TILE_SIZE
			"crit_chance":      _item_crit_chance = minf(_item_crit_chance + v, 0.75)
			"crit_mult":        _item_crit_mult_bonus += v
			"pierce_rate":      _item_pierce_rate = minf(_item_pierce_rate + v, 1.0)
			"on_hit_poison":    _item_on_hit_poison = true
			"on_hit_slow":      _item_on_hit_slow = true
			"on_hit_armor_break": _item_on_hit_armor_break = true


func clear_synergy_buffs() -> void:
	_synergy_buffs.clear()
	_synergy_armor_bonus = 0.0
	synergy_stun_chance = 0.0
	synergy_on_hit_slow = false


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
	var eff_speed := (_atk_speed + _item_speed_bonus) * (1.0 + aura_bonus)
	var eff_atk := _atk + _item_atk_bonus
	for buff in _buffs.values():
		eff_speed *= buff.get("speed_mult", 1.0)
		eff_atk   *= buff.get("atk_mult",   1.0)
	for sbuff in _synergy_buffs.values():
		eff_speed *= sbuff.get("speed_mult", 1.0)
		eff_atk   *= sbuff.get("atk_mult",   1.0)
	_attack_timer = 1.0 / maxf(eff_speed, 0.1)
	var eff_pierce := minf(_item_pierce_rate, 1.0)
	var eff_armor := clampf(_current_target._armor_rate * (1.0 - eff_pierce) - _synergy_armor_bonus, 0.0, 1.0)
	var final_dmg := eff_atk * (1.0 - eff_armor)
	var crit_chance := maxf(_skill_crit_chance, _item_crit_chance)
	if crit_chance > 0.0 and randf() < crit_chance:
		var crit_mult := 2.0 + _item_crit_mult_bonus
		final_dmg *= crit_mult
	if _skill_wolf_rampage_chance > 0.0 and randf() < _skill_wolf_rampage_chance:
		final_dmg *= 1.5
	_current_target.take_damage(final_dmg)
	_apply_on_hit_effect()


func _apply_on_hit_effect() -> void:
	if not is_instance_valid(_current_target):
		return
	var ability: String = _data.get("ability", "")
	match ability:
		"slow":
			_current_target.apply_status("slow", Constants.SLOW_DURATION)
		"fear":
			_current_target.apply_status("fear", Constants.FEAR_DURATION)
		"stun":
			if randf() < 0.15:
				_current_target.apply_status("stun", Constants.PETRIFY_DURATION)
		"poison":
			_current_target.apply_status("poison", 5.0)
		"armor_break":
			_current_target.apply_status("armor_break", Constants.ARMOR_BREAK_DURATION)
	# 道具命中效果
	if _item_on_hit_poison:
		_current_target.apply_status("poison", 5.0)
	if _item_on_hit_slow:
		_current_target.apply_status("slow", 2.0)
	if _item_on_hit_armor_break:
		_current_target.apply_status("armor_break", Constants.ARMOR_BREAK_DURATION)
	# 协同特殊效果
	if synergy_stun_chance > 0.0 and randf() < synergy_stun_chance:
		_current_target.apply_status("stun", 0.5)
	if synergy_on_hit_slow:
		_current_target.apply_status("slow", 2.0)
	if _skill_slow_on_hit_chance > 0.0 and randf() < _skill_slow_on_hit_chance:
		_current_target.apply_status("slow", 2.0)
	if _skill_trample_fear:
		_current_target.apply_status("fear", 2.0)
	if _skill_trample_aoe_slow:
		var hit_pos := _current_target.position
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.position.distance_to(hit_pos) < Constants.TILE_SIZE * 2.0:
				e.apply_status("slow", 2.0)


func unlock_skill(node_id: String) -> void:
	if node_id in unlocked_skills:
		return
	unlocked_skills.append(node_id)
	_apply_skill_effect(node_id)
	queue_redraw()


func _apply_skill_effect(node_id: String) -> void:
	match node_id:
		"cheetah_A":  _atk_speed *= 1.15
		"cheetah_B1": _skill_crit_chance = 0.20
		"cheetah_B2": _skill_slow_on_hit_chance = 0.30
		"elephant_A": _range_px += Constants.TILE_SIZE
		"elephant_B1": _skill_trample_fear = true
		"elephant_B2": _skill_trample_aoe_slow = true
		"wolf_A":  _atk *= 1.20
		"wolf_B1": _atk_speed *= 1.20
		"wolf_B2": _skill_wolf_rampage_chance = 0.33


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




func _on_destroyed() -> void:
	GridManager.grid.vacate(grid_cell.x, grid_cell.y)
	GridManager.obstacle_changed.emit()
	tower_destroyed.emit(self)
	queue_free()
