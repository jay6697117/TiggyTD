extends Node
# ---------------------------------------------------------------------------
# SynergyManager — 协同效果系统 autoload
# GDD：synergy.md
# 依赖：Tower（group "towers"），hud（group "hud"）
# ---------------------------------------------------------------------------

# 协同定义表
# animals: { animal_id: min_count }  — 每种动物需要的最少数量
# targets: 受益动物列表（空=所有参与动物）
const SYNERGY_DEFS: Array = [
	{
		"id": "hyena_trio",
		"name": "狂野猎手",
		"animals": {"wolf_pack": 3},
		"targets": ["wolf_pack"],
		"speed_mult": 1.30,
	},
	{
		"id": "turtle_wall",
		"name": "铁壁防线",
		"animals": {"pangolin": 2},
		"targets": ["pangolin"],
		"armor_bonus": 0.15,
	},
	{
		"id": "cheetah_pack",
		"name": "闪电突袭",
		"animals": {"cheetah": 2},
		"targets": ["cheetah"],
		"stun_chance": 0.10,
	},
	{
		"id": "elephant_herd",
		"name": "地动山摇",
		"animals": {"elephant": 2},
		"targets": ["elephant"],
		"on_hit_slow": true,
	},
	{
		"id": "predator_mix",
		"name": "丛林法则",
		"animals": {"cheetah": 1, "wolf_pack": 1, "tiger": 1},
		"targets": ["cheetah", "wolf_pack", "tiger"],
		"atk_mult": 1.15,
	},
	{
		"id": "tank_duo",
		"name": "钢铁意志",
		"animals": {"pangolin": 1, "elephant": 1},
		"targets": ["pangolin", "elephant"],
		"armor_bonus": 0.10,
	},
]

# 当前激活状态 { synergy_id → bool }
var _active: Dictionary = {}


func recalculate() -> void:
	var towers := get_tree().get_nodes_in_group("towers")

	# 统计各动物数量
	var counts: Dictionary = {}
	for t in towers:
		var aid: String = t.animal_id
		counts[aid] = counts.get(aid, 0) + 1

	# 清除所有协同 buff（后续重新施加激活的）
	for t in towers:
		t.clear_synergy_buffs()

	for syn in SYNERGY_DEFS:
		var now_active := _check_condition(syn["animals"], counts)
		var was_active: bool = _active.get(syn["id"], false)
		_active[syn["id"]] = now_active

		if now_active:
			_apply_synergy(syn, towers)
			if not was_active:
				get_tree().call_group("hud", "show_synergy_banner", Localization.L("synergy.activated", [Localization.L("synergy." + syn["id"] + ".name")]))


func _check_condition(required: Dictionary, counts: Dictionary) -> bool:
	for animal_id in required:
		if counts.get(animal_id, 0) < required[animal_id]:
			return false
	return true


func _apply_synergy(syn: Dictionary, towers: Array) -> void:
	var targets: Array = syn["targets"]
	for t in towers:
		if t.animal_id not in targets:
			continue
		if syn.has("speed_mult"):
			t.apply_synergy_buff(syn["id"] + "_spd", syn["speed_mult"], 1.0)
		if syn.has("atk_mult"):
			t.apply_synergy_buff(syn["id"] + "_atk", 1.0, syn["atk_mult"])
		if syn.has("armor_bonus"):
			t.apply_synergy_armor(syn["id"] + "_arm", syn["armor_bonus"])
		if syn.has("stun_chance"):
			t.synergy_stun_chance += syn["stun_chance"]
		if syn.has("on_hit_slow"):
			t.synergy_on_hit_slow = true


func get_active_synergies() -> Array:
	var result: Array = []
	for syn in SYNERGY_DEFS:
		result.append({"name": syn["name"], "active": _active.get(syn["id"], false)})
	return result
