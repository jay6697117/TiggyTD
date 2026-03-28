# Sprint 6 — 2026-06-05 至 2026-06-18

## Sprint 目标
精灵图替换：以程序生成的 64×64 PNG 占位图取代 ColorRect 色块，为后续美术资源导入铺路。

---

## Tasks

### Must Have

| ID | 任务 | 验收标准 |
|----|------|----------|
| S6-01 | **占位精灵生成器** — `tools/gen_placeholder_sprites.py`；纯 stdlib 生成 64×64 RGBA PNG（彩色圆形）；12 种塔 + 11 种敌人 | 运行脚本后 `assets/art/towers/` 和 `assets/art/enemies/` 各有对应 PNG |
| S6-02 | **Tower Sprite2D** — `tower.gd` 替换 `_draw()` 色块为 `Sprite2D` 子节点；升级时用 `modulate` 加深（2级灰 0.75，3级灰 0.55）；等级黄点保留 `_draw()` | 放置塔可见彩色圆形精灵；升级后颜色变暗 |
| S6-03 | **Enemy Sprite2D** — `enemy.gd` `setup()` 添加 `Sprite2D` 子节点；HP 条 `_draw()` 保留不变 | 敌人可见对应彩色圆形精灵 |

### Won't Have This Sprint
- 真实美术资源（保持占位 PNG）
- 动画帧（AnimatedSprite2D）
- 第二张地图

---

## 完成状态
- [x] S6-01 占位精灵生成器
- [x] S6-02 Tower Sprite2D
- [x] S6-03 Enemy Sprite2D

## 修改文件
- `tools/gen_placeholder_sprites.py` — 新增，生成占位 PNG
- `assets/art/towers/*.png` — 新增 12 个占位精灵
- `assets/art/enemies/*.png` — 新增 11 个占位精灵
- `src/scripts/gameplay/tower.gd` — S6-02（Sprite2D、modulate、删除 ANIMAL_COLORS）
- `src/scripts/gameplay/enemy.gd` — S6-03（Sprite2D）
