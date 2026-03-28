# Sprint 3 — 2026-04-24 至 2026-05-07

## Sprint 目标
实现英雄三个主动技能：百兽怒吼(Q)、自然之召(W)、纪元审判(E)；完成 Milestone 1 MVP 验收。

---

## Tasks

### Must Have

| ID | 任务 | 验收标准 |
|----|------|----------|
| S3-01 | **Tower buff 系统** — `apply_buff(id, duration, atk_mult, speed_mult)`，叠加字典管理 | 多个 buff 共存不互相覆盖，到期自动移除 |
| S3-02 | **英雄技能框架** — CASTING/TARGET_SELECT 状态，三个 CD 计时器，`skill_cd_updated` 信号 | 施法期间英雄不可移动，CD 倒计时正确发出信号 |
| S3-03 | **百兽怒吼(Q)** — 全场塔 atk_speed×1.5，持续8秒，CD=30秒 | 猎豹攻击间隔怒吼期间≈0.267s，8秒后恢复 |
| S3-04 | **自然之召(W)** — 5格内塔 atk×1.3，持续10秒，CD=45秒 | 施法位置5格内塔伤害×1.3，范围外不受影响 |
| S3-05 | **纪元审判(E)** — 点击选择目标，300固定伤害无视护甲，CD=120秒 | armor=50%的敌人受到300伤害（非150）；点击空地取消不消耗CD |
| S3-06 | **技能UI** — HUD底部技能栏（Q/W/E按钮+CD倒计时标签） | CD期间按钮置灰显示倒计时，就绪后高亮 |

### Should Have

| ID | 任务 | 验收标准 |
|----|------|----------|
| S3-07 | **MVP集成验收** — BUILD→WAVE×10→WIN/LOSE 全流程无崩溃 | 完整一局无脚本错误，三个技能均可正常触发 |

---

## 完成状态
- [x] S3-01 Tower buff字典系统（tower.gd）
- [x] S3-02 英雄技能框架（hero.gd）
- [x] S3-03 百兽怒吼（hero.gd `_do_apex_roar`）
- [x] S3-04 自然之召（hero.gd `_do_natures_call`）
- [x] S3-05 纪元审判（hero.gd `_try_era_judgement_target` + enemy.gd `ignore_armor`）
- [x] S3-06 技能UI（hud.gd + main.tscn SkillBar）
- [x] S3-07 MVP集成验收

## 修改文件
- `src/scripts/gameplay/tower.gd` — 加入 `_buffs` 字典、`apply_buff()`、`_process_buffs()`，`_fire()` 应用buff乘数，`setup()` 加入 "towers" group
- `src/scripts/gameplay/hero.gd` — 全面重写：CASTING/TARGET_SELECT 状态，三个技能实现，PhysicsPointQuery 点击选敌，`skill_cd_updated` 信号
- `src/scripts/gameplay/enemy.gd` — `take_damage(amount, ignore_armor=false)` 加无视护甲参数
- `src/scripts/ui/hud.gd` — 加入技能栏 @onready 引用，`_connect_hero()`，`_on_skill_cd_updated()`
- `src/scenes/game/main.tscn` — 加入 SkillBar Panel 及子节点（三组 VBox+Button+Label）
