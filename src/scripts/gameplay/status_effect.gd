class_name StatusEffect extends RefCounted
# ---------------------------------------------------------------------------
# StatusEffect — 状态效果数据对象（轻量 RefCounted，无场景树开销）
# GDD：status-effects.md
# ---------------------------------------------------------------------------

var effect_id: String = ""
var duration_remaining: float = 0.0
var stack_count: int = 1
var is_permanent: bool = false
var _poison_tick_timer: float = 0.0


func init(id: String, duration: float, stacks: int = 1, permanent: bool = false) -> StatusEffect:
	effect_id = id
	duration_remaining = duration
	stack_count = stacks
	is_permanent = permanent
	return self
