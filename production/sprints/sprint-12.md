# Sprint 12 — 2026-08-21 至 2026-09-03

## Sprint 目标
Beta 阶段首冲：修复 Alpha 遗留 Bug、完成全量本地化收尾（含引导文本、道具效果、道具商店 UI）、新增暂停菜单、接入图腾神殿 meta 节点实际效果——使游戏从功能完整走向体验完整。

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
| S12-01 | **首通奖励 Bug 修复** — `game_over_panel.gd:85` 缩进错误导致 `break` 总是执行，首通20印记永远不发放 | Claude | 0.5天 | — | 首次通关 ancient_savanna 获得 20 额外印记 |
| S12-02 | **引导文本本地化** — `tutorial_overlay.gd` 8 步硬编码中文改为 `Localization.L("tutorial.step_N")`；按钮文本"知道了"/"跳过引导"改用 key；`zh-CN.json`/`en-US.json` 补充 10 个 tutorial key | Claude | 1天 | S11-01 ✅ | 英文模式下引导全程显示英文 |
| S12-03 | **暂停菜单新增** — 新建 `pause_panel.gd`（96行），ESC 键触发，WAVE/BUILD 状态下生效，layer=90；提供"继续游戏"和"返回主菜单"两个按钮；暂停时 `get_tree().paused = true` | Claude | 1天 | — | ESC 弹出暂停菜单，点继续恢复，点主菜单回到首页 |
| S12-04 | **主菜单全量本地化** — `main_menu.gd` 副标题、4 个按钮文本、印记显示改为 `Localization.L()` 调用 | Claude | 0.5天 | S11-01 ✅ | 英文模式主菜单无中文 |
| S12-05 | **图鉴面板重构与本地化** — `collection_panel.gd` 数据结构从 `{id, name}` 简化为纯 ID 列表，名称通过 `L("animal." + id)` 获取；进度文本、标签页标题本地化；解锁计数逻辑优化 | Claude | 1天 | S11-04 ✅ | 英文模式图鉴标题/进度/标签页全英文 |
| S12-06 | **道具商店全量本地化** — `item_shop_panel.gd` 标题、金币显示、刷新按钮、购买按钮、无货/已售文本改为 `L()` 调用；25 个道具效果描述改为 `L("item.effect." + type)` | Claude | 1.5天 | S11-01 ✅ | 英文模式道具商店全英文，效果描述正确显示参数 |

### Should Have

| ID | 任务 | Agent/Owner | 估时 | 依赖 | 验收标准 |
|----|------|-------------|------|------|----------|
| S12-07 | **图腾神殿本地化** — `totem_temple_panel.gd` 印记余额、已解锁标记改为 `L()` 调用 | Claude | 0.5天 | S11-01 ✅ | 英文模式图腾神殿无中文 |
| S12-08 | **图鉴 Toast 本地化** — `collection_manager.gd` 解锁提示改为 `L("ui.collection_toast")` | Claude | 0.1天 | S11-01 ✅ | 英文模式图鉴解锁提示显示英文 |
| S12-09 | **首通奖励通用化** — `game_over_panel.gd:82` 首通判定从硬编码 `ancient_savanna` 改为 `GameState.current_level_id`，三关首通均有额外印记 | Claude | 0.5天 | S12-01 | 通关 lava_canyon/frozen_tundra 首次也获得20额外印记 |
| S12-10 | **道具商店图腾节点效果接入** — `item_shop_panel.gd` 刷新费用受 `eco_shop_discount` 节点影响降至25g；`build_free_item` 节点提供每波首件免费 | Claude | 0.5天 | 图腾节点 ✅ | 解锁对应节点后商店刷新25g，首件免费 |
| S12-11 | **技能树图腾节点效果接入** — `skill_tree_panel.gd` 解锁 `build_skill_disc` 节点后技能点消耗打9折 | Claude | 0.3天 | 图腾节点 ✅ | 解锁节点后技能点费用显示90% |
| S12-12 | **关卡提前解锁** — `level_select_panel.gd` 解锁 `unlock_map2` 图腾节点后无需通关即可进入 lava_canyon | Claude | 0.3天 | 图腾节点 ✅ | 解锁节点后 lava_canyon 直接可选 |
| S12-13 | **英雄技能 CD 优化** — `hero.gd` 自然之唤技能 CD 改为可配置变量 `_natures_call_cd_max`，与时代审判保持一致的参数化设计 | Claude | 0.3天 | — | 英雄技能 CD 可通过变量调整 |

### Nice to Have

| ID | 任务 | Agent/Owner | 估时 | 依赖 | 验收标准 |
|----|------|-------------|------|------|----------|
| S12-14 | **风险登记册更新** — `risks.md` 新增 R-06~R-10 五项风险，对已有风险调整状态 | Claude | 0.2天 | — | 风险登记册反映 Beta 阶段最新风险评估 |

---

## Carryover from Sprint 11

无。

---

## Risks

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 本地化 key 数量激增（+60 key），遗漏导致英文界面显示 key 名 | 中 | 中 | 提交后 grep 全库验证所有 key 存在于两份 JSON |
| 暂停菜单与现有状态机冲突 | 低 | 高 | 新增 PAUSED 状态，`process_mode = ALWAYS` 保证暂停面板可操作 |
| 图腾节点效果接入后平衡性变化 | 低 | 中 | 折扣/免费幅度保守（5g/首件/10%），后续微调 |

---

## Dependencies on External Factors

- 无外部依赖

---

## Definition of Done for this Sprint
- [x] 所有 Must Have 任务完成
- [x] 所有 Should Have 任务完成
- [x] 暂停菜单功能正常（ESC 触发、继续、返回主菜单）
- [x] 英文模式下全 UI 无中文硬编码字符串残留（引导文本含）
- [x] 三关首通均可获得额外印记
- [x] 图腾节点 `eco_shop_discount` / `build_free_item` / `build_skill_disc` / `unlock_map2` 效果生效
- [x] sprint-12.md 归档

---

## 交付结果

| ID | 状态 | 备注 |
|----|------|------|
| S12-01 | ✅ 完成 | `game_over_panel.gd:85` 缩进修正，`break` 移入条件体内（提交 `5479614`） |
| S12-02 | ✅ 完成 | `tutorial_overlay.gd` 8步改为 `key` 字段 + `L()` 调用，按钮文本本地化（提交 `5479614`） |
| S12-03 | ✅ 完成 | `pause_panel.gd` 新建 96 行，`main.gd` 注册暂停面板（提交 `5479614`） |
| S12-04 | ✅ 完成 | `main_menu.gd` 副标题+4按钮+印记显示全部 `L()` 化（提交 `5479614`） |
| S12-05 | ✅ 完成 | `collection_panel.gd` 简化为 ID 列表，名称/进度/标签页本地化（提交 `5479614`） |
| S12-06 | ✅ 完成 | `item_shop_panel.gd` 标题+金币+25效果描述全部 `L()` 化（提交 `5479614` + `318506e`） |
| S12-07 | ✅ 完成 | `totem_temple_panel.gd` 印记余额+已解锁标记 `L()` 化（提交 `5479614`） |
| S12-08 | ✅ 完成 | `collection_manager.gd` Toast 本地化（提交 `5479614`） |
| S12-09 | ✅ 完成 | `game_over_panel.gd:82` 改为 `GameState.current_level_id`（提交 `318506e`） |
| S12-10 | ✅ 完成 | 商店刷新费用动态化+首件免费逻辑（提交 `318506e`） |
| S12-11 | ✅ 完成 | 技能点 9 折逻辑（提交 `318506e`） |
| S12-12 | ✅ 完成 | `unlock_map2` 节点提前解锁 lava_canyon（提交 `318506e`） |
| S12-13 | ✅ 完成 | `_natures_call_cd_max` 参数化（提交 `318506e`） |
| S12-14 | ✅ 完成 | `risks.md` 新增 R-06~R-10（提交 `5479614`） |

---

## Carryover

无。
