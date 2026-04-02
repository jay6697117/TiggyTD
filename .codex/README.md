# Codex Game Studios — 完整使用指南

> **Claude Code Game Studios** 的 [OpenAI Codex](https://platform.openai.com/docs/codex) 兼容版本。
> 把一个 Codex 会话变成一个完整的游戏开发工作室：48 个 Agent、37 个 Skill、全套文档模板和自动化脚本。

---

## 🚀 30 秒速查 — 最常用操作

| 场景 | 操作 | 说明 |
|:---:|------|------|
| 🆕 | **首次使用** → 使用 `start` 技能 | 系统引导你选择路径，从零到工作流全搞定 |
| 📋 | **每次开工** → 运行 `bash .codex/scripts/session_start.sh` | 自动加载 Sprint 上下文 + 最近 Git 活动 |
| 💡 | **想点子** → 使用 `brainstorm` 技能 | MDA 框架驱动的专业创意头脑风暴 |
| 🔍 | **代码审查** → 使用 `code-review` 技能 | 按文件/子系统进行针对性审查 |
| ✅ | **提交前** → 运行 `bash .codex/scripts/validate_commit.sh` | 检查硬编码值、TODO 格式、JSON 有效性 |
| 📦 | **推送前** → 运行 `bash .codex/scripts/validate_push.sh` | 警告推送到受保护分支 |
| 🏁 | **结束工作** → 运行 `bash .codex/scripts/wrap_session.sh` | 记录本次工作成果日志 |
| 🎮 | **配置引擎** → 使用 `setup-engine` 技能 | 如 `setup-engine godot 4.6` |
| 📊 | **查看状态** → `/status` | 查看当前会话和项目状态 |
| 🛡️ | **一键预检** → 运行 `bash .codex/scripts/preflight.sh` | 一次跑完所有验证脚本 |
| 👥 | **团队协作** → 使用 `team-*` 系列技能 | 如 `team-combat`、`team-ui`、`team-narrative` |
| 📝 | **Sprint 计划** → 使用 `sprint-plan` 技能 | 创建和管理 Sprint |

> **💡 提示**：在 Codex 中使用技能的方式是自然语言，例如：*"请使用 `brainstorm` 技能"* 或 *"帮我做一个 `code-review`"*

---

## 目录

- [🚀 30 秒速查](#-30-秒速查--最常用操作)
- [这是什么](#这是什么)
- [与 Claude Code 版本的关系](#与-claude-code-版本的关系)
- [快速开始](#快速开始)
- [目录结构总览](#目录结构总览)
- [Agent 角色一览（48 个）](#agent-角色一览48-个)
- [Skill 技能一览（37 个）](#skill-技能一览37-个)
- [命令映射](#命令映射)
- [脚本说明](#脚本说明)
- [模板说明](#模板说明)
- [知识库说明](#知识库说明)
- [规则与安全护栏](#规则与安全护栏)
- [刷新与验证](#刷新与验证)
- [自定义指南](#自定义指南)
- [常见问题（FAQ）](#常见问题faq)

---

## 这是什么

`.codex/` 目录是一个**完全自包含**的 Codex 运行时层。它包含了运行游戏开发工作室所需的一切：

- ✅ 项目级别的 Codex 配置（`config.toml`）
- ✅ 48 个专业角色的完整注册表（Agent）
- ✅ 37 个工作流技能（Skill）
- ✅ 29 个文档模板（Template）
- ✅ 引擎知识库（Godot / Unity / Unreal）
- ✅ 自动化验证和会话管理脚本
- ✅ 执行规则和安全护栏

**核心理念**：你仍然做每一个决定，但你拥有一个会问正确问题、提前发现错误、保持项目组织有序的团队。

---

## 与 Claude Code 版本的关系

| 维度 | Claude Code 版本 (`.claude/`) | Codex 版本 (`.codex/`) |
|------|------|------|
| **运行时** | Anthropic Claude Code CLI | OpenAI Codex CLI |
| **配置格式** | `settings.json` | `config.toml` |
| **Agent 定义** | Markdown + YAML frontmatter (`.md`) | TOML 配置 (`.toml`) + Markdown 角色文档 |
| **Skill 调用** | 斜杠命令 `/skill-name` | 让 Codex 使用 `skill-name` 技能 |
| **Hook** | 原生 hook 系统 | 转换为可执行脚本 (`.codex/scripts/`) |
| **Rule** | `settings.json` 内嵌 | 独立 `.rules` 文件 |
| **模型** | Claude Opus / Sonnet / Haiku | GPT-5.4（统一映射） |

**重要**：运行时只使用 `.codex/` 目录。`.claude/` 目录仅作为生成器的**输入源**存在，不要在运行时依赖它。

---

## 快速开始

### 前置要求

- [Git](https://git-scm.com/)
- [Codex CLI](https://platform.openai.com/docs/codex)（`npm install -g @openai/codex`）
- Python 3（用于生成脚本和测试）
- 推荐：[jq](https://jqlang.github.io/jq/)（用于 JSON 验证）

### 第一步：克隆仓库

```bash
git clone https://github.com/Donchitos/Claude-Code-Game-Studios.git my-game
cd my-game
```

### 第二步：启动 Codex

```bash
codex
```

### 第三步：验证配置已加载

在 Codex 中运行以下命令确认环境正常：

```
/debug-config    ← 检查 config.toml 是否被正确加载
/status          ← 查看当前会话状态
```

### 第四步：开始你的游戏开发

告诉 Codex 使用 `start` 技能：

> "请使用 `start` 技能"

系统会问你当前处于哪个阶段：
- **A) 完全没想法** — 连游戏概念都没有，想从头探索
- **B) 模糊想法** — 有个大概方向（比如"做个太空游戏"），但没具体化
- **C) 明确概念** — 知道要做什么类型的游戏，但还没写文档
- **D) 已有作品** — 已经有设计文档、代码或原型，想继续推进

根据你的回答，系统会推荐下一步使用的技能。

### 典型工作流程

```
start → brainstorm → setup-engine → map-systems → prototype → sprint-plan → 开发循环
```

---

## 目录结构总览

```
.codex/
├── README.md                           ← 你正在看的文件
├── config.toml                         ← 核心配置（模型、Agent、Skill 注册）
├── migration-manifest.toml             ← 迁移清单（记录从 .claude/ 生成的所有文件）
│
├── agents/                             ← 48 个 Agent 的 TOML 配置文件
│   ├── producer.toml                   ← 每个文件定义一个 Agent 的模型和指令路径
│   ├── creative-director.toml
│   ├── gameplay-programmer.toml
│   └── ... (共 48 个)
│
├── docs/
│   ├── project-instructions.md         ← Codex 加载的项目指令（最重要的引导文件）
│   ├── usage.md                        ← 使用概览
│   ├── command-map.md                  ← 命令映射表（Claude → Codex）
│   ├── migration-map.md                ← 迁移策略说明
│   ├── roles/                          ← 48 个 Agent 的详细角色说明文档
│   │   ├── producer.md
│   │   ├── creative-director.md
│   │   └── ... (共 48 个)
│   └── reference/                      ← 原始参考文档（从 .claude/ 迁移）
│       ├── quick-start.md
│       ├── agent-roster.md
│       ├── coding-standards.md
│       ├── hooks-reference.md
│       ├── rules/                      ← 原始 Rule 参考文档
│       └── ...
│
├── skills/                             ← 37 个工作流技能
│   ├── start/SKILL.md                  ← 新手引导
│   ├── brainstorm/SKILL.md             ← 创意头脑风暴
│   ├── sprint-plan/SKILL.md            ← Sprint 计划
│   ├── code-review/SKILL.md            ← 代码审查
│   └── ... (共 37 个)
│
├── templates/                          ← 29 个文档模板
│   ├── game-design-document.md         ← GDD 模板
│   ├── sprint-plan.md                  ← Sprint 计划模板
│   ├── architecture-decision-record.md ← ADR 模板
│   └── ...
│
├── knowledge/                          ← 知识库（引擎参考 + 示例）
│   ├── engine-reference/               ← Godot / Unity / Unreal 引擎参考
│   │   ├── godot/                      ← Godot 4 API、模块、最佳实践
│   │   ├── unity/                      ← Unity API、插件、最佳实践
│   │   └── unreal/                     ← UE5 API、插件、最佳实践
│   └── examples/                       ← 工作流示例会话
│
├── scripts/                            ← 自动化脚本（从 Hook 转换）
│   ├── generate_codex_layer.py         ← 核心：从 .claude/ 重新生成整个 .codex/ 层
│   ├── preflight.sh                    ← 运行所有验证脚本
│   ├── session_start.sh                ← 会话启动时加载上下文
│   ├── validate_commit.sh              ← 提交前验证
│   ├── validate_push.sh                ← 推送前验证
│   ├── validate_assets.sh              ← 资产变更验证
│   ├── detect_gaps.sh                  ← 检测项目缺失部分
│   ├── save_session_context.sh         ← 压缩上下文前保存进度
│   ├── wrap_session.sh                 ← 会话结束时记录成果
│   └── log_agent.sh                    ← Agent 调用审计日志
│
├── rules/
│   └── default.rules                   ← 执行策略规则（允许/禁止的命令）
│
└── tests/
    └── test_generate_codex_layer.py    ← 生成器的单元测试
```

---

## Agent 角色一览（48 个）

Agent 按三层架构组织，模拟真实游戏工作室的运作方式：

### 第 1 层 — 总监级（Director）

决策权最高，负责项目愿景和全局方向。

| Agent | 职责 |
|-------|------|
| `creative-director` | 创意总监 — 游戏愿景、基调、美学方向的最高权威 |
| `technical-director` | 技术总监 — 引擎架构、技术选型、性能策略 |
| `producer` | 制作人 — Sprint 计划、里程碑跟踪、风险管理、跨部门协调 |

### 第 2 层 — 部门主管（Department Lead）

各专业领域的负责人，向总监汇报。

| Agent | 职责 |
|-------|------|
| `game-designer` | 游戏设计 — 核心循环、进度系统、战斗机制、经济设计 |
| `lead-programmer` | 主程序 — 代码架构、编码标准、Code Review |
| `art-director` | 美术总监 — 视觉风格、资产标准、UI/UX 视觉设计 |
| `audio-director` | 音频总监 — 音乐方向、音效设计、混音策略 |
| `narrative-director` | 叙事总监 — 故事架构、世界观、角色设计 |
| `qa-lead` | QA 主管 — 测试策略、Bug 分级、发布质量门禁 |
| `release-manager` | 发布经理 — 认证清单、商店提审、版本管理 |
| `localization-lead` | 本地化主管 — 国际化架构、字符串管理 |

### 第 3 层 — 专家级（Specialist）

执行具体工作，向部门主管汇报。

| Agent | 职责 |
|-------|------|
| `gameplay-programmer` | 玩法程序 — 实现游戏机制和交互功能 |
| `engine-programmer` | 引擎程序 — 渲染管线、物理、内存管理 |
| `ai-programmer` | AI 程序 — 行为树、寻路、NPC 行为 |
| `network-programmer` | 网络程序 — 多人联网、状态同步 |
| `tools-programmer` | 工具程序 — 编辑器扩展、管线自动化 |
| `ui-programmer` | UI 程序 — 菜单、HUD、界面系统 |
| `systems-designer` | 系统设计 — 战斗公式、进度曲线、制作配方 |
| `level-designer` | 关卡设计 — 空间布局、遭遇设计、节奏规划 |
| `economy-designer` | 经济设计 — 资源经济、掉落系统、进度曲线 |
| `technical-artist` | 技术美术 — 着色器、VFX、渲染优化 |
| `sound-designer` | 音效设计 — 音效规格、音频事件、混音文档 |
| `writer` | 文案 — 对话、传说、物品描述 |
| `world-builder` | 世界构建 — 阵营、文化、历史、地理 |
| `ux-designer` | UX 设计 — 用户流程、交互设计、可访问性 |
| `prototyper` | 原型设计 — 快速验证概念的专家 |
| `performance-analyst` | 性能分析 — 性能剖析、瓶颈排查 |
| `devops-engineer` | DevOps — CI/CD 管线、构建脚本 |
| `analytics-engineer` | 数据分析 — 遥测系统、A/B 测试 |
| `security-engineer` | 安全工程 — 反作弊、数据安全 |
| `qa-tester` | QA 测试 — 测试用例、Bug 报告 |
| `accessibility-specialist` | 可访问性专家 — 无障碍标准、辅助功能 |
| `live-ops-designer` | 运营设计 — 赛季活动、战斗通行证 |
| `community-manager` | 社区经理 — 补丁说明、玩家沟通 |

### 引擎专家

| 引擎 | 主专家 | 子专家 |
|------|--------|--------|
| **Godot 4** | `godot-specialist` | `godot-gdscript-specialist`, `godot-shader-specialist`, `godot-gdextension-specialist` |
| **Unity** | `unity-specialist` | `unity-dots-specialist`, `unity-shader-specialist`, `unity-addressables-specialist`, `unity-ui-specialist` |
| **Unreal 5** | `unreal-specialist` | `ue-blueprint-specialist`, `ue-gas-specialist`, `ue-replication-specialist`, `ue-umg-specialist` |

---

## Skill 技能一览（37 个）

在 Codex 中使用技能的方式是告诉 Codex 使用相应的技能名称：

> "请使用 `brainstorm` 技能"
> 
> "帮我做一个 `code-review`"

### 项目管理

| 技能 | 作用 |
|------|------|
| `start` | 新手引导 — 问你在哪个阶段，推荐下一步 |
| `sprint-plan` | 创建 Sprint 计划 |
| `milestone-review` | 里程碑审查 |
| `estimate` | 工作量估算 |
| `retrospective` | Sprint 回顾 |
| `project-stage-detect` | 检测项目当前所处阶段 |
| `scope-check` | 范围检查 — 评估是否超出预算 |
| `gate-check` | 质量门禁检查 |

### 审查与分析

| 技能 | 作用 |
|------|------|
| `code-review` | 代码审查（针对特定文件或子系统） |
| `design-review` | 设计审查 |
| `balance-check` | 平衡性检查 |
| `asset-audit` | 资产审计 |
| `perf-profile` | 性能剖析 |
| `tech-debt` | 技术债务清理 |

### 创意与设计

| 技能 | 作用 |
|------|------|
| `brainstorm` | 创意头脑风暴（使用 MDA 框架等专业方法） |
| `prototype` | 快速原型验证 |
| `design-system` | 设计系统文档编写 |
| `map-systems` | 系统映射 — 分解概念为子系统 |
| `onboard` | 团队成员入职引导 |
| `playtest-report` | 测试报告 |

### 发布

| 技能 | 作用 |
|------|------|
| `release-checklist` | 发布清单 |
| `launch-checklist` | 上线清单 |
| `changelog` | 变更日志 |
| `patch-notes` | 补丁说明 |
| `hotfix` | 热修复流程 |

### 架构与文档

| 技能 | 作用 |
|------|------|
| `architecture-decision` | 架构决策记录（ADR） |
| `reverse-document` | 逆向文档 — 从代码生成文档 |
| `bug-report` | Bug 报告 |
| `setup-engine` | 引擎配置（如 `setup-engine godot 4.6`） |
| `localize` | 本地化 |

### 团队协作（多 Agent 协同）

| 技能 | 作用 |
|------|------|
| `team-combat` | 协调多个 Agent 开发战斗功能 |
| `team-narrative` | 协调多个 Agent 开发叙事内容 |
| `team-ui` | 协调多个 Agent 开发 UI |
| `team-release` | 协调多个 Agent 完成发布 |
| `team-polish` | 协调多个 Agent 打磨细节 |
| `team-audio` | 协调多个 Agent 处理音频 |
| `team-level` | 协调多个 Agent 设计关卡 |

---

## 命令映射

由于 Codex 不会自动导入仓库本地的斜杠命令，原来在 Claude Code 中使用 `/command` 的方式，现在改为告诉 Codex 使用对应的技能。

### 原生 Codex 命令（直接用斜杠）

| 命令 | 说明 |
|------|------|
| `/plan` | 规划模式 |
| `/review` | 整个工作目录的代码审查 |
| `/status` | 查看会话状态 |
| `/debug-config` | 检查配置是否正确加载 |
| `/statusline` | 查看/调整底部状态栏 |

### 迁移的技能（用自然语言触发）

```
Claude Code 命令:  /brainstorm
Codex 等效方式:    "请使用 brainstorm 技能"

Claude Code 命令:  /sprint-plan
Codex 等效方式:    "请使用 sprint-plan 技能"

Claude Code 命令:  /code-review
Codex 等效方式:    "请使用 code-review 技能"
```

其余 37 个技能同理。完整映射表见 `.codex/docs/command-map.md`。

---

## 脚本说明

`.codex/scripts/` 下的脚本对应原始 Claude Code 版本的 Hook 系统：

| 脚本 | 原始 Hook | 作用 |
|------|-----------|------|
| `session_start.sh` | `session-start.sh` | 会话启动时加载 Sprint 上下文和最近 Git 活动 |
| `detect_gaps.sh` | `detect-gaps.sh` | 检测新项目（建议 `/start`）和缺失的文档 |
| `validate_commit.sh` | `validate-commit.sh` | 提交前检查：硬编码值、TODO 格式、JSON 有效性 |
| `validate_push.sh` | `validate-push.sh` | 推送到受保护分支时发出警告 |
| `validate_assets.sh` | `validate-assets.sh` | 验证资产命名规范和 JSON 结构 |
| `save_session_context.sh` | `pre-compact.sh` | 上下文压缩前保存会话进度笔记 |
| `wrap_session.sh` | `session-stop.sh` | 会话结束时记录成果 |
| `log_agent.sh` | `log-agent.sh` | Agent 调用的审计追踪 |
| `preflight.sh` | _(新增)_ | 一键运行所有验证脚本 |
| `generate_codex_layer.py` | _(核心)_ | 从 `.claude/` 重新生成整个 `.codex/` 层 |

### 运行预检

```bash
bash .codex/scripts/preflight.sh
```

---

## 模板说明

`.codex/templates/` 包含 29 个游戏开发文档模板，可直接使用：

| 模板 | 用途 |
|------|------|
| `game-concept.md` | 游戏概念文档 |
| `game-design-document.md` | 游戏设计文档（GDD） |
| `game-pillars.md` | 游戏支柱（核心设计原则） |
| `technical-design-document.md` | 技术设计文档（TDD） |
| `architecture-decision-record.md` | 架构决策记录（ADR） |
| `sprint-plan.md` | Sprint 计划 |
| `milestone-definition.md` | 里程碑定义 |
| `art-bible.md` | 美术圣经 |
| `sound-bible.md` | 音效圣经 |
| `economy-model.md` | 经济模型 |
| `faction-design.md` | 阵营设计 |
| `level-design-document.md` | 关卡设计文档 |
| `narrative-character-sheet.md` | 叙事角色表 |
| `pitch-document.md` | 项目提案 |
| `test-plan.md` | 测试计划 |
| `release-checklist-template.md` | 发布清单 |
| `release-notes.md` | 发布说明 |
| `changelog-template.md` | 变更日志 |
| `post-mortem.md` | 项目复盘 |
| `incident-response.md` | 事件响应 |
| `risk-register-entry.md` | 风险登记 |
| `project-stage-report.md` | 项目阶段报告 |
| `systems-index.md` | 系统索引 |
| `concept-doc-from-prototype.md` | 从原型生成概念文档 |
| `design-doc-from-implementation.md` | 从实现生成设计文档 |
| `architecture-doc-from-code.md` | 从代码生成架构文档 |
| `collaborative-protocols/` | 协作协议模板（设计/实现/领导） |

---

## 知识库说明

`.codex/knowledge/` 包含引擎参考文档和工作流示例：

### 引擎参考 (`engine-reference/`)

每个引擎都包含：
- `VERSION.md` — 当前支持的版本
- `breaking-changes.md` — 重大变更
- `deprecated-apis.md` — 已弃用 API
- `current-best-practices.md` — 当前最佳实践
- `modules/` — 各子系统参考（animation, audio, input, navigation, networking, physics, rendering, ui）
- `plugins/` — 引擎特定插件参考

### 示例 (`examples/`)

- 逆向文档工作流示例
- 设计会话示例（打造系统）
- 实现会话示例（战斗伤害）
- 范围危机决策示例

---

## 规则与安全护栏

### 执行策略规则 (`.codex/rules/default.rules`)

**允许的操作**：
- `git status` — 只读状态查看
- `git diff` — 只读差异查看
- `git log` — 只读历史查看
- `git branch` — 只读分支查看
- `git rev-parse` — 只读版本解析

**禁止的操作**：
- `rm -rf` — 递归删除
- `git push --force` / `git push -f` — 强制推送
- `git reset --hard` — 硬重置
- `git clean -f` — 破坏性清理
- `sudo` — 权限提升
- `chmod 777` — 过度宽松的权限

### 项目指令护栏

- 不要暴露 `.env` 内容或凭据
- 不要在仓库根目录创建 `AGENTS.md`（所有项目指导必须在 `.codex/` 内）
- 不要使用 force-push 或 hard reset 重写历史

---

## 刷新与验证

当 `.claude/` 目录（源材料）或 `docs/` 下的引擎参考文档发生变化时，需要重新生成 `.codex/` 层。

### 重新生成

```bash
python3 .codex/scripts/generate_codex_layer.py
```

这个脚本会：
1. 读取 `.claude/` 下的所有 Agent、Skill、Hook、Rule、Template
2. 将路径引用从 `.claude/` 重写为 `.codex/`
3. 将 Claude Code 特有术语转换为 Codex 等效术语
4. 将 Agent 定义拆分为 TOML 配置 + Markdown 角色文档
5. 将 Hook 脚本转换为独立可执行脚本
6. 生成 `config.toml`、`README.md`、`migration-manifest.toml` 等
7. 更新 `migration-manifest.toml` 记录所有迁移条目

### 验证

```bash
# 运行生成器的单元测试
python3 -m unittest discover -s .codex/tests -p 'test_*.py'

# 验证规则是否正确加载
codex execpolicy check --pretty --rules .codex/rules/default.rules -- git status

# 验证规则是否正确阻止危险操作
codex execpolicy check --pretty --rules .codex/rules/default.rules -- git push --force origin main
```

### 在 Codex 内验证

```
/debug-config    ← 确认 config.toml 已加载
/status          ← 查看会话状态
```

---

## 自定义指南

这是一个**模板**，不是锁定的框架。你可以自定义一切：

### 添加/移除 Agent

- **删除不需要的 Agent**：删除 `.codex/agents/<name>.toml` 和 `.codex/docs/roles/<name>.md`，并从 `config.toml` 中移除对应的 `[agents.<name>]` 配置块
- **添加新 Agent**：创建新的 `.toml` 配置文件和 `.md` 角色文档，在 `config.toml` 中添加配置块

### 修改 Agent 行为

编辑 `.codex/docs/roles/<agent-name>.md` 来调整 Agent 的行为指令、专业知识和工作协议。

### 调整 Skill

编辑 `.codex/skills/<skill-name>/SKILL.md` 来修改工作流步骤。

### 选择引擎

仓库包含 Godot 4、Unity 和 Unreal Engine 5 三套引擎专家。你只需要保留匹配你项目引擎的那套，可以删除其他两套的 Agent。

### 添加执行规则

编辑 `.codex/rules/default.rules` 添加新的允许或禁止规则。

---

## 常见问题（FAQ）

### Q：我是第一次用，应该从哪里开始？

启动 Codex，使用 `start` 技能。系统会根据你的情况引导你。

### Q：Agent 会自动运行吗？会不会改了我不想改的东西？

**不会**。这是**协作式**系统，不是自动驾驶。每个 Agent 都遵循严格的协作协议：
1. **先问** — 不假设你的意图
2. **给选项** — 展示 2-4 个方案及优缺点
3. **你决定** — 用户永远做最终决策
4. **先草稿** — 展示工作内容再确认
5. **你批准** — 没有你的同意什么都不会写入

### Q：我能只用部分 Agent 吗？

当然可以。删掉 `config.toml` 中不需要的 `[agents.*]` 配置块即可。

### Q：`config.toml` 中的 `approval_policy = "never"` 是什么意思？

这意味着 Codex 在执行操作前不需要你逐个批准每个命令。这是生成器的默认设置，你可以改为 `"on-request"` 或 `"always"` 来增加控制。

### Q：`.claude/` 和 `.codex/` 都存在时，用哪个？

**只用 `.codex/`**。`.claude/` 仅作为生成器的输入源。如果修改了 `.claude/` 中的内容，需要重新运行 `generate_codex_layer.py` 来同步到 `.codex/`。

### Q：如何更新到新版本？

参考仓库根目录的 [UPGRADING.md](../UPGRADING.md) 获取版本迁移指南。

### Q：脚本运行报错怎么办？

所有脚本都采用优雅降级设计 — 缺少可选工具（如 `jq`）时不会崩溃，只是跳过相应的验证检查。

---

## 技术细节

### 配置文件结构 (`config.toml`)

```toml
# 模型配置
model = "gpt-5.4"
model_reasoning_effort = "xhigh"
model_instructions_file = ".codex/docs/project-instructions.md"

# 功能开关
[features]
multi_agent = true        # 启用多 Agent 协作
unified_exec = true       # 统一执行模式
shell_snapshot = true     # Shell 快照

# Agent 线程配置
[agents]
max_threads = 6           # 最大并行 Agent 数
max_depth = 2             # Agent 嵌套深度
job_max_runtime_seconds = 1800  # 单个 Agent 最长运行时间 (30 分钟)
```

### Agent TOML 配置格式

```toml
model = "gpt-5.4"
model_reasoning_effort = "xhigh"
model_instructions_file = "../docs/roles/<agent-name>.md"
```

### Skill YAML Frontmatter 格式

```yaml
---
name: skill-name
description: "技能描述"
---

# SKILL.md 主体内容...
```

---

*本文档随项目更新持续维护。如有疑问，请提交 [Issue](https://github.com/Donchitos/Claude-Code-Game-Studios/issues)。*
