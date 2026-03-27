# 风险登记册

| ID | 风险描述 | 概率 | 影响 | 缓解措施 |
|----|---------|------|------|----------|
| R-01 | VFX/Audio 场景资源缺失导致运行时 warning 洪流 | 高 | 低 | AudioSystem/VFXSystem 已做缺失文件防御，暂不影响逻辑 |
| R-02 | `map_renderer._input` 鼠标坐标与 Camera2D 偏移不对齐 | 中 | 高 | Sprint 1 集成测试时验证点击精度 |
| R-03 | 英雄节点无脚本，`main.gd` 未初始化英雄系统 | 高 | 中 | Sprint 1 添加占位英雄脚本，防止 $Hero 引用报错 |
| R-04 | `TowerPlacementManager` 第71行代码截断，可能有遗漏 | 中 | 高 | Sprint 1 首要任务验证完整性 |
| R-05 | 无建造面板，玩家无法选塔，游戏不可玩 | 确定 | 严重 | Sprint 1 Must Have |
| R-06 | 无胜负面板，WIN/LOSE 状态无视觉反馈 | 确定 | 高 | Sprint 1 Must Have |
