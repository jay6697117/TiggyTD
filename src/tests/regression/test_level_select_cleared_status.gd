extends SceneTree

const LEVEL_SELECT_SCRIPT := "res://scripts/ui/level_select_panel.gd"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var exit_code: int = await _run_test()
	quit(exit_code)


func _run_test() -> int:
	_seed_progress()

	var panel := CanvasLayer.new()
	panel.set_script(load(LEVEL_SELECT_SCRIPT))
	root.add_child(panel)
	await _wait_frames(2)

	var frozen_button: Button = _get_level_button(panel, 3)
	if frozen_button == null:
		return _fail("Frozen tundra button was not created")
	if frozen_button.disabled:
		return _fail("CLEARED level should remain enterable")
	if frozen_button.text != _localization().L("ui.enter"):
		return _fail("CLEARED level should show the enter action")

	return _pass("CLEARED levels stay enterable in level select")


func _seed_progress() -> void:
	var save_load := _save_load()
	save_load.set_value("level_progress", [
		{"level_id": "ancient_savanna", "status": "UNLOCKED", "best_result": {"waves_survived": 0, "base_hp_remaining": -1}},
		{"level_id": "lava_canyon", "status": "UNLOCKED", "best_result": {"waves_survived": 0, "base_hp_remaining": -1}},
		{"level_id": "frozen_tundra", "status": "CLEARED", "best_result": {"waves_survived": 10, "base_hp_remaining": 10}},
	])
	save_load.set_value("meta_progression", {
		"ancient_marks": 0,
		"total_marks_earned": 0,
		"unlocked_nodes": [],
	})


func _get_level_button(panel: CanvasLayer, card_index: int) -> Button:
	var panel_container: PanelContainer = panel.get_child(1) as PanelContainer
	var vbox: VBoxContainer = panel_container.get_child(0) as VBoxContainer
	var card: PanelContainer = vbox.get_child(card_index) as PanelContainer
	var hbox: HBoxContainer = card.get_child(0) as HBoxContainer
	return hbox.get_child(1) as Button


func _wait_frames(count: int) -> void:
	for _i in count:
		await process_frame


func _save_load() -> Node:
	return root.get_node("SaveLoad")


func _localization() -> Node:
	return root.get_node("Localization")


func _fail(message: String) -> int:
	printerr("TEST FAILED: %s" % message)
	return 1


func _pass(message: String) -> int:
	print("TEST PASSED: %s" % message)
	return 0
