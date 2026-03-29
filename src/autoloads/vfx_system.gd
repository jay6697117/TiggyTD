extends Node

# ---------------------------------------------------------------------------
# VFXSystem — 特效/视觉反馈系统单例
# GDD：vfx.md
# ---------------------------------------------------------------------------

# VFX 效果注册表：effect_id -> 场景路径
const VFX_REGISTRY: Dictionary = {
	"hit_normal":          "res://scenes/entities/vfx/hit_normal.tscn",
	"hit_crit":            "res://scenes/entities/vfx/hit_crit.tscn",
	"hit_aoe":             "res://scenes/entities/vfx/hit_aoe.tscn",
	"status_slow":         "res://scenes/entities/vfx/status_slow.tscn",
	"status_petrify":      "res://scenes/entities/vfx/status_petrify.tscn",
	"status_poison":       "res://scenes/entities/vfx/status_poison.tscn",
	"status_fear":         "res://scenes/entities/vfx/status_fear.tscn",
	"status_armor_break":  "res://scenes/entities/vfx/status_armor_break.tscn",
	"skill_apex_roar":     "res://scenes/entities/vfx/skill_apex_roar.tscn",
	"skill_natures_call":  "res://scenes/entities/vfx/skill_natures_call.tscn",
	"skill_era_judgement": "res://scenes/entities/vfx/skill_era_judgement.tscn",
	"hero_aura":           "res://scenes/entities/vfx/hero_aura.tscn",
	"synergy_activate":    "res://scenes/entities/vfx/synergy_activate.tscn",
	"base_damage":         "res://scenes/entities/vfx/base_damage.tscn",
	"victory":             "res://scenes/entities/vfx/victory.tscn",
	"defeat":              "res://scenes/entities/vfx/defeat.tscn",
	"boss_spawn":          "res://scenes/entities/vfx/boss_spawn.tscn",
	"damage_number":       "res://scenes/entities/vfx/damage_number.tscn",
}

# 当前帧活跃特效数（用于并发上限控制）
var _active_death_vfx_this_frame: int = 0
var _screen_shake_tween: Tween

# 挂载点（游戏主场景初始化后设置）
var _vfx_layer: Node2D


func _process(_delta: float) -> void:
	_active_death_vfx_this_frame = 0


func set_vfx_layer(layer: Node2D) -> void:
	_vfx_layer = layer


# 纯代码实现的特效（无需 .tscn 文件）
const _CODE_VFX: Array = ["victory", "defeat", "base_damage"]


# 播放一次性特效
func play(effect_id: String, position: Vector2, parent: Node2D = null) -> void:
	if effect_id in _CODE_VFX:
		_play_code_vfx(effect_id, position, parent)
		return
	var path: String = VFX_REGISTRY.get(effect_id, "")
	if path.is_empty():
		push_warning("VFXSystem: unknown effect_id '%s'" % effect_id)
		return
	if not ResourceLoader.exists(path):
		push_warning("VFXSystem: missing scene %s" % path)
		return
	var scene: PackedScene = load(path)
	var instance := scene.instantiate()
	var target_parent := parent if parent else _vfx_layer
	if target_parent == null:
		push_warning("VFXSystem: no vfx_layer set")
		instance.queue_free()
		return
	target_parent.add_child(instance)
	instance.global_position = position


# 播放浮动伤害数字
func play_damage_number(position: Vector2, amount: int, is_crit: bool = false) -> void:
	play("damage_number", position)
	# damage_number 场景内部读取 amount 和 is_crit 参数
	# 通过 set_deferred 或 call_deferred 设置（场景实例化后）


# 屏幕震动
func screen_shake(intensity: float, duration: float, camera: Camera2D) -> void:
	if camera == null:
		return
	if _screen_shake_tween and _screen_shake_tween.is_valid():
		_screen_shake_tween.kill()
	var origin := camera.offset
	_screen_shake_tween = create_tween()
	_screen_shake_tween.set_loops(int(duration / 0.05))
	_screen_shake_tween.tween_callback(func():
		var t := randf_range(-intensity, intensity)
		camera.offset = Vector2(t, t)
	)
	_screen_shake_tween.tween_callback(func():
		camera.offset = origin
	).set_delay(duration)


func _play_code_vfx(effect_id: String, position: Vector2, parent: Node2D = null) -> void:
	var target := parent if parent else _vfx_layer
	if target == null:
		return
	match effect_id:
		"victory":
			_vfx_burst(target, position, Color(1.0, 0.9, 0.1), 24, 120.0)
			_vfx_burst(target, Vector2(320, 240), Color(0.2, 1.0, 0.4), 16, 100.0)
			_vfx_burst(target, Vector2(960, 240), Color(0.2, 0.6, 1.0), 16, 100.0)
		"defeat":
			_vfx_burst(target, position, Color(1.0, 0.2, 0.1), 20, 90.0)
		"base_damage":
			_vfx_burst(target, position, Color(1.0, 0.4, 0.0), 8, 60.0)


func _vfx_burst(parent: Node2D, origin: Vector2, color: Color, count: int, speed: float) -> void:
	for i in count:
		var p := ColorRect.new()
		p.size = Vector2(6, 6)
		p.color = color
		p.position = origin - Vector2(3, 3)
		p.z_index = 20
		parent.add_child(p)
		var angle := TAU * i / count
		var vel := Vector2(cos(angle), sin(angle)) * randf_range(speed * 0.6, speed)
		var dur := randf_range(0.4, 0.8)
		var tw := p.create_tween()
		tw.tween_property(p, "position", p.position + vel * dur, dur)
		tw.parallel().tween_property(p, "modulate:a", 0.0, dur)
		tw.tween_callback(p.queue_free)


# 死亡特效并发控制（最多10个/帧）
func play_death_vfx(position: Vector2) -> void:
	_active_death_vfx_this_frame += 1
	if _active_death_vfx_this_frame > 10 and randf() < 0.5:
		return  # 随机跳过50%
	play("hit_normal", position)
