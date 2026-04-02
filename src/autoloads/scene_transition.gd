extends CanvasLayer

# ---------------------------------------------------------------------------
# SceneTransition — 转场动画单例
# 提供黑色淡入淡出效果，用于场景切换时的过渡动画
# ---------------------------------------------------------------------------

const FADE_DURATION := 0.5

var _color_rect: ColorRect
var _tween: Tween


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_color_rect = ColorRect.new()
	_color_rect.color = Color(0, 0, 0, 0)
	_color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_color_rect)


# 淡出到黑屏（场景切换前调用）
func fade_to_black(duration: float = FADE_DURATION) -> void:
	_kill_tween()
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_tween = create_tween()
	_tween.tween_property(_color_rect, "color:a", 1.0, duration)
	await _tween.finished


# 从黑屏淡入（场景切换后调用）
func fade_from_black(duration: float = FADE_DURATION) -> void:
	_kill_tween()
	_color_rect.color.a = 1.0
	_tween = create_tween()
	_tween.tween_property(_color_rect, "color:a", 0.0, duration)
	_tween.tween_callback(func(): _color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE)
	await _tween.finished


# 便捷方法：淡出 → 执行回调 → 淡入
func transition(callback: Callable, duration: float = FADE_DURATION) -> void:
	await fade_to_black(duration)
	callback.call()
	await fade_from_black(duration)


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
