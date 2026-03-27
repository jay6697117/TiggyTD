# Godot 4.4 → 4.6 Breaking Changes 参考

> **用途**: 所有代码建议必须对照本文档，避免使用已废弃或行为已变更的 API。
> **来源**: 官方 migration guides + release notes（2026-03-27 验证）

---

## Godot 4.4 Breaking Changes

### UID 系统（Universal UID）
```
变更：大量文件类型现在使用 UID 引用（.tscn, .tres, .gd 等）
影响：从 4.3 迁移时需运行 UID 升级工具
行动：新项目直接用 4.4+，无需处理
```

### SceneTree 内部重构
```
变更：节点处理顺序内部实现改变（性能优化）
影响：依赖节点处理顺序边界情况的代码可能行为不同
行动：不要依赖同帧内兄弟节点的特定处理顺序
```

### .NET 最低版本升至 .NET 8
```
影响：TiggyTD 使用 GDScript，不受影响
```

### CSG 实现替换
```
影响：TiggyTD 不使用 CSG，不受影响
```

### GDScript：typed Dictionary
```gdscript
# 4.4+ 支持类型化字典
var data: Dictionary[String, int] = {}
# 旧写法仍有效但不推荐
var data: Dictionary = {}
```

### FileAccess 返回类型变更
```gdscript
# 4.4 前：get_var() 在失败时行为不一致
# 4.4 后：更严格的返回类型，失败返回 null
var file = FileAccess.open(path, FileAccess.READ)
if file == null:
    push_error("无法打开文件: " + path)
    return
```

---

## Godot 4.5 Breaking Changes

### NavigationServer2D 独立化 ⚠️ 重要
```gdscript
# 4.5 前：NavigationServer2D 内部依赖 3D 服务器
# 4.5 后：完全独立
# 行动：直接使用 NavigationAgent2D，API 不变，但性能更好

# TiggyTD 正确用法：
var agent: NavigationAgent2D  # 挂载在敌人节点上
agent.target_position = base_position
var next_pos = agent.get_next_path_position()  # 每帧调用
```

### duplicate() 深拷贝语义变更 ⚠️ 重要
```gdscript
# 4.5 前：duplicate() 在某些情况下自动深拷贝
# 4.5 后：必须显式传 true 参数才深拷贝

# 错误写法（可能导致数据共享 bug）：
var copy = original_dict.duplicate()

# 正确写法（深拷贝）：
var copy = original_dict.duplicate(true)

# TiggyTD 涉及场景：
# - StatusEffect 数据结构复制
# - TowerSkillState 复制
# - 存档数据读取后的副本
```

### TileMapLayer 碰撞：Chunk-based ⚠️ 重要
```gdscript
# 4.5 后：碰撞在 tile 数据编辑器中定义，运行时按 chunk 生成
# 禁止：运行时逐格设置碰撞
# 正确：在 TileSet 资源中为每种 tile 类型配置碰撞形状

# 获取格子类型（用于判断 PATH / BUILD / BLOCKED）：
var source_id = tilemap.get_cell_source_id(Vector2i(x, y))
# source_id == -1 表示空格
```

### 可变参数（variadic args）
```gdscript
# 4.5 新增 variadic 函数支持
func my_func(arg1: int, args: Array) -> void:
    pass  # 旧写法仍有效

# 新写法（4.5+）：
func my_func(arg1: int, ...args) -> void:
    pass
```

### @abstract 注解
```gdscript
# 4.5 新增，TiggyTD 可用于定义抽象基类
@abstract
class_name BaseEnemy
extends CharacterBody2D

@abstract
func get_exp_reward() -> int:
    pass  # 子类必须实现
```

---

## Godot 4.6 Breaking Changes

### Jolt Physics 成为 3D 默认 ⚠️ 注意
```
变更：Jolt 现为 3D 项目默认物理后端
影响：TiggyTD 是 2D 项目，使用 Godot Physics 2D，不受影响
确认：项目设置中 physics/2d/default_gravity 等保持不变
```

### Glow 在 Tonemapping 之前应用
```
变更：发光效果渲染顺序改变
影响：TiggyTD 使用 Compatibility 渲染器（无 HDR），不受影响
```

### Windows 默认渲染器改为 Direct3D 12
```
变更：Windows 上 Forward+ 项目默认用 D3D12
影响：TiggyTD 使用 Compatibility/OpenGL，不受影响
行动：项目设置确认 rendering/renderer/rendering_method = "gl_compatibility"
```

### Unique Node IDs
```gdscript
# 4.6 新增：每个节点有唯一运行时 ID（独立于 name）
# 可通过 node.get_instance_id() 获取
# TiggyTD 用途：tower_id、enemy_id 可使用此值而非手动分配
var tower_id: int = tower_node.get_instance_id()
```

### 信号不得以下划线开头 ⚠️ 重要
```gdscript
# 错误写法（4.6 中信号以 _ 开头会被隐藏）：
signal _enemy_died
signal _tower_placed

# 正确写法：
signal enemy_died
signal tower_placed
signal wave_started(wave_number: int)
```

---

## TiggyTD 特定风险矩阵

| 系统 | 相关 breaking change | 风险 | 行动 |
|------|---------------------|------|------|
| 寻路系统 | 4.5 NavigationServer2D 独立化 | LOW | 使用 NavigationAgent2D，API 相同 |
| 存档系统 | 4.4 FileAccess 返回类型 / 4.5 duplicate() | MEDIUM | 始终检查 null，深拷贝用 duplicate(true) |
| 关卡/地图系统 | 4.5 TileMapLayer chunk 碰撞 | MEDIUM | 在 TileSet 中配置碰撞，不在运行时设置 |
| 状态效果系统 | 4.5 duplicate() 语义 | MEDIUM | StatusEffect 数据结构复制时用 duplicate(true) |
| 所有信号 | 4.6 下划线前缀隐藏 | HIGH | 所有 signal 使用 snake_case 无前缀 |
| 渲染/VFX | 4.6 Jolt/D3D12/Glow 变更 | LOW | 使用 Compatibility 渲染器规避所有变更 |
| 英雄技能树 | 4.6 Unique Node IDs | POSITIVE | 可用 get_instance_id() 作为 tower_id |
