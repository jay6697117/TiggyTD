# 状态效果系统

> **状态**: 已完成
> **作者**: 开发者 + Claude
> **最后更新**: 2026-03-27

---

## Overview（概述）

状态效果系统管理游戏中所有临时状态的施加、持续计时、叠加规则和移除。状态效果分为两类：施加在敌人身上的负面效果（减速、恐惧、石化、中毒）和施加在动物塔/英雄身上的正面效果（buff，由英雄技能和光环产生）。系统提供统一的 apply_effect / remove_effect / tick 接口，供其他系统调用，自身不主动触发任何效果。

---

## Player Fantasy（玩家幻想）

状态效果是Build深度的可见化。看到全场敌人中毒变绿、减速变蓝、石化变灰——这些视觉反馈直接传递「我的阵型有效」的满足感。恐惧让猛犸象掉头乱跑的瞬间是「反制成功」的惊喜时刻。Build设计感来自于：哪些动物组合能触发石化+中毒+减速三重压制，是玩家探索的乐趣核心。

---

## Detailed Design（详细设计）

### 状态效果列表

#### 负面效果（施加在敌人）

| 效果ID | 名称 | 来源 | 效果 | 持续时间 | 叠加规则 |
|--------|------|------|------|---------|----------|
| `slow` | 减速 | 树懒、乌龟 | move_speed × 0.5 | 3秒 | 刷新计时，不叠加强度 |
| `fear` | 恐惧 | 鬣狗 | 敌人反向逃跑3秒 | 3秒 | 刷新计时 |
| `stun` | 石化 | 蛇（毒液触发） | 完全停止移动和攻击 | 1.5秒 | 刷新计时 |
| `poison` | 中毒 | 蛇 | 每秒造成10点真实伤害 | 5秒 | 可叠加最多3层（最多30DPS） |
| `armor_break` | 破甲 | 犀牛冲撞 | armor_reduction × 0.5 | 5秒 | 不叠加，刷新计时 |

#### 正面效果（施加在塔/英雄）

| 效果ID | 名称 | 来源 | 效果 | 持续时间 | 叠加规则 |
|--------|------|------|------|---------|----------|
| `apex_roar` | 怒吼激励 | 英雄Q技能 | atk_speed × 1.5 | 8秒 | 刷新计时，不叠加强度 |
| `natures_call` | 自然激励 | 英雄W技能 | base_atk × 1.3 | 10秒 | 刷新计时 |
| `hero_aura` | 英雄光环 | 英雄被动 | atk_speed × 1.2 | 持续（英雄在范围内） | 不叠加（只有一个英雄） |

### 数据结构

```
StatusEffect {
  effect_id: string          // 效果唯一标识
  source_unit_id: int        // 施加者ID
  target_unit_id: int        // 承受者ID
  duration_remaining: float  // 剩余持续时间（秒）
  stack_count: int           // 当前叠加层数（默认1）
  is_permanent: bool         // true=持续型（如hero_aura），不计时
}
```

### 核心接口

```
// 施加效果
apply_effect(target, effect_id, source, duration, stacks=1):
  existing = find_effect(target, effect_id)
  if existing:
    if effect允许叠加 and existing.stack_count < max_stacks:
      existing.stack_count += 1
      existing.duration_remaining = duration  // 同时刷新计时
    else:
      existing.duration_remaining = duration  // 仅刷新计时
  else:
    创建新 StatusEffect 并加入 target.active_effects
    立即应用效果到目标属性

// 每帧更新
tick(delta):
  for each active_effect in all_units:
    if effect.is_permanent: continue
    effect.duration_remaining -= delta
    if effect.duration_remaining <= 0:
      remove_effect(target, effect_id)
    if effect_id == "poison":
      target.hp -= 10 × effect.stack_count × delta  // 每秒伤害

// 移除效果
remove_effect(target, effect_id):
  找到并删除 target.active_effects 中对应效果
  还原被修改的目标属性
```

### 属性修改方式

```
效果施加时：直接修改目标运行时属性（非base值）
  slow:       target.current_move_speed = target.base_move_speed × 0.5
  fear:       target.ai_state = FEAR; target.fear_direction = reverse
  stun:       target.can_move = false; target.can_attack = false
  armor_break: target.current_armor = target.base_armor × 0.5
  apex_roar:  target.current_atk_speed = target.base_atk_speed × 1.5
  natures_call: target.current_atk = target.base_atk × 1.3
  hero_aura:  target.current_atk_speed = target.base_atk_speed × 1.2

效果移除时：还原为 base 值（或重新计算其他仍生效的效果）
```

### 多效果共存时的属性计算

```
敌人同时受slow和stun：
  stun期间 can_move=false，stun结束后slow仍生效（move_speed×0.5）

塔同时受apex_roar和hero_aura：
  current_atk_speed = base_atk_speed × 1.5 × 1.2 = base × 1.8
  （乘法叠加，在apply_effect时重新计算final值）

敌人受3层poison：
  每帧伤害 = 10 × 3 × delta
```

---

## Formulas（公式）

**减速效果**
```
current_move_speed = base_move_speed × 0.5
示例：迅猛龙 base_move_speed=3.0 → 减速后=1.5
```

**中毒伤害（每秒）**
```
poison_dps = 10 × stack_count
最大叠加层数=3，最大DPS=30
总伤害（5秒）= 10 × stack_count × 5
示例：3层中毒 → 5秒内共造成150点真实伤害
```

**破甲后伤害计算（与伤害计算系统联动）**
```
破甲后：target.current_armor = base_armor × 0.5
代入伤害公式：effective_dmg = raw_dmg × (1 - current_armor/100)
示例：腕龙 base_armor=40% → 破甲后armor=20%
  猎豹攻击50点 → 破甲前实际35点，破甲后实际40点
```

**buff乘法叠加**
```
final_atk_speed = base_atk_speed × ∏(各buff倍率)
示例：hero_aura(×1.2) + apex_roar(×1.5) → base × 1.8
```

---

## Edge Cases（边界情况）

| 情况 | 处理方式 |
|------|----------|
| 石化期间敌人受到减速 | 减速效果正常施加并计时；石化结束后减速立即生效（移动速度×0.5） |
| 恐惧期间敌人到达地图边缘 | 敌人在边界停止，不穿越地图边界；恐惧计时继续，结束后恢复正常AI |
| 减速快到期时再次被命中 | 刷新为完整3秒，不叠加为6秒 |
| 中毒目标在毒伤tick前死亡 | 死亡事件优先，不再tick中毒伤害 |
| 塔在apex_roar生效期间被出售 | 塔实例销毁时自动清除所有active_effects，不影响其他塔 |
| 恐惧的敌人反向跑回起点是否给玩家造成伤害 | 否，只有敌人正向到达终点才扣HP；恐惧结束后恢复正常寻路 |
| 多个蛇同时对同一目标施加中毒 | 叠加层数+1（上限3层），同时刷新持续时间为5秒 |
| hero_aura在塔上与apex_roar同时生效 | 属性重新计算：base × 1.2 × 1.5，移除任一buff后重算 |

---

## Dependencies（依赖关系）

### 上游依赖

| 系统 | 使用内容 |
|------|----------|
| 动物塔攻击系统 | 命中后调用 apply_effect 施加减速/石化/中毒/破甲 |
| 英雄技能系统 | 调用 apply_effect 施加 apex_roar / natures_call |
| 英雄光环系统 | 调用 apply_effect / remove_effect 管理 hero_aura |
| 伤害计算系统 | 破甲状态修改 current_armor，伤害计算读取该值 |

### 下游依赖

| 系统 | 使用内容 | 状态 |
|------|---------|------|
| 敌人AI系统 | 恐惧状态修改 ai_state，石化修改 can_move | ✅ 已完成 |
| 游戏UI系统 | 显示状态效果图标、持续时间、层数 | ⬜ 未设计 |

---

## Tuning Knobs（调节旋钮）

| 旋钮 | 当前值 | 安全范围 | 影响的游戏体验 |
|------|--------|---------|---------------|
| 减速强度 | ×0.5 | ×0.3~×0.7 | 越低减速越强，过强会让敌人几乎静止 |
| 减速持续时间 | 3秒 | 2~5秒 | 越长覆盖更多攻击轮次 |
| 石化持续时间 | 1.5秒 | 1~3秒 | 超过3秒对Boss级敌人过于强力 |
| 中毒DPS | 10/层 | 5~20/层 | 越高真实伤害比重越大，克制高护甲敌人 |
| 中毒最大层数 | 3层 | 2~5层 | 越多多蛇协同价值越高 |
| 恐惧持续时间 | 3秒 | 2~4秒 | 超过4秒恐惧接近无效化敌人 |
| 破甲幅度 | armor×0.5 | armor×0.3~×0.7 | 越低破甲越强，影响高护甲敌人可杀性 |

---

## Acceptance Criteria（验收标准）

| # | 标准 | 验证方法 |
|---|------|----------|
| AC-1 | 减速使敌人移动速度降低50% | 迅猛龙正常速度3.0，被树懒命中后速度变为1.5，3秒后恢复 |
| AC-2 | 减速重复命中刷新计时不叠加强度 | 敌人被减速2秒后再次命中，确认还剩3秒（而非5秒），速度仍×0.5 |
| AC-3 | 石化使敌人完全停止移动和攻击1.5秒 | 腕龙被蛇石化，确认1.5秒内完全静止，之后恢复移动 |
| AC-4 | 中毒每秒10点真实伤害，最多3层 | 3条蛇同时命中同一敌人，确认每秒扣30点HP，第4条蛇命中不增加伤害 |
| AC-5 | 恐惧使敌人反向移动3秒 | 鬣狗命中迅猛龙，确认迅猛龙反向跑3秒后恢复正常寻路方向 |
| AC-6 | 恐惧敌人到达地图边界时停止不穿越 | 恐惧的敌人跑到地图边缘，确认停在边界不消失也不穿越 |
| AC-7 | 破甲使目标护甲减半 | 腕龙armor=40%，犀牛冲撞后armor=20%，5秒后恢复40% |
| AC-8 | hero_aura与apex_roar乘法叠加为×1.8 | 猎豹在光环内触发怒吼，确认攻速=base×1.8（非+0.7叠加） |