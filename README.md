# TiggyTD

> 操控万兽之王老虎，率领现代生物军团，用 Build 自由与策略深度抵御史前巨兽的纪元入侵。

**类型**：Roguelite 塔防 + 实时英雄操控
**视觉风格**：日系卡通 + 高清唯美像素
**目标平台**：PC (Steam) + Steam Deck
**引擎**：Godot 4.6 / GDScript
**开发规模**：独立开发，目标商业发行

---

## 核心玩法

- **图腾指挥英雄**：实时操控老虎在战场移动，触发全局光环和三大技能（百兽怒吼 / 自然之召 / 纪元审判）
- **动物塔 Build 系统**：12只动物塔，独立技能树（2级分支）+ 道具装备 + 道具合成
- **协同效果**：特定动物组合触发协同加成，Build 深度的最高层表达
- **史前入侵者**：具有特殊行为的史前生物（推塔、石化、恐惧），Boss 有护盾阶段机制
- **Roguelite 循环**：每3波商店 → 购买/合成道具 → 跨局古代印记 → 图腾神殿永久解锁

---

## 开发阶段

| 阶段 | 目标 | 状态 |
|------|------|------|
| **MVP** | 一张地图、12种动物、10波+Boss、能赢能输的可运行原型 | 🔧 开发中 |
| **Vertical Slice** | 一局完整体验，含 Build 深度、特效和商店 | ⬜ 未开始 |
| **Alpha** | 完整游戏内容，3关卡、图鉴收集、跨局成长、新手引导 | ⬜ 未开始 |
| **Steam 发行** | 商业发行版本 | ⬜ 未开始 |

---

## 系统设计文档（GDD）

34个系统已完整设计，每个文档含：Overview、Player Fantasy、Detailed Rules、Formulas、Edge Cases、Dependencies、Tuning Knobs、Acceptance Criteria。

→ [`design/gdd/systems-index.md`](design/gdd/systems-index.md)

---

## 项目结构

```
TiggyTD/
├── src/                  # Godot 项目源码
│   ├── autoloads/        # 全局单例（GameState, AudioSystem 等）
│   ├── scenes/           # 场景文件
│   │   ├── game/         # 核心游戏场景
│   │   ├── ui/           # UI 场景
│   │   └── entities/     # 动物塔、敌人、英雄
│   └── scripts/          # GDScript 逻辑
├── assets/               # 美术、音效、字体资源
├── design/               # 游戏设计文档
│   └── gdd/              # 34个系统 GDD
├── docs/                 # 技术文档
│   └── engine-reference/ # Godot 4.6 版本参考
├── tests/                # GUT 单元测试
└── production/           # 生产管理（Sprint 计划等）
```

---

## 技术栈

| 项目 | 选择 |
|------|------|
| 引擎 | Godot 4.6 |
| 语言 | GDScript |
| 渲染 | Compatibility (OpenGL) |
| 物理 | Godot Physics 2D |
| 测试 | GUT (Godot Unit Testing) |
| 版本控制 | Git / GitHub |

---

## 快速开始

1. 安装 [Godot 4.6](https://godotengine.org/releases/4.6/)
2. 克隆本仓库
3. 在 Godot 中打开 `src/project.godot`
4. 运行主场景

---

## 设计参考

本游戏受以下作品启发：
- **Tangy TD**（Cakez，2026）— Build 深度和实时英雄操控的直接参考
- **Path of Exile** — 技能树设计哲学
- **Vampire Survivors** — 实时操作感和 Roguelite 循环
- **Bloons TD** — 塔防框架和波次设计

---

## 开发日志

- **2026-03-27** — 完成全部 34 个系统 GDD 文档
- **2026-03-27** — 确定引擎：Godot 4.6 + GDScript
- **2026-03-09** — 项目立项，完成游戏概念和系统索引
