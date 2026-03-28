# Sprint 4 — 2026-05-08 至 2026-05-21

## Sprint 目标
完善 MVP 体验：修复重开 bug、扩充建造面板动物、实现波次间商店系统。

---

## Tasks

### Must Have

| ID | 任务 | 验收标准 |
|----|------|----------|
| S4-01 | **重开修复** — `game_over_panel` 重开时 `reload_current_scene()` + GameState.reset_run()，确保塔/敌人节点完全清除 | 连续两局无节点叠加，金币/血量归零正确 |
| S4-02 | **BuildPanel 扩充** — 将全部 12 种动物（tiger/lion/eagle/owl/otter/peacock/chameleon 追加）加入建造面板 | 所有 12 种动物可在 BUILD 状态放置 |

### Should Have

| ID | 任务 | 验收标准 |
|----|------|----------|
| S4-03 | **商店系统** — SHOP 状态，每波结束后弹出，消耗古代印记(ancient_marks)购买：全场塔 HP+20%、下波金币+50、英雄技能 CD 重置 | 3 个商品可购买，古代印记余额正确扣减，关闭商店进入 BUILD |
| S4-04 | **古代印记奖励** — 击杀 boss 时获得 3 个古代印记，普通波次结算奖励 1 个 | wave_cleared 后 ancient_marks += 1，wave 10 boss 死亡额外 +3 |

### Won't Have This Sprint
- 塔升级系统
- 第二张地图
- 存档落地（SaveLoad stub 维持现状）

---

## 完成状态
- [ ] S4-01 重开修复
- [ ] S4-02 BuildPanel 扩充
- [ ] S4-03 商店系统
- [ ] S4-04 古代印记奖励

## 修改文件
- `src/scripts/ui/game_over_panel.gd` — S4-01
- `src/scripts/ui/build_panel.gd` — S4-02
- `src/autoloads/game_state.gd` — S4-03/04（ancient_marks 信号）
- `src/scripts/ui/shop_panel.gd` — S4-03（新建）
- `src/scenes/game/main.tscn` — S4-03（新增 ShopPanel 节点）
- `src/scripts/gameplay/wave_manager.gd` — S4-04
