extends Label
class_name DamageLabel
# ---------------------------------------------------------------------------
# DamageLabel — 伤害/金币飘字
# GDD：vfx.md  公式：-2px/frame 上移，48帧消失，alpha 从第24帧开始淡出
# 用法：DamageLabel.spawn(text, color, world_pos, parent_node)
# ---------------------------------------------------------------------------

const TOTAL_FRAMES := 48
const FADE_START_FRAME := 24
const RISE_PX_PER_FRAME := 2.0

var _frame: int = 0


func init(text: String, color: Color, world_pos: Vector2) -> void:
	self.text = text
	add_theme_color_override("font_color", color)
	add_theme_font_size_override("font_size", 18)
	position = world_pos + Vector2(-16.0, -32.0)
	z_index = 10


func _process(_delta: float) -> void:
	_frame += 1
	position.y -= RISE_PX_PER_FRAME
	if _frame >= FADE_START_FRAME:
		var alpha := 1.0 - float(_frame - FADE_START_FRAME) / float(TOTAL_FRAMES - FADE_START_FRAME)
		modulate.a = clampf(alpha, 0.0, 1.0)
	if _frame >= TOTAL_FRAMES:
		queue_free()
