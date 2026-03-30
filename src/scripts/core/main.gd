extends Node2D

# ---------------------------------------------------------------------------
# Main — 游戏主场景根节点
# 负责：初始化各系统引用、连接全局信号
# ---------------------------------------------------------------------------

@onready var camera: Camera2D              = $Camera2D
@onready var vfx_layer: Node2D             = $VFXLayer
@onready var map_renderer: Node2D          = $MapRenderer
@onready var wave_manager: Node            = $WaveManager
@onready var tower_placement: Node         = $TowerPlacementManager
@onready var towers_node: Node2D           = $Entities/Towers
@onready var enemies_node: Node2D          = $Entities/Enemies


func _ready() -> void:
	VFXSystem.set_vfx_layer(vfx_layer)
	wave_manager.setup(enemies_node)
	tower_placement.setup(towers_node)
	_connect_signals()
	# 主菜单
	var menu := CanvasLayer.new()
	menu.set_script(load("res://scripts/ui/main_menu.gd"))
	add_child(menu)
	# 道具商店
	var item_shop := CanvasLayer.new()
	item_shop.set_script(load("res://scripts/ui/item_shop_panel.gd"))
	add_child(item_shop)
	# 背包面板
	var inv_panel := CanvasLayer.new()
	inv_panel.set_script(load("res://scripts/ui/inventory_panel.gd"))
	add_child(inv_panel)
	GameState.change_state(GameState.State.MAIN_MENU)


func _connect_signals() -> void:
	GameState.state_changed.connect(_on_state_changed)
	GameState.base_hp_changed.connect(_on_base_hp_changed)
	map_renderer.cell_clicked.connect(tower_placement.on_cell_clicked)
	tower_placement.tower_focused.connect(func(t): get_tree().call_group("hud", "show_skill_tree", t))
	tower_placement.placement_failed.connect(func(reason): get_tree().call_group("hud", "show_toast", reason))


var _tutorial_launched: bool = false


func _on_state_changed(new_state: GameState.State) -> void:
	match new_state:
		GameState.State.BUILD:
			if not _tutorial_launched:
				_tutorial_launched = true
				var tutorial_done: bool = SaveLoad.get_value("tutorial", {}).get("tutorial_completed", false)
				if not tutorial_done:
					var overlay := CanvasLayer.new()
					overlay.set_script(load("res://scripts/ui/tutorial_overlay.gd"))
					add_child(overlay)
		GameState.State.WIN:
			AudioSystem.play_bgm("victory")
			VFXSystem.play("victory", Vector2(640, 480))
		GameState.State.LOSE:
			AudioSystem.play_bgm("defeat")
			VFXSystem.play("defeat", Vector2(640, 480))


func _on_base_hp_changed(_new_hp: int) -> void:
	AudioSystem.play_sfx("base_damage")
	VFXSystem.screen_shake(5.0, 0.3, camera)
	VFXSystem.play("base_damage", Vector2(640, 480))


# 启动下一波（可由 UI 按钮调用）
func start_next_wave() -> void:
	if GameState.current_state == GameState.State.BUILD:
		GameState.change_state(GameState.State.WAVE)
