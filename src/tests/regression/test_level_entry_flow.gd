extends SceneTree

const MAIN_SCENE := "res://scenes/game/main.tscn"
const MAIN_MENU_SCRIPT := "res://scripts/ui/main_menu.gd"
const LEVEL_SELECT_SCRIPT := "res://scripts/ui/level_select_panel.gd"
const STATE_MAIN_MENU := 0
const STATE_BUILD := 1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var exit_code := await _run_test()
	quit(exit_code)


func _run_test() -> int:
	_seed_default_progress()
	var game_state := _game_state()
	game_state.current_level_id = "ancient_savanna"
	game_state.current_state = STATE_MAIN_MENU

	var err := change_scene_to_file(MAIN_SCENE)
	if err != OK:
		return _fail("Unable to load main scene: %s" % err)

	await _wait_frames(3)

	var menu := _find_node_by_script(current_scene, MAIN_MENU_SCRIPT)
	if menu == null:
		return _fail("Main menu was not created")

	menu.call("_on_start_pressed")
	await _wait_frames(1)

	var level_select := _find_node_by_script(root, LEVEL_SELECT_SCRIPT)
	if level_select == null:
		return _fail("Level select panel did not open")

	level_select.call("_on_level_selected", "lava_canyon")
	await _wait_frames(4)

	if game_state.current_state != STATE_BUILD:
		return _fail("Expected BUILD after entering a level, got %s" % game_state.current_state)
	if game_state.current_level_id != "lava_canyon":
		return _fail("Expected selected level to persist after reload")

	var reloaded_menu := _find_node_by_script(current_scene, MAIN_MENU_SCRIPT)
	if reloaded_menu == null:
		return _fail("Main menu missing after scene reload")
	if reloaded_menu.visible:
		return _fail("Main menu should be hidden after entering a level")

	var lingering_panel := _find_node_by_script(root, LEVEL_SELECT_SCRIPT)
	if lingering_panel != null:
		return _fail("Level select panel should not survive the scene reload")

	var grid_manager := _grid_manager()
	if grid_manager.grid.waypoints[0] != Vector2i(0, 1):
		return _fail("Expected lava_canyon grid layout after reload")

	return _pass("Level entry flow reached BUILD without leaving menu overlays behind")


func _seed_default_progress() -> void:
	var save_load := _save_load()
	save_load.set_value("level_progress", [
		{"level_id": "ancient_savanna", "status": "UNLOCKED", "best_result": {"waves_survived": 0, "base_hp_remaining": -1}},
		{"level_id": "lava_canyon", "status": "UNLOCKED", "best_result": {"waves_survived": 0, "base_hp_remaining": -1}},
		{"level_id": "frozen_tundra", "status": "LOCKED", "best_result": {"waves_survived": 0, "base_hp_remaining": -1}},
	])
	save_load.set_value("meta_progression", {
		"ancient_marks": 0,
		"total_marks_earned": 0,
		"unlocked_nodes": [],
	})


func _wait_frames(count: int) -> void:
	for _i in count:
		await process_frame


func _find_node_by_script(node: Node, script_path: String) -> Node:
	if node == null:
		return null
	var script: Script = node.get_script() as Script
	if script != null and script.resource_path == script_path:
		return node
	for child in node.get_children():
		var found: Node = _find_node_by_script(child, script_path)
		if found != null:
			return found
	return null


func _game_state() -> Node:
	return root.get_node("GameState")


func _save_load() -> Node:
	return root.get_node("SaveLoad")


func _grid_manager() -> Node:
	return root.get_node("GridManager")


func _fail(message: String) -> int:
	printerr("TEST FAILED: %s" % message)
	return 1


func _pass(message: String) -> int:
	print("TEST PASSED: %s" % message)
	return 0
