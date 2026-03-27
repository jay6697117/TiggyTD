# Sprint 2 — 2026-04-10 至 2026-04-23

## Sprint 目标
实现英雄（老虎）系统核心：右键点击移动、A*寻路、光环加成，完成「操控英雄 + 塔防」的完整核心体验。

---

## Tasks

### Must Have

| ID | 任务 | 验收标准 |
|----|------|----------|
| S2-01 | **英雄移动** — 右键点击地图，英雄沿寻路路径移动 | 右键任意可达格子，英雄平滑移动到目标位置 |
| S2-02 | **寻路系统** — PathfindingSystem autoload（AStarGrid2D） | 英雄不穿越 BLOCKED 格，塔放置/移除后路径实时更新 |
| S2-03 | **英雄光环** — 3格范围内动物塔攻速+20% | 英雄移近塔时塔攻击间隔缩短20%，离开后恢复 |
| S2-04 | **英雄占位渲染** — 橙色圆形色块 + 光环范围圆圈 | 英雄位置可见橙圆，光环范围可见淡黄圆圈 |

### Should Have

| ID | 任务 | 验收标准 |
|----|------|----------|
| S2-05 | **集成测试** — BUILD→WAVE×10→WIN/LOSE 全流程无崩溃 | 完整一局无脚本错误 |

---

## 完成状态
- [x] S2-01 英雄移动（hero.gd）
- [x] S2-02 寻路系统（pathfinding_system.gd autoload）
- [x] S2-03 英雄光环（tower.gd _get_aura_bonus）
- [x] S2-04 英雄渲染（hero.gd _draw）
- [x] S2-05 启动无错误

## 新增文件
- `src/autoloads/pathfinding_system.gd`
- `src/scripts/gameplay/hero.gd`（从占位符升级）

## 修改文件
- `src/project.godot` — 注册 PathfindingSystem autoload
- `src/scripts/gameplay/tower.gd` — _fire() 加入光环加成查询
