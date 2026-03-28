# Sprint 5 — 2026-05-22 至 2026-06-04

## Sprint 目标
补全核心塔防机制：塔升级系统（1→2→3级），平衡波次难度曲线。

---

## Tasks

### Must Have

| ID | 任务 | 验收标准 |
|----|------|----------|
| S5-01 | **塔升级系统** — 再次点击已放置的塔显示「升级/出售」菜单；升级费用=基础费用×当前等级；每级 atk×1.3、hp×1.2；最高3级 | 猎豹3级 atk≈60×1.3²≈101；升级后颜色加深以示区别 |
| S5-02 | **平衡调优** — 调整波次金币奖励、敌人HP、塔攻速使10波可在合理难度通关 | 测试局能在不购买商店的情况下恰好胜利（中等难度） |

### Should Have

| ID | 任务 | 验收标准 |
|----|------|----------|
| S5-03 | **升级UI提示** — 点击已有塔时 BuildPanel 区域显示该塔信息+升级按钮+出售按钮 | 点击3级塔升级按钮置灰并显示「已满级」 |

### Won't Have This Sprint
- 精灵图替换（保持 ColorRect）
- 第二张地图
- 存档落地

---

## 完成状态
- [x] S5-01 塔升级系统
- [x] S5-02 平衡调优
- [x] S5-03 升级UI提示

## 修改文件
- `src/scripts/gameplay/tower.gd` — S5-01（level、upgrade()）
- `src/scripts/gameplay/tower_placement_manager.gd` — S5-01（upgrade 入口）
- `src/scripts/ui/build_panel.gd` — S5-03（塔信息面板）
- `src/scripts/gameplay/wave_manager.gd` — S5-02（金币奖励调整）
- `src/scripts/gameplay/enemy.gd` — S5-02（HP缩放）
