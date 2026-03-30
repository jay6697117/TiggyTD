extends Node

# ---------------------------------------------------------------------------
# ItemDB — 道具数据库
# GDD: item-database.md
# 静态只读；运行时通过 ItemDB.get_item(id) 查询
# ---------------------------------------------------------------------------

const ITEMS: Dictionary = {
	# ── 基础道具：攻击向（10种）──────────────────────────────────────────────
	"sharp_claw": {
		"name": "利爪", "tier": 1, "price": 40, "shop_weight": 10, "recipe": [],
		"effects": [{"type": "base_atk", "value": 10}]
	},
	"poison_fang": {
		"name": "毒牙", "tier": 1, "price": 50, "shop_weight": 8, "recipe": [],
		"effects": [{"type": "on_hit_poison", "dps": 5.0, "duration": 3.0}]
	},
	"piercing_horn": {
		"name": "穿刺角", "tier": 1, "price": 45, "shop_weight": 8, "recipe": [],
		"effects": [{"type": "pierce_rate", "value": 0.15}]
	},
	"swift_feather": {
		"name": "疾风羽", "tier": 1, "price": 40, "shop_weight": 10, "recipe": [],
		"effects": [{"type": "atk_speed", "value": 0.3}]
	},
	"rage_crystal": {
		"name": "狂暴晶石", "tier": 1, "price": 45, "shop_weight": 9, "recipe": [],
		"effects": [{"type": "crit_rate", "value": 0.10}]
	},
	"blood_gem": {
		"name": "嗜血宝石", "tier": 1, "price": 50, "shop_weight": 8, "recipe": [],
		"effects": [{"type": "crit_mult", "value": 0.3}]
	},
	"hunter_mark": {
		"name": "猎手印记", "tier": 1, "price": 60, "shop_weight": 6, "recipe": [],
		"effects": [{"type": "on_hit_mark", "bonus_dmg": 0.15}]
	},
	"chain_strike": {
		"name": "连锁爪", "tier": 1, "price": 55, "shop_weight": 7, "recipe": [],
		"effects": [{"type": "on_hit_chain", "chance": 0.20, "dmg_ratio": 0.50}]
	},
	"aoe_roar": {
		"name": "咆哮石", "tier": 1, "price": 65, "shop_weight": 5, "recipe": [],
		"effects": [{"type": "aoe_attack", "radius": 1.0}]
	},
	"armor_break": {
		"name": "碎甲石", "tier": 1, "price": 55, "shop_weight": 7, "recipe": [],
		"effects": [{"type": "on_hit_armor_break", "value": 0.10, "duration": 5.0}]
	},
	# ── 基础道具：防御向（6种）──────────────────────────────────────────────
	"iron_shell": {
		"name": "铁壳", "tier": 1, "price": 35, "shop_weight": 10, "recipe": [],
		"effects": [{"type": "hp", "value": 100}]
	},
	"thorn_bark": {
		"name": "荆棘皮", "tier": 1, "price": 45, "shop_weight": 7, "recipe": [],
		"effects": [{"type": "thorns", "ratio": 0.10}]
	},
	"regen_moss": {
		"name": "生机苔", "tier": 1, "price": 40, "shop_weight": 8, "recipe": [],
		"effects": [{"type": "regen", "hp": 20, "interval": 5.0}]
	},
	"shield_scale": {
		"name": "盾甲鳞", "tier": 1, "price": 45, "shop_weight": 8, "recipe": [],
		"effects": [{"type": "armor_rate", "value": 0.10}]
	},
	"last_stand": {
		"name": "绝地反击", "tier": 1, "price": 60, "shop_weight": 6, "recipe": [],
		"effects": [{"type": "last_stand", "threshold": 0.30, "atk_bonus": 0.30}]
	},
	"taunt_gem": {
		"name": "嘲讽宝石", "tier": 1, "price": 50, "shop_weight": 6, "recipe": [],
		"effects": [{"type": "taunt", "radius": 3.0}]
	},
	# ── 基础道具：辅助向（6种）──────────────────────────────────────────────
	"aura_stone": {
		"name": "光环石", "tier": 1, "price": 45, "shop_weight": 8, "recipe": [],
		"effects": [{"type": "ally_aura", "radius": 2.0, "atk_bonus": 0.08}]
	},
	"slow_mud": {
		"name": "减速泥", "tier": 1, "price": 40, "shop_weight": 9, "recipe": [],
		"effects": [{"type": "on_hit_slow", "ratio": 0.20, "duration": 2.0}]
	},
	"gold_tooth": {
		"name": "金牙", "tier": 1, "price": 50, "shop_weight": 7, "recipe": [],
		"effects": [{"type": "on_kill_gold", "value": 2}]
	},
	"range_scope": {
		"name": "远望镜", "tier": 1, "price": 45, "shop_weight": 8, "recipe": [],
		"effects": [{"type": "range", "value": 1.5}]
	},
	"quick_feet": {
		"name": "疾步符", "tier": 1, "price": 30, "shop_weight": 9, "recipe": [],
		"effects": [{"type": "move_speed", "value": 1.0}]
	},
	"cooldown_gem": {
		"name": "冷却宝石", "tier": 1, "price": 55, "shop_weight": 7, "recipe": [],
		"effects": [{"type": "cooldown_reduction", "value": 0.15}]
	},
	# ── 基础道具：特殊向（3种）──────────────────────────────────────────────
	"echo_stone": {
		"name": "回响石", "tier": 1, "price": 70, "shop_weight": 5, "recipe": [],
		"effects": [{"type": "on_hit_double", "chance": 0.10}]
	},
	"soul_link": {
		"name": "灵魂链接", "tier": 1, "price": 80, "shop_weight": 3, "recipe": [],
		"effects": [{"type": "soul_link", "radius": 1.0}]
	},
	"wild_instinct": {
		"name": "野性本能", "tier": 1, "price": 65, "shop_weight": 5, "recipe": [],
		"effects": [{"type": "wild_instinct", "buffs_per_wave": 1}]
	},
	# ── 合成道具（15种，tier=2，shop_weight=0）────────────────────────────────
	"death_fang": {
		"name": "死亡之牙", "tier": 2, "price": 0, "shop_weight": 0,
		"recipe": ["sharp_claw", "poison_fang"],
		"effects": [{"type": "base_atk", "value": 15}, {"type": "on_hit_poison", "dps": 10.0, "duration": 5.0}]
	},
	"soul_piercer": {
		"name": "灵魂穿刺", "tier": 2, "price": 0, "shop_weight": 0,
		"recipe": ["piercing_horn", "piercing_horn"],
		"effects": [{"type": "pierce_rate", "value": 0.40}, {"type": "on_hit_ignore_armor", "chance": 0.15}]
	},
	"berserker_heart": {
		"name": "狂战士之心", "tier": 2, "price": 0, "shop_weight": 0,
		"recipe": ["rage_crystal", "blood_gem"],
		"effects": [{"type": "crit_rate", "value": 0.20}, {"type": "crit_mult", "value": 0.8}, {"type": "on_crit_regen", "hp": 5}]
	},
	"apex_claw": {
		"name": "顶点利爪", "tier": 2, "price": 0, "shop_weight": 0,
		"recipe": ["sharp_claw", "rage_crystal"],
		"effects": [{"type": "base_atk", "value": 20}, {"type": "crit_rate", "value": 0.15}, {"type": "on_crit_atk_stack", "bonus": 5, "max_stacks": 3}]
	},
	"storm_strike": {
		"name": "风暴连击", "tier": 2, "price": 0, "shop_weight": 0,
		"recipe": ["swift_feather", "chain_strike"],
		"effects": [{"type": "atk_speed", "value": 0.5}, {"type": "on_hit_chain", "chance": 0.50, "dmg_ratio": 0.80}]
	},
	"titan_shell": {
		"name": "泰坦甲壳", "tier": 2, "price": 0, "shop_weight": 0,
		"recipe": ["iron_shell", "shield_scale"],
		"effects": [{"type": "hp", "value": 200}, {"type": "armor_rate", "value": 0.20}, {"type": "on_hit_block", "chance": 0.10}]
	},
	"blood_thorn": {
		"name": "嗜血荆棘", "tier": 2, "price": 0, "shop_weight": 0,
		"recipe": ["thorn_bark", "blood_gem"],
		"effects": [{"type": "thorns", "ratio": 0.25}, {"type": "thorns_crit", "value": true}]
	},
	"phoenix_moss": {
		"name": "凤凰苔藓", "tier": 2, "price": 0, "shop_weight": 0,
		"recipe": ["regen_moss", "last_stand"],
		"effects": [{"type": "regen", "hp": 30, "interval": 5.0}, {"type": "last_stand", "threshold": 0.30, "atk_bonus": 0.50}, {"type": "last_stand_regen_mult", "value": 2.0}]
	},
	"war_aura": {
		"name": "战争光环", "tier": 2, "price": 0, "shop_weight": 0,
		"recipe": ["aura_stone", "aura_stone"],
		"effects": [{"type": "ally_aura", "radius": 3.0, "atk_bonus": 0.20}, {"type": "ally_aura_atk_speed", "radius": 3.0, "value": 0.10}]
	},
	"plague_fang": {
		"name": "瘟疫之牙", "tier": 2, "price": 0, "shop_weight": 0,
		"recipe": ["poison_fang", "slow_mud"],
		"effects": [{"type": "on_hit_poison", "dps": 5.0, "duration": 3.0}, {"type": "on_hit_slow", "ratio": 0.30, "duration": 3.0}, {"type": "plague_spread", "radius": 1.0}]
	},
	"fortress_mark": {
		"name": "要塞印记", "tier": 2, "price": 0, "shop_weight": 0,
		"recipe": ["hunter_mark", "taunt_gem"],
		"effects": [{"type": "on_hit_mark", "bonus_dmg": 0.25}, {"type": "taunt", "radius": 3.0}]
	},
	"infinity_echo": {
		"name": "无限回响", "tier": 2, "price": 0, "shop_weight": 0,
		"recipe": ["echo_stone", "echo_stone"],
		"effects": [{"type": "on_hit_double", "chance": 0.35}, {"type": "on_hit_triple", "chance": 0.10}]
	},
	"gold_empire": {
		"name": "黄金帝国", "tier": 2, "price": 0, "shop_weight": 0,
		"recipe": ["gold_tooth", "gold_tooth"],
		"effects": [{"type": "on_kill_gold", "value": 5}, {"type": "passive_gold", "value": 3, "interval": 10.0}]
	},
	"sniper_scope": {
		"name": "狙击镜", "tier": 2, "price": 0, "shop_weight": 0,
		"recipe": ["range_scope", "hunter_mark"],
		"effects": [{"type": "range", "value": 3.0}, {"type": "long_range_dmg", "bonus": 0.40}]
	},
	"primal_instinct": {
		"name": "原始本能", "tier": 2, "price": 0, "shop_weight": 0,
		"recipe": ["wild_instinct", "cooldown_gem"],
		"effects": [{"type": "wild_instinct", "buffs_per_wave": 2}, {"type": "cooldown_reduction", "value": 0.25}]
	},
}


func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})


func get_shop_pool() -> Array:
	var pool: Array = []
	for id in ITEMS:
		if ITEMS[id]["shop_weight"] > 0:
			pool.append(id)
	return pool


func get_all_ids() -> Array:
	return ITEMS.keys()


func get_crafting_recipes() -> Array:
	var recipes: Array = []
	for id in ITEMS:
		if ITEMS[id]["tier"] == 2:
			var mats: Array = ITEMS[id]["recipe"]
			recipes.append({"result": id, "mat_a": mats[0] if mats.size() > 0 else "", "mat_b": mats[1] if mats.size() > 1 else mats[0] if mats.size() > 0 else ""})
	return recipes
