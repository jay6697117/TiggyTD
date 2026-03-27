extends Node

# ---------------------------------------------------------------------------
# SaveLoad — 存档/读档系统单例
# GDD：save-load.md
# ---------------------------------------------------------------------------

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 1

var _data: Dictionary = {}


func _ready() -> void:
	load_game()


func save_game() -> void:
	_data["save_version"] = SAVE_VERSION
	_data["timestamp"] = Time.get_unix_time_from_system()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveLoad: cannot write to %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(_data, "\t"))
	file.close()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_init_default_save()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveLoad: cannot read %s" % SAVE_PATH)
		_init_default_save()
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("SaveLoad: JSON parse error")
		_init_default_save()
		return
	_data = json.data
	_migrate_if_needed()


func get_value(key: String, default_value: Variant = null) -> Variant:
	return _data.get(key, default_value)


func set_value(key: String, value: Variant) -> void:
	_data[key] = value


func _init_default_save() -> void:
	_data = {
		"save_version": SAVE_VERSION,
		"settings": {
			"language_code": "zh-CN",
			"audio": {
				"master_volume": 80,
				"sfx_volume": 80,
				"bgm_volume": 60
			}
		},
		"meta_progression": {
			"ancient_marks": 0,
			"total_marks_earned": 0,
			"unlocked_nodes": []
		},
		"collection": {
			"unlocked_entries": [],
			"unlock_dates": {}
		},
		"level_progress": [
			{"level_id": "ancient_savanna", "status": "UNLOCKED", "best_result": {"waves_survived": 0, "base_hp_remaining": -1}},
			{"level_id": "lava_canyon", "status": "LOCKED", "best_result": {"waves_survived": 0, "base_hp_remaining": -1}},
			{"level_id": "frozen_tundra", "status": "LOCKED", "best_result": {"waves_survived": 0, "base_hp_remaining": -1}}
		],
		"tutorial": {
			"tutorial_completed": false,
			"current_step": 0
		}
	}


func _migrate_if_needed() -> void:
	var version: int = _data.get("save_version", 0)
	if version < SAVE_VERSION:
		# 未来版本迁移逻辑写在这里
		_data["save_version"] = SAVE_VERSION
		save_game()
