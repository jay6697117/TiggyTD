# ---------------------------------------------------------------------------
# CollisionLayers — 碰撞层/掩码常量
# GDD：collision.md
# 与 project.godot [layer_names] 保持同步
# ---------------------------------------------------------------------------
class_name CollisionLayers

# 物理层 bit 值
const HERO        := 1   # layer 1
const ENEMIES     := 2   # layer 2
const TOWERS      := 4   # layer 3
const PROJECTILES := 8   # layer 4
const PATH        := 16  # layer 5
const BUILD_GRID  := 32  # layer 6

# 翼龙专用（使用 ENEMIES 层的高位，通过 metadata 区分地面/飞行）
# MVP 阶段：翼龙与地面敌人同层，由 can_target_air 属性控制塔的攻击资格
# Alpha 阶段如需严格分层再拆分

# 常用碰撞掩码组合
## 英雄：检测地形（BUILD_GRID 边界）
const MASK_HERO       := BUILD_GRID

## 地面敌人：检测路径区域
const MASK_ENEMY_GROUND := PATH

## 投射物：检测所有敌人
const MASK_PROJECTILE := ENEMIES

## 塔攻击范围查询：检测敌人
const MASK_TOWER_ATTACK := ENEMIES

## 光环范围查询：检测塔
const MASK_AURA := TOWERS
