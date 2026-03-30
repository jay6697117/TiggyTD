# Sprint 9 — 2026-07-17 至 2026-07-30

## Sprint 目标
实现道具系统完整接入战斗：ItemDB 数据层、背包、装备到塔/英雄、效果生效、合成台——让每局的 Build 深度真正可玩。

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
| S9-01 | **ItemDB autoload** — 新建 `src/autoloads/item_db.gd`；静态字典存储25种基础道具 + 15种合成道具的完整属性（id/name/tier/price/recipe/effects/shop_weight）；注册到 `project.godot` | Claude | 1天 | 道具数据库 GDD ✅ | `ItemDB.get("sharp_claw")` 返回正确属性字典；所有40种道具可查询；合成道具 recipe 字段包含2个原材料 id |
| S9-02 | **Inventory 背包系统** — 新建 `src/scripts/gameplay/inventory.gd`（Node，挂载到主场景）；最多6格；`add_item(item_id)→bool`、`remove_item(item_id)`、`has_item(item_id)→bool`、`free_slots→int`；背包变化时 emit `inventory_changed` 信号；背包满时拒绝并通过 HUD toast 提示「背包已满」 | Claude | 1天 | S9-01 ✅ | 6件后第7件被拒绝；`inventory_changed` 信号触发 UI 刷新；CollectionManager 图鉴道具解锁在此埋点（`CollectionManager.on_item_acquired`） |
| S9-03 | **道具装备到塔** — Tower 新增 `equipped_item: String`（空串=无装备）、`equip_item(item_id)`、`apply_item_effects()`；效果类型覆盖：STAT_MODIFIER（atk/atk_speed/hp/range/armor_rate 加法叠加）、ON_HIT（poison/slow/armor_break 通过 StatusEffect 接口调用）；TowerPlacementManager 新增 `equip_to_tower(cell, item_id)` 接口 | Claude | 2天 | S9-01, S9-02 ✅ | 将 sharp_claw 装备到猎豹，猎豹 atk 立即+10；slow_mud 装备后攻击附带减速；装备满1件后拒绝第二件并提示 |
| S9-04 | **商店出售道具** — 修改 `src/scripts/ui/shop_panel.gd`；波次后商店按 ItemDB.shop_weight 随机生成4件基础道具；显示名称+价格；购买扣金币后调用 `Inventory.add_item`；「背包已满」时购买按钮置灰 | Claude | 1.5天 | S9-01, S9-02, S9-03 ✅ | 第3波商店出现道具；购买后背包+1；金币不足时按钮灰色；背包满时按钮灰色 |

### Should Have

| ID | 任务 | Agent/Owner | 估时 | 依赖 | 验收标准 |
|----|------|-------------|------|------|----------|
| S9-05 | **合成台** — 新建 `src/scripts/ui/crafting_panel.gd`（嵌入商店面板右侧标签页）；列出所有15条合成配方；可合成者高亮（背包中有两件材料且有空槽）；点击高亮配方弹出确认→执行合成；配方按 ItemDB 的 recipe 字段驱动，无硬编码 | Claude | 1.5天 | S9-01, S9-02 ✅ | 背包有利爪+毒牙时死亡之牙配方高亮；确认合成后背包移除两件材料、增加死亡之牙；材料不足时配方灰色 |
| S9-06 | **背包 + 装备 UI** — 新建 `src/scripts/ui/inventory_panel.gd`（CanvasLayer，layer=75，BUILD 状态按 I 键或 HUD 按钮打开）；6格网格显示背包道具；点击道具→进入装备目标选择模式→点击塔格子调用 `equip_to_tower`；已装备道具在塔卡片上显示名称标签 | Claude | 1天 | S9-02, S9-03 ✅ | 背包面板 I 键可开关；点击道具再点击塔完成装备；塔的 skill_tree_panel 显示已装备道具名称 |

### Nice to Have

| ID | 任务 | Agent/Owner | 估时 | 依赖 | 验收标准 |
|----|------|-------------|------|------|----------|
| S9-07 | **图鉴道具标签页** — 补全 `collection_panel.gd` 的第三个标签页「道具」；显示40种道具格（首次进背包解锁）；CollectionManager 新增 `on_item_acquired(item_id)` 调用点 | Claude | 0.5天 | S9-02, S8-02 ✅ | 图鉴进度从「X/23」变为「X/63」；首次获得利爪后道具格亮起 |

---

## Carryover from Sprint 8

| 任务 | 原因 | 新估时 |
|------|------|--------|
| 无 | Sprint 8 全部完成 | — |

---

## Risks

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| Tower 效果叠加顺序与 GDD 公式不一致导致数值偏差 | 中 | 中 | S9-03 实现前先在 Tower 注释中写出叠加公式，与 damage-calculation.md 对照后再编码 |
| 商店改造破坏现有波次间 ShopPanel（古代印记商店）逻辑 | 中 | 高 | 现有 ShopPanel 是印记商店，S9-04 新建独立 ItemShopPanel，不修改现有文件；两个商店在不同状态触发 |
| ON_HIT 道具效果与状态效果系统接口不匹配 | 低 | 中 | 先读 status_effect.gd 接口再实现，复用已有 apply_status 函数 |
| S9-05 合成台体量偏大，Should Have 可能延期 | 中 | 低 | S9-01~S9-04 是硬目标；S9-05/S9-06 可推至 Sprint 10 |

---

## Dependencies on External Factors
- 无外部依赖；全部基于已有 GDD 和代码

---

## Definition of Done for this Sprint
- [ ] S9-01 ItemDB：40种道具全部可查询
- [ ] S9-02 Inventory：6格背包，满格拒绝，信号驱动UI
- [ ] S9-03 道具装备到塔：STAT_MODIFIER + ON_HIT 效果生效
- [ ] S9-04 商店出售道具：随机4件，购买进背包
- [ ] S9-05 合成台：配方驱动，合成结果进背包
- [ ] S9-06 背包UI：I键开关，点选装备到塔
- [ ] 无 S1/S2 bug（崩溃、存档损坏）
- [ ] `design/gdd/systems-index.md` 更新（道具系统标为代码已实现）
- [ ] 代码合并至 main 分支

## 预计修改文件
- `src/autoloads/item_db.gd` — S9-01（新增）
- `src/project.godot` — S9-01（注册 ItemDB）
- `src/scripts/gameplay/inventory.gd` — S9-02（新增）
- `src/scripts/gameplay/tower.gd` — S9-03（装备槽 + apply_item_effects）
- `src/scripts/gameplay/tower_placement_manager.gd` — S9-03（equip_to_tower 接口）
- `src/scripts/ui/shop_panel.gd` — S9-04（改造为道具商店，或新增 item_shop_panel.gd）
- `src/scripts/ui/crafting_panel.gd` — S9-05（新增）
- `src/scripts/ui/inventory_panel.gd` — S9-06（新增）
- `src/autoloads/collection_manager.gd` — S9-07（新增 on_item_acquired）
- `src/scripts/ui/collection_panel.gd` — S9-07（道具标签页）
