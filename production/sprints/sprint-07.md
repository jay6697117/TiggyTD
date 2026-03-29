# Sprint 7 — 2026-06-19 至 2026-07-02

## Sprint 目标
实现新手引导系统与跨局印记结算，使游戏达到 Vertical Slice「可对外展示」标准。

---

## Capacity
- 总天数：10 个工作日
- 缓冲（20%）：2 天（预留给意外 bug 和调试）
- 可用：8 天

---

## Tasks

### Must Have（关键路径）

| ID | 任务 | Agent/Owner | 估时 | 依赖 | 验收标准 |
|----|------|-------------|------|------|----------|
| S7-01 | **新手引导系统** — 新建 `src/scripts/ui/tutorial_overlay.gd`；8步序列（高亮遮罩+气泡文字+跳过按钮）；首次启动自动触发，完成后写存档 `tutorial_completed=true` | Claude | 3天 | SaveLoad ✅ | AC-1~AC-6 全部通过（见 `design/gdd/tutorial.md`）；首次启动触发引导，再次启动不触发；跳过按钮立即生效 |
| S7-02 | **局末印记结算** — `game_over_panel.gd` 按 GDD 规则计算并发放 meta 印记（胜利+30、失败过5波+10、失败未过5波+5、首通+20、Boss击杀+15）；结算界面显示「+X 古代印记」 | Claude | 1天 | S7-01 存档接入 ✅ | 胜利局结算后 `meta_progression.ancient_marks` 增加30；失败第6波增加10；首通额外+20（仅一次）；结算面板显示印记获得量 |

### Should Have

| ID | 任务 | Agent/Owner | 估时 | 依赖 | 验收标准 |
|----|------|-------------|------|------|----------|
| S7-03 | **图腾神殿 UI** — 主菜单新增「图腾神殿」入口；展示12个节点（名称/费用/状态）；用古代印记购买；加成在下局 `GameState.reset_run()` 时生效；已购节点置灰 | Claude | 3天 | S7-02 ✅ | AC-3~AC-6 通过；12个节点全部显示；印记不足时拒绝购买并提示差额；解锁后重启游戏仍保持 |

### Nice to Have

| ID | 任务 | Agent/Owner | 估时 | 依赖 | 验收标准 |
|----|------|-------------|------|------|----------|
| S7-04 | **VFX 补全** — 为 VFXSystem 的 `victory`/`defeat`/`base_damage` 效果实现真实 Node2D 粒子（当前为空 stub）；不依赖外部资源文件 | Claude | 1天 | 无 | 游戏胜利/失败/基地受损时有明显视觉反馈；无 missing resource 警告 |

---

## Carryover from Sprint 6

| 任务 | 原因 | 新估时 |
|------|------|--------|
| 无 | Sprint 6 全部完成 | — |

---

## Risks

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 引导高亮遮罩与 CanvasLayer 层级冲突 | 中 | 高 | 引导层使用独立 CanvasLayer（layer=100），高于所有 UI |
| 图腾神殿加成需修改 `GameState.reset_run()` 导致回归 | 中 | 中 | 修改前先读取 reset_run 的全部调用方，确认影响范围 |
| S7-03 体量偏大，Should Have 可能延期 | 中 | 低 | S7-01+S7-02 是硬目标；S7-03 可推至 Sprint 8 |

---

## Dependencies on External Factors
- 无外部依赖；全部系统基于已有代码和 GDD

---

## Definition of Done for this Sprint
- [x] S7-01 新手引导 8步全部实现
- [x] S7-02 局末印记结算按 GDD 公式正确计算，结算面板显示获得量
- [x] S7-03 图腾神殿 12节点可购买，加成下局生效
- [x] S7-04 VFX 补全（victory/defeat/base_damage 纯代码粒子）
- [ ] 无 S1/S2 bug（崩溃、存档损坏、进度丢失）
- [ ] `design/gdd/systems-index.md` 更新状态
- [ ] 代码合并至 main 分支

## 修改文件
- `src/scripts/gameplay/hero.gd` — S7-01（signal hero_moved）
- `src/scripts/gameplay/tower_placement_manager.gd` — S7-01（signal tower_placed）
- `src/scripts/ui/tutorial_overlay.gd` — S7-01（新增，8步引导系统）
- `src/scripts/core/main.gd` — S7-01（接入 tutorial_overlay）
- `src/scripts/ui/game_over_panel.gd` — S7-02+S7-03（印记结算标签 + 图腾神殿入口）
- `src/scripts/ui/totem_temple_panel.gd` — S7-03（新增，12节点图腾神殿）
- `src/autoloads/vfx_system.gd` — S7-04（victory/defeat/base_damage 纯代码粒子）
