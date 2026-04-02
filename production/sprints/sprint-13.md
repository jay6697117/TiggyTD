# Sprint 13 — 2026-09-04 至 2026-09-17

## Sprint 目标
美术资源首轮替换：将动物塔、敌人、地图 Tileset 的纯色块占位替换为像素贴图；新增设置面板支持音量调节和语言切换。

---

## Capacity
- 总天数：10 个工作日
- 缓冲（20%）：2 天
- 可用：8 天

---

## Tasks

### Must Have（关键路径）

|----|------|-------------|------|------|----------|
| S13-01 | **~~动物塔 Sprite 替换~~** — 12 种动物塔（tiger/lion/ elephant/cheetah/eagle/wolf_pack/owl/otter/peacock/ chameleon/honey_badger/pangolin）使用像素贴图替换纯色块渲染 | 美术+Claude | 3天 | 贴图资源 | 放置后显示动物塔像素图，非纯色块 |
| S13-02 | **~~敌人 Sprite 替换~~** — 11 种史前生物（raptor/triceratops/ mammoth/pterodactyl/ankylosaurus/sabre_tooth/giant_sloth/ doedicurus/mosasaurus/ammonite/trex_king）使用像素贴图 | 美术+Claude | 3天 | 贴图资源 | 敌人行走、攻击时显示像素动画，非纯色块 |
| S13-03 | **地图 Tileset 贴图** — ancient_savanna/lava_canyon/frozen_tundra 三张地图的路径格/建造格/障碍格使用 Tileset 贴图 | 美术+Claude | 2天 | 贴图资源 | 三张地图有明确主题视觉区分 |

### Should Have

|----|------|-------------|------|------|----------|
| S13-04 | **设置面板** — 新建 `settings_panel.gd`；支持 BGM/SFX 音量滑块（0~100）、语言切换（中文/英文）下拉；设置持久化到 SaveLoad | Claude | 1.5天 | — | 主菜单新增"设置"按钮，修改语言后重启生效 |
| S13-05 | **~~UI 图标替换~~** — 金币、古代印记、道具稀有度边框使用小图标 | 美术+Claude | 1天 | 贴图资源 | 金币显示小金币图标而非纯文字 |

### Nice to Have

|----|------|-------------|------|------|----------|
| S13-06 | **英雄 Sprite 替换** — 英雄角色使用像素贴图+行走/待机/攻击动画 | 美术+Claude | 1.5天 | 贴图资源 | 英雄显示像素图，移动时有行走动画 |
| S13-07 | **~~背景图替换~~** — 三关战斗背景 + 主菜单背景使用实际贴图 | 美术+Claude | 1天 | 贴图资源 | 主菜单有像素风背景图 |

---

## Carryover from Sprint 12

无。

---

## Risks

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| Sprite 替换后碰撞/渲染对齐偏移 | 中 | 中 | 替换后逐一在游戏中验证对齐 |
| 设置面板与现有 SaveLoad 兼容性 | 低 | 低 | 新增 `settings` key，不影响现有存档结构 |

---



---

## Definition of Done for this Sprint
- [x] 动物塔在游戏中显示像素贴图
- [x] 敌人在游戏中显示像素贴图
- [ ] 三张地图使用 Tileset 贴图
- [ ] 设置面板可用
- [ ] 无 S1/S2 级 Bug
- [ ] sprint-13.md 归档
