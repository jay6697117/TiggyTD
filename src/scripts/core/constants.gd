# ---------------------------------------------------------------------------
# Constants — 全局常量
# 所有系统通过 preload 或 const 引用本文件
# ---------------------------------------------------------------------------
class_name Constants

# 碰撞层（对应 project.godot layer_names）
const LAYER_HERO        := 1  # bit 0
const LAYER_ENEMIES     := 2  # bit 1
const LAYER_TOWERS      := 4  # bit 2
const LAYER_PROJECTILES := 8  # bit 3
const LAYER_PATH        := 16 # bit 4
const LAYER_BUILD_GRID  := 32 # bit 5

# 地图
const TILE_SIZE         := 64       # 像素/格
const MAP_WIDTH         := 20       # 格
const MAP_HEIGHT        := 15       # 格

# 经济
const STARTING_GOLD     := 150
const BASE_HP_MAX       := 10
const SHOP_REFRESH_COST := 30

# 波次
const TOTAL_WAVES       := 10
const SHOP_WAVES        := [3, 6, 9]  # 这些波次后触发商店

# 英雄技能 CD（秒）
const CD_APEX_ROAR      := 30.0
const CD_NATURES_CALL   := 45.0
const CD_ERA_JUDGEMENT  := 120.0

# 英雄光环
const HERO_AURA_RADIUS  := 3.0   # 格
const HERO_AURA_BONUS   := 0.20  # +20% 攻速

# 状态效果默认值
const SLOW_FACTOR       := 0.50  # 速度乘数
const SLOW_DURATION     := 3.0
const PETRIFY_DURATION  := 1.5
const FEAR_DURATION     := 3.0
const POISON_DPS        := 10.0
const POISON_MAX_STACKS := 3
const ARMOR_BREAK_FACTOR:= 0.50  # 护甲乘数
const ARMOR_BREAK_DURATION := 5.0

# 背包
const INVENTORY_MAX_SLOTS := 6

# Boss
const BOSS_SHIELD_THRESHOLD := 0.50  # HP%
const BOSS_SHIELD_DURATION  := 8.0

# VFX
const MAX_DEATH_VFX_PER_FRAME := 10

# EXP
const EXP_NORMAL_ENEMY  := 5
const EXP_ELITE_ENEMY   := 15
const EXP_BOSS          := 50
const EXP_LEVEL_THRESHOLDS := [50, 120, 250]  # 1→2, 2→3, 3→4 级所需 EXP
