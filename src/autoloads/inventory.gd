extends Node

# ---------------------------------------------------------------------------
# Inventory — 玩家背包（局内）
# GDD: item-equipment.md
# 容量6格，存储道具ID列表；reset_run 时清空
# ---------------------------------------------------------------------------

const CAPACITY := 6

# 当前背包内容：Array of String（item_id）
var _items: Array = []

signal item_added(item_id: String)
signal item_removed(item_id: String, index: int)
signal inventory_changed


func _ready() -> void:
	GameState.state_changed.connect(_on_state_changed)


func _on_state_changed(new_state: GameState.State) -> void:
	if new_state == GameState.State.BUILD and GameState.current_wave == 0:
		clear()


# ── 公开接口 ────────────────────────────────────────────────────────────────

func add_item(item_id: String) -> bool:
	if _items.size() >= CAPACITY:
		return false
	if not ItemDB.get_item(item_id):
		return false
	_items.append(item_id)
	item_added.emit(item_id)
	inventory_changed.emit()
	return true


func remove_item_at(index: int) -> String:
	if index < 0 or index >= _items.size():
		return ""
	var item_id: String = _items[index]
	_items.remove_at(index)
	item_removed.emit(item_id, index)
	inventory_changed.emit()
	return item_id


func remove_item(item_id: String) -> bool:
	var idx := _items.find(item_id)
	if idx == -1:
		return false
	remove_item_at(idx)
	return true


func has_item(item_id: String) -> bool:
	return item_id in _items


func count_item(item_id: String) -> int:
	var n := 0
	for id in _items:
		if id == item_id:
			n += 1
	return n


func is_full() -> bool:
	return _items.size() >= CAPACITY


func free_slots() -> int:
	return CAPACITY - _items.size()


func get_items() -> Array:
	return _items.duplicate()


func clear() -> void:
	_items.clear()
	inventory_changed.emit()
