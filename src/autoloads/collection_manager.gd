extends Node

# ---------------------------------------------------------------------------
# CollectionManager — 图鉴收集系统
# GDD: collection.md
# 监听动物放置/敌人击杀事件，首次解锁时写存档并给予印记奖励
# ---------------------------------------------------------------------------

const UNLOCK_REWARD := 3


func on_animal_placed(animal_id: String) -> void:
	_check_unlock(animal_id)


func on_enemy_killed(enemy_id: String) -> void:
	_check_unlock(enemy_id)


func on_item_acquired(item_id: String) -> void:
	var col: Dictionary = SaveLoad.get_value("collection", {"unlocked_entries": [], "unlock_dates": {}, "seen_items": []})
	var seen: Array = col.get("seen_items", [])
	if item_id in seen:
		return
	seen.append(item_id)
	col["seen_items"] = seen
	SaveLoad.set_value("collection", col)
	SaveLoad.save_game()
	_show_toast(item_id)


func _check_unlock(entry_id: String) -> void:
	var col: Dictionary = SaveLoad.get_value("collection", {"unlocked_entries": [], "unlock_dates": {}})
	var entries: Array = col.get("unlocked_entries", [])
	if entry_id in entries:
		return
	entries.append(entry_id)
	var dates: Dictionary = col.get("unlock_dates", {})
	dates[entry_id] = Time.get_date_string_from_system()
	col["unlocked_entries"] = entries
	col["unlock_dates"] = dates
	SaveLoad.set_value("collection", col)
	SaveLoad.save_game()
	GameState.add_ancient_marks(UNLOCK_REWARD)
	_show_toast(entry_id)


func _show_toast(entry_id: String) -> void:
	var toast := CanvasLayer.new()
	toast.layer = 120
	var lbl := Label.new()
	lbl.text = Localization.L("ui.collection_toast", [entry_id])
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	lbl.set_anchor_and_offset(SIDE_LEFT,   0.0, 0.0)
	lbl.set_anchor_and_offset(SIDE_RIGHT,  1.0, 0.0)
	lbl.set_anchor_and_offset(SIDE_TOP,    0.85, 0.0)
	lbl.set_anchor_and_offset(SIDE_BOTTOM, 0.95, 0.0)
	toast.add_child(lbl)
	get_tree().root.add_child(toast)
	var timer := get_tree().create_timer(2.0)
	timer.timeout.connect(toast.queue_free)
