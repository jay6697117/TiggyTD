# Sprint 10 — 2026-07-31 至 2026-08-06

## Sprint 目标
清除 Vertical Slice 遗留项：金币不足 UI 信号、关卡 2/3 地形特效、双语本地化文件补全——让 Alpha 阶段可完整体验三张地图。

---

## Capacity
- 总天数：5 个工作日
- 缓冲（20%）：1 天
- 可用：4 天

---

## Tasks

### Must Have（关键路径）

| ID | 任务 | Agent/Owner | 估时 | 验收标准 |
|----|------|-------------|------|----------|
| S10-01 | **金币不足 UI 信号修复** — `_try_upgrade` 金币不足时 emit `placement_failed`，HUD 显示 toast | Claude | 0.5天 | 升级金币不足时屏幕出现「金币不足」红字提示 |
| S10-02 | **frozen_tundra 速度加成** — 敌人 init 时检测 `current_level_id`，冰封冻原关卡 `_speed_base *= 1.1` | Claude | 0.5天 | 冰封冻原关卡迅猛龙速度=90×1.1=99，其他关卡不变 |
| S10-03 | **双语本地化文件** — 填充 `zh-CN.json` 和 `en-US.json`，共 129 个 key，覆盖 UI/技能/动物/敌人/协同/道具/状态/商店/错误分类 | Claude | 2天 | `Localization.L("ui.gold")` 中文返回「金币」、英文返回「Gold」；所有 key 无缺失 |

---

## 交付结果

| ID | 状态 | 备注 |
|----|------|------|
| S10-01 | ✅ 完成 | `tower_placement_manager.gd:141` 新增 emit |
| S10-02 | ✅ 完成 | `enemy.gd:91` 新增 frozen_tundra 判断 |
| S10-03 | ✅ 完成 | 两个 JSON 各 129 keys，Python 脚本生成并验证 |

---

## Carryover

无。

---

## Commit

`12c9ddd` feat: Sprint 10 — 金币不足UI信号修复、frozen_tundra速度加成、双语本地化文件
