# 风险登记册

## 已关闭风险

| ID | 风险描述 | 关闭 Sprint | 实际解决方案 |
|----|---------|------------|-------------|
| R-01 | VFX/Audio 场景资源缺失导致运行时 warning 洪流 | Sprint 7 | AudioSystem/VFXSystem 防御性实现，缺失文件时静默跳过 |
| R-02 | `map_renderer._input` 鼠标坐标与 Camera2D 偏移不对齐 | Sprint 1 | 坐标转换使用 `get_local_mouse_position()` 直接在 Node2D 空间计算，无偏移 |
| R-03 | 英雄节点无脚本，`main.gd` 未初始化英雄系统 | Sprint 1 | `hero.gd` 完整实现，`main.gd` 通过 `@onready` 引用 |
| R-04 | `TowerPlacementManager` 第71行代码截断，可能有遗漏 | Sprint 1 | 文件完整，截断为编辑器显示问题，代码逻辑无缺失 |
| R-05 | 无建造面板，玩家无法选塔，游戏不可玩 | Sprint 1 | `build_panel.gd` 完整实现，支持12种动物塔选择 |
| R-06 | 无胜负面板，WIN/LOSE 状态无视觉反馈 | Sprint 1 | `game_over_panel.gd` 完整实现，含印记结算和关卡解锁提示 |

---

## 当前活跃风险

| ID | 风险描述 | 概率 | 影响 | 缓解措施 |
|----|---------|------|------|----------|
| R-07 | 暂停面板 `get_tree().paused` 会暂停所有非 PROCESS_MODE_ALWAYS 节点，可能影响 CanvasLayer UI 响应 | 中 | 低 | pause_panel 已设置 PROCESS_MODE_ALWAYS；其他 UI 面板在暂停时本应不响应，行为符合预期 |
| R-08 | 本地化 key 缺失时 `Localization.L()` 返回 key 字符串，英文模式下可能出现 key 名称显示 | 低 | 低 | Sprint 12 结束时执行 grep 全量验证，确认所有 key 存在于两份 JSON |
