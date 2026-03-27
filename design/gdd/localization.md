# 本地化系统

> **状态**: 已完成
> **作者**: 开发者 + Claude
> **最后更新**: 2026-03-27

---

## Overview（概述）

本地化系统提供中文简体（zh-CN）和英文美国（en-US）两种语言支持。所有游戏内显示文本通过字符串键（key）引用，实际文本内容存储在对应语言的本地化文件中。系统在游戏启动时加载对应语言的文件，运行时通过 `L(key)` 函数获取文本。切换语言需要重启游戏（MVP阶段不支持运行时热切换）。

---

## Player Fantasy（玩家幻想）

本地化是「让游戏被更多玩家看见」的基础工程。对中文玩家，母语界面是基本体验保障；对英文玩家，完整翻译是进入国际市场的入场券。本系统的价值不在于游戏感，而在于确保设计意图能准确传达给不同语言的玩家——每个技能描述、每个状态效果提示都需要清晰准确。

---

## Detailed Design（详细设计）

### 文件结构

```
assets/
  localization/
    zh-CN.json    // 中文简体（默认）
    en-US.json    // 英文美国
```

### 文件格式

```json
// zh-CN.json 示例
{
  "ui.base_hp": "基地HP",
  "ui.gold": "金币",
  "ui.wave": "波次",
  "skill.apex_roar.name": "百兽怒吼",
  "skill.apex_roar.desc": "全场动物塔攻速提升50%，持续8秒。冷却：30秒",
  "skill.natures_call.name": "自然之召",
  "skill.natures_call.desc": "英雄周围5格内动物塔攻击+30%，持续12秒。冷却：45秒",
  "skill.era_judgement.name": "纪元审判",
  "skill.era_judgement.desc": "对单个目标造成300点真实伤害，可打破护盾。冷却：120秒",
  "animal.cheetah.name": "猎豹",
  "animal.turtle.name": "乌龟",
  "enemy.raptor.name": "迅猛龙",
  "enemy.mosasaurus_rex.name": "沧龙霸主",
  "synergy.hyena_trio.name": "狂野猎手",
  "synergy.hyena_trio.desc": "3只鬣狗：所有鬣狗攻速+30%",
  "status.slow.name": "减速",
  "status.petrify.name": "石化",
  "boss.spawn_alert": "沧龙霸主降临！",
  "ui.victory": "胜利！",
  "ui.defeat": "失败",
  "shop.refresh_cost": "刷新（30金币）",
  "craft.confirm": "消耗 {0} + {1}，合成 {2}？",
  "error.insufficient_gold": "金币不足",
  "error.inventory_full": "背包已满"
}
```

### 运行时接口

```
// 初始化（游戏启动时）
Localization.load(language_code)  // "zh-CN" 或 "en-US"

// 获取文本
L(key) → string
  示例：L("ui.base_hp") → "基地HP"（zh-CN）或 "Base HP"（en-US）

// 带参数的文本（{0}占位符替换）
L("craft.confirm", material_a, material_b, result)
  → "消耗 攻速鼓 + 时间沙漏，合成 永恒节拍器？"

// 语言回退规则
若 key 在当前语言文件中不存在：
  1. 回退到 zh-CN（默认语言）
  2. 若 zh-CN 也不存在：显示 key 本身（便于发现缺失翻译）
```

### 语言选择

```
语言设置入口：主菜单「设置」→「语言」
MVP 支持语言：zh-CN（默认）、en-US
切换后：显示提示「请重启游戏以应用语言更改」
语言偏好存储在存档系统（settings.language_code）
```

### Key 命名规范

```
格式：{分类}.{子分类}.{名称}
分类：ui / skill / animal / enemy / item / synergy / status / error / boss / shop / craft
示例：
  ui.base_hp
  skill.apex_roar.name
  skill.apex_roar.desc
  animal.cheetah.name
  item.attack_drum.name
  item.attack_drum.desc
  error.inventory_full
```

---

## Formulas（公式）

**Key 总数估算**
```
UI文本：~30个key
技能（3个×2）：6个key
动物（12个×2）：24个key
敌人（10个×2）：20个key
道具（20个×2）：40个key
协同（6个×2）：12个key
状态效果（5个×2）：10个key
系统提示/错误：~20个key
总计：约160~200个key
```

---

## Edge Cases（边界情况）

| 情况 | 处理方式 |
|------|----------|
| Key不存在于当前语言 | 回退zh-CN，若仍不存在显示key本身（如"item.unknown_item.name"） |
| 占位符数量与参数不匹配 | 多余占位符保持{N}原样，缺少参数显示空字符串 |
| 语言文件JSON格式错误 | 启动时捕获解析错误，强制使用zh-CN，写入错误日志 |
| 中文字体与英文字体渲染差异 | 为zh-CN和en-US分别指定字体文件（中文需要支持CJK的像素字体） |

---

## Dependencies（依赖关系）

### 上游依赖

| 系统 | 使用内容 |
|------|----------|
| 存档/读档系统 | 读取 settings.language_code 决定启动语言 |

### 下游依赖

所有显示文本的系统均调用 `L(key)` 接口，包括：游戏UI系统、商店系统、道具合成系统、英雄技能系统、协同效果系统等。本地化系统是所有UI文本的基础依赖。

---

## Tuning Knobs（调节旋钮）

| 旋钮 | 当前值 | 安全范围 | 影响的游戏体验 |
|------|--------|---------|---------------|
| 支持语言数量 | 2（zh-CN, en-US） | 2~5种 | 每增加一种语言需维护对应翻译文件 |
| 语言切换方式 | 重启生效 | — | 若改为热切换需要所有UI组件监听语言变更事件 |

---

## Acceptance Criteria（验收标准）

| # | 标准 | 验证方法 |
|---|------|----------|
| AC-1 | 默认语言为中文简体，所有UI文本显示中文 | 首次启动游戏，确认所有界面文字为中文 |
| AC-2 | 切换至英文后重启，所有UI文本变为英文 | 设置切换en-US重启，确认「基地HP」变为「Base HP」 |
| AC-3 | 缺失key时显示key本身而非崩溃 | 在zh-CN.json中删除一个key，确认对应位置显示key字符串 |
| AC-4 | 带参数文本正确替换占位符 | 合成确认弹窗正确显示材料名和结果名 |
| AC-5 | 语言偏好在重启后保持 | 切换为en-US后重启，确认仍为英文界面 |