# Sprint 8 — 2026-07-03 至 2026-07-16

## Sprint 目标
补全 Alpha 养成收尾：图鉴收集系统上线，关卡选择进度逻辑完整，达成 Vertical Slice 里程碑。

---

## Capacity
- 总天数：10 个工作日
- 缓冲（20%）：2 天
- 可用：8 天

---

## Tasks

### Must Have（关键路径）

| ID | 任务 | Agent/Owner | 估时 | 依赖 | 验收标准 |
|----|------|-------------|------|------|----------|
| S8-01 | **主菜单** — `main_menu.gd` 已完成（4按钮 + 印记显示 + MAIN_MENU state）| Claude | 0天 | ✅ Sprint 7 已交付 | 启动进入主菜单；4个按钮功能正常 |
| S8-02 | **图鉴收集系统** — 新建 `CollectionManager` autoload；在 `tower_placement_manager._try_place` 和 `enemy._on_die` 埋点；新建 `collection_panel.gd`（12动物+11敌人网格，未解锁显示???，已解锁显示名称）；注册 autoload | Claude | 3天 | SaveLoad ✅ | 首次放猎豹 → 图鉴亮起 + +3印记 + 弹出提示；再次放置不重复给印记；重启后图鉴状态保留 |

### Should Have

| ID | 任务 | Agent/Owner | 估时 | 依赖 | 验收标准 |
|----|------|-------------|------|------|----------|
| S8-03 | **关卡选择进度补全** — `GameState.current_level_id`；`level_select_panel` 写入当前关卡；`game_over_panel._save_result` 改用 `current_level_id`，胜利时将下一关从 LOCKED→UNLOCKED 并显示解锁提示 | Claude | 1天 | S8-01 ✅ | 通关 ancient_savanna 后 lava_canyon 变为可选；level_progress 存档写入 CLEARED；解锁提示显示「新关卡解锁：熔岩峡谷！」 |

### Nice to Have

| ID | 任务 | Agent/Owner | 估时 | 依赖 | 验收标准 |
|----|------|-------------|------|------|----------|
| S8-04 | **Milestone-02 定义** — 新建 `production/milestones/milestone-02-vertical-slice.md`；Sprint 5-8 交付清单全部 [x]；声明进入 Alpha 阶段 | Claude | 0.5天 | 无 | 文件存在；所有完成标准均标 [x] |

---

## Carryover from Sprint 7

| 任务 | 原因 | 新估时 |
|------|------|--------|
| 无 | Sprint 7 全部完成 | — |

---

## Risks

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| CollectionManager toast 与其他 CanvasLayer 冲突 | 低 | 低 | layer=120 高于所有 UI |
| game_over_panel 动态插入 Label 在重复进入时叠加 | 中 | 低 | _show 每次调用前设 _unlocked_level_name=""，Label 仅在首次解锁时创建 |

---

## Definition of Done for this Sprint
- [x] S8-02 图鉴系统：CollectionManager + collection_panel 完整实现
- [x] S8-03 关卡进度：通关解锁下一关，存档正确写入
- [x] S8-04 Milestone-02 文档创建
- [x] 代码合并至 main 分支

## 修改文件
- `src/autoloads/collection_manager.gd` — S8-02（新增 CollectionManager autoload）
- `src/project.godot` — S8-02（注册 CollectionManager autoload）
- `src/scripts/ui/collection_panel.gd` — S8-02（新增图鉴面板）
- `src/scripts/gameplay/tower_placement_manager.gd` — S8-02（放置后调用 CollectionManager）
- `src/scripts/gameplay/enemy.gd` — S8-02（击杀后调用 CollectionManager）
- `src/autoloads/game_state.gd` — S8-03（添加 current_level_id 字段）
- `src/scripts/ui/level_select_panel.gd` — S8-03（写入 current_level_id）
- `src/scripts/ui/game_over_panel.gd` — S8-03（动态关卡id + 通关解锁逻辑）
- `production/milestones/milestone-02-vertical-slice.md` — S8-04（新增 Milestone-02）
