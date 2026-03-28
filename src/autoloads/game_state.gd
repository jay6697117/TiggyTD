extends Node

# ---------------------------------------------------------------------------
# GameState — 全局游戏状态单例
# 依赖：无
# 被依赖：几乎所有系统
# ---------------------------------------------------------------------------

enum State { MAIN_MENU, BUILD, WAVE, SHOP, WIN, LOSE, PAUSED }

# 当前游戏状态
var current_state: State = State.MAIN_MENU

# 资源/货币
var gold: int = 150
var ancient_marks: int = 0

# 基地
var base_hp: int = 10
var base_hp_max: int = 10

# 波次
var current_wave: int = 0
var total_waves: int = 10

# 击杀统计
var kills_this_run: int = 0
var enemies_leaked: int = 0

# 信号
signal state_changed(new_state: State)
signal gold_changed(new_amount: int)
signal base_hp_changed(new_hp: int)
signal wave_changed(new_wave: int)
signal ancient_marks_changed(new_amount: int)


func change_state(new_state: State) -> void:
	current_state = new_state
	state_changed.emit(new_state)


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true


func add_ancient_marks(amount: int) -> void:
	ancient_marks += amount
	ancient_marks_changed.emit(ancient_marks)


func spend_ancient_marks(amount: int) -> bool:
	if ancient_marks < amount:
		return false
	ancient_marks -= amount
	ancient_marks_changed.emit(ancient_marks)
	return true


func damage_base(amount: int) -> void:
	base_hp = max(0, base_hp - amount)
	base_hp_changed.emit(base_hp)
	if base_hp <= 0:
		change_state(State.LOSE)


func reset_run() -> void:
	gold = 150
	base_hp = base_hp_max
	current_wave = 0
	kills_this_run = 0
	enemies_leaked = 0
	ancient_marks = 0
	change_state(State.BUILD)


# 仅重置数值，不发信号（reload_current_scene 前调用）
func reset_run_data() -> void:
	gold = 150
	base_hp = base_hp_max
	current_wave = 0
	kills_this_run = 0
	enemies_leaked = 0
	ancient_marks = 0
	current_state = State.BUILD
