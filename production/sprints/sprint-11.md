# Sprint 11 — 2026-08-07 至 2026-08-20

## Sprint 目标
Alpha 收尾打磨：将本地化系统接入全部 UI 硬编码文本、修复已知体验问题、完成三关波次差异化配置——使三张地图各具独立游戏感。

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
| S11-01 | **UI 本地化接入** — 将 `hud.gd`、`build_panel.gd`、`game_over_panel.gd`、`level_select_panel.gd`、`shop_panel.gd`、`inventory_panel.gd`、`crafting_panel.gd`、`skill_tree_panel.gd` 中所有硬编码中文字符串替换为 `Localization.L(key)` 调用；`zh-CN.json` / `en-US.json` 已有对应 key | Claude | 3天 | S10-03 ✅ | 设置切换 en-US 重启后，HUD 显示「Gold」「Wave」「Base HP」；关卡选择界面显示英文关卡名和描述 |
| S11-02 | **lava_canyon / frozen_tundra 独立波次配置** — `wave_manager.gd` 支持按 `current_level_id` 选取波次表；新增 `WAVE_CONFIG_LAVA`（Z形地形敌人组合偏重装甲）和 `WAVE_CONFIG_FROZEN`（U形长路偏重快速敌人）各 10 波；Boss 波保持 trex_king | Claude | 2天 | 关卡地图 ✅ | 进入 lava_canyon 第1波出现不同于 ancient_savanna 的敌人组合；frozen_tundra 早波有更多高速敌人 |
| S11-03 | **关卡描述文本更新** — `level_select_panel.gd` 中「待解锁」描述替换为正式文案，中英双语均通过 `L()` 获取；`zh-CN.json` / `en-US.json` 补充对应 key | Claude | 0.5天 | S11-01 | 关卡2描述显示「Z形三折道，装甲敌人居多」，不再出现「待解锁」字样 |

### Should Have

| ID | 任务 | Agent/Owner | 估时 | 依赖 | 验收标准 |
|----|------|-------------|------|------|----------|
| S11-04 | **图鉴道具标签页完整化** — `collection_panel.gd` 道具标签页显示全部 40 种道具（25基础+15合成）；未解锁显示「？？？」；`CollectionManager` 补充道具解锁存档字段 `seen_items` | Claude | 1天 | ItemDB ✅ | 图鉴道具标签页显示40格；首次进背包后对应格解锁显示名称 |
| S11-05 | **协同效果 Banner 本地化** — `synergy_manager.gd` 的 banner 文本改为 `Localization.L("synergy." + syn_id + ".name") + Localization.L("synergy.activated")`；新增对应 key | Claude | 0.5天 | S11-01 | 英文模式协同激活提示显示英文名称 |

### Nice to Have

| ID | 任务 | Agent/Owner | 估时 | 依赖 | 验收标准 |
|----|------|-------------|------|------|----------|
| S11-06 | **lava_canyon 熔岩格视觉区分** — `map_renderer.gd` 在 lava_canyon 关卡将 BLOCKED 格渲染为橙红色，与普通 BLOCKED 格区分 | Claude | 1天 | 关卡地图 ✅ | 进入熔岩峡谷后，部分不可建格子呈橙红色调 |
| S11-07 | **frozen_tundra 冰雪格视觉区分** — 同上，frozen_tundra 关卡 BLOCKED 格渲染为冰蓝色 | Claude | 0.5天 | S11-06 | 进入冰封冻原后不可建格呈蓝白色调 |

---

## Carryover from Sprint 10

无。

---

## Risks

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| UI 硬编码字符串量大，逐文件替换容易遗漏 | 高 | 中 | 替换后 grep 全库检查残余中文字符串 |
| 三关波次配置时平衡性偏差 | 中 | 中 | 以 ancient_savanna 现有 WAVE_CONFIG 为基准做相对调整，不重新设计数值 |
| 本地化 key 不一致导致英文界面出现 key 字符串 | 低 | 低 | 写入 JSON 后运行自动化检查，确认所有 key 存在 |

---

## Dependencies on External Factors

- 无外部依赖

---

## Definition of Done for this Sprint
- [x] 所有 Must Have 任务完成
- [x] 切换 en-US 重启后无中文硬编码字符串残留（grep 验证）
- [x] 三关均可从关卡选择进入并完整游玩 10 波
- [x] 无 S1/S2 级 bug
- [x] sprint-11.md 归档，systems-index.md 状态无需更新（所有系统已完成）

---

## 交付结果

| ID | 状态 | 备注 |
|----|------|------|
| S11-01 | ✅ 完成 | grep 验证 8 个目标文件无硬编码中文字符串 |
| S11-02 | ✅ 完成 | `wave_manager.gd` 新增 `WAVE_CONFIG_LAVA` / `WAVE_CONFIG_FROZEN`，`_get_wave_config()` 按 `current_level_id` 分发 |
| S11-03 | ✅ 完成 | `level_select_panel.gd:80` 已用 `L(key)`，JSON key 已存在，无需修改 |
| S11-04 | ✅ 完成 | `collection_panel.gd` 道具标签页遍历 `ItemDB.get_all_ids()`，`seen_items` 存档读写已实现 |
| S11-05 | ✅ 完成 | `synergy_manager.gd:81` banner 改为 `Localization.L("synergy.activated", [L("synergy.{id}.name")])` |
| S11-06 | ✅ 完成 | `map_renderer.gd` lava_canyon BLOCKED 格渲染为橙红色 `(0.70, 0.25, 0.05)` |
| S11-07 | ✅ 完成 | `map_renderer.gd` frozen_tundra BLOCKED 格渲染为冰蓝色 `(0.55, 0.75, 0.95)` |

---

## Carryover

无。
