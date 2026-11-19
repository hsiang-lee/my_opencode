# Feature / Fix / QAExplorer — OpenCode 代码工作流系统

> 为 OpenCode 设计的三场景工作流 Agent 系统：先判场景，再判档位，纪律不随规模下降。

## 概述

**3 个 Primary Agent，用户 Tab 切换选择。**

- **Feature** — 行为变更：设计 → 用户故事 → 评审 → TDD → 审查 → 收尾（6 步，分轻量/精简/完整档）
- **Fix** — bug：复现 → 根因 → 覆盖分叉 → 修复 → 审查 → 收尾（5 步，不设档位）
- **QAExplorer** — 前端探索测试：生成/执行用例，产出证据化 finding 报告（只报告，不修复）

**核心设计：Agent 不做意图猜测，用户选场景；档位由机械阈值判定，不凭感觉；无测试不是独立场景：Feature/Fix 自己补安全网。**

## 场景判定

| 顺序 | 判据 | 场景 |
|------|------|------|
| 1 | 行为与预期不符（bug），有或可构造复现路径 | Fix |
| 2 | 新增/变更行为 | Feature |
| 3 | 前端探索测试 | QAExplorer |

### 档位（Feature 入口）

**Feature**（行为变更）

| 档位 | 判据 | 效果 |
|------|------|------|
| 轻量档 | ≤2 文件且 ≤50 行且不改公共接口 | 跳过设计与故事，保留 TDD、审查、收尾 |
| 精简档 | 3-8 文件且无新增模块/公共接口/数据模型 | 跳过 momus，其余照走 |
| 完整档 | >8 文件，或新增模块/公共接口/数据结构/并发/权限/迁移 | 走满全流程 |

## 架构

```
Tab 切换:

  Fix (bug)        Feature (行为)                   QAExplorer
  5 步             6 步 / 精简5步 / 轻量3步          探索测试
     │                    │                            │
     └────────────────────┴──── shared subagents ──────┘
```

### 共享 Subagent

| Agent | 功能 |
|-------|------|
| story-writer | 用户故事：Epic 契约 + [story]/[enabler] + AC + 批次标注，不写结构设计 |
| story-executor | 逐故事 TDD + 批末三 scout 扫描 → refactor + 批次单 commit；既有遗留代码缺覆盖时自己补安全网（能直接写测试就直接补；难测才用 legacy-code） |
| refactor | 按 scout 清单逐项重构：查 refactoring 手法、先补测试覆盖、检查点节奏验证、红即回滚 |
| smell-scout / pattern-scout / test-smell-scout | 坏味道扫描（Fowler 24 / 模式 12 / 测试 13），只报告位置与证据，不改代码 |
| code-reviewer | 按批次 SHA 区间审查：假测试 + 设计审计 + 清洁度（不含坏味道） |
| branch-finisher | 分支收尾 |
| explore / librarian | 代码库搜索 / 外部研究 |
| metis / momus | 场景与档位预判 / 故事评审（含 AC 映射与契约完整性） |
| oracle | 战略咨询 |

所有 agent 模型统一通过 `opencode.json` 或各文件 frontmatter 配置。

### Skill

| Skill | 消费者 | 内容 |
|-------|--------|------|
| brainstorm | Feature Step 1（唯一加载方） | 设计探索：开放提问 + 复述确认、方案对比、决策清单输出（契约 + 关键选择，不含结构设计）；完整档定稿前做 Builder Check |
| design | Feature Step 1, code-reviewer, story-executor | 索引层（决策顺序 / YAGNI 闸门 / 自检）+ references/（GRASP 9、SOLID+包原则、DbC、GoF 23、分析模型 UML）按需读 |
| testing-techniques | story-executor, code-reviewer | 单文件：假测试判级表 + 四属性 + AAA/命名/边界/参数化 + 替身 + 夹具 |
| refactoring | story-executor, Feature, Fix | 坏味道 → 重构手法映射（Fowler 24 / 模式 12 / 测试 13），每个手法带一句要点 |
| legacy-code | code-reviewer, Feature/Fix/story-executor（难测时条件加载） | 遗留代码补测试：找接缝 → 解依赖 → 写特征测试，再改行为（单文件） |
| reporting | Feature, Fix, QAExplorer, branch-finisher | 面向人类的汇报/请示：结论先行、决策前置、不填空模板；禁止转发子 agent 内部报告 |
| functional | code-reviewer, story-executor | 索引层（范式选型 / 反 FP 闸门 / 评审 16 项）+ references/（构建块 C++&Rust、FP↔OO、错误处理、性能）按需读 |
| gdb | Fix（根因是崩溃 / 内存破坏时） | GDB 调试：崩溃分析、运行时变量、core dump |
| init-deep / gh-pr / glab / issue-master / writing-skills / qnx / vcpkg / mull | 按需 | 见各自 SKILL.md |

### 新旧对照

| 旧 | 新 |
|----|----|
| Forge | Feature |
| Trace | Fix |
| Patch | Feature 轻量档（小改下沉为档位） |

## 安装

### 1. 安装 Agent 文件

```bash
cp agents/*.md ~/.config/opencode/agents/
```

### 2. 安装 Skill 文件

```bash
cp -r skills/* ~/.config/opencode/skills/
```

### 3. 更新 AGENTS.md

把本仓库的 `AGENTS.md` 合并进 `~/.config/opencode/AGENTS.md`。

### 4. 生效

重启 OpenCode 或新开会话。

## 使用

### Fix (bug)

Tab 切到 Fix，给出复现步骤。根因调查后判定覆盖：有测试 → story-executor 按 TDD 修复；无测试 → Fix 自己补安全网（能直接写测试就直接补；难测才用 legacy-code：接缝 → 解依赖 → 写特征测试），补完继续 TDD 修复。

### Feature (行为变更)

Tab 切到 Feature，描述功能。入口先定档位：轻量档跳过设计/故事/评审，精简档跳过 momus，完整档走满 6 步。

### QAExplorer (前端探索测试)

提供目标 URL 与环境名称（必须非生产）。产出写入 `docs/qa/`。

## 文件结构

```
~/.config/opencode/
├── agents/
│   ├── Feature.md        # Primary: 行为变更（轻量/精简/完整档）
│   ├── Fix.md            # Primary: bug 修复
│   ├── QAExplorer.md    # Primary: 前端探索测试
│   ├── story-writer.md
│   ├── story-executor.md
│   ├── smell-scout.md
│   ├── pattern-scout.md
│   ├── test-smell-scout.md
│   ├── refactor.md
│   ├── code-reviewer.md
│   ├── branch-finisher.md
│   ├── explore.md
│   ├── librarian.md
│   ├── metis.md
│   ├── momus.md
│   └── oracle.md
├── skills/
│   ├── brainstorm/SKILL.md
│   ├── design/SKILL.md + references/*.md
│   ├── legacy-code/SKILL.md
│   ├── testing-techniques/SKILL.md
│   ├── reporting/SKILL.md
│   ├── functional/SKILL.md + references/*.md
│   └── ...（gdb / init-deep / gh-pr / glab / issue-master / mull / qnx / vcpkg / writing-skills）
└── AGENTS.md
```

### 项目内产物

| 路径 | 产出者 | 内容 |
|------|--------|------|
| `docs/stories/YYYY-MM-DD-<epic>.md` | story-writer | Epic 契约表 + `[story]` / `[enabler]` 故事清单 + 批次标注 |
| `docs/qa/`、`docs/qa-findings/` | QAExplorer | 用例表与探索结果 |
