# Feature / Fix / Legacy / Refactor / QA-Explorer — OpenCode 代码工作流系统

> 为 OpenCode 设计的五场景工作流 Agent 系统：先判场景，再判档位，纪律不随规模下降。

## 概述

**5 个 Primary Agent，用户 Tab 切换选择。**

- **Feature** — 行为变更：设计 → 用户故事 → 评审 → TDD → 审查 → 收尾（6 步，分轻量/精简/完整档）
- **Fix** — bug：复现 → 根因 → 覆盖分叉 → 修复 → 审查 → 收尾（5 步，不设档位）
- **Legacy** — 无测试代码：L0 侦察 → L1 改法拍板 → L2 安全网 → L3 主循环 → L4 出清 → 审查 → 收尾
- **Refactor** — 行为保持型重构：基线 → 计划 → 评审 → 分批执行 → 审查 → 收尾（轻量档跳过计划）
- **QA-Explorer** — 前端探索测试：生成/执行用例，产出证据化 finding 报告（只报告，不修复）

**核心设计：Agent 不做意图猜测，用户选场景；档位由机械阈值判定，不凭感觉。**

## 场景判定

| 顺序 | 判据 | 场景 |
|------|------|------|
| 1 | 行为与预期不符（bug），有或可构造复现路径 | Fix |
| 2 | 要改的代码无测试 / 难有可靠测试 | Legacy |
| 3 | 行为不变，只改结构或模式，基线全绿 | Refactor |
| 4 | 新增/变更行为，且目标可写测试 | Feature |
| 5 | 前端探索测试 | QA-Explorer |

### 档位（Feature / Refactor 入口）

**Feature**（行为变更）

| 档位 | 判据 | 效果 |
|------|------|------|
| 轻量档 | ≤2 文件且 ≤50 行且不改公共接口 | 跳过设计与故事，保留 TDD、审查、收尾 |
| 精简档 | 3-8 文件且无新增模块/公共接口/数据模型 | 跳过 momus，其余照走 |
| 完整档 | >8 文件，或新增模块/公共接口/数据结构/并发/权限/迁移 | 走满全流程 |

**Refactor**（行为保持）

| 档位 | 判据 | 效果 |
|------|------|------|
| 轻量档 | 单一坏味道且 ≤2 文件 | 跳过 planner 与 momus，直接执行、审查、收尾 |
| 完整档 | 多处坏味道 / 跨模块 / 涉及模式引入 | planner → momus → 分批执行 → 审查 → 收尾 |

## 架构

```
Tab 切换:

  Fix (bug)     Legacy (无测试)     Refactor (结构)     Feature (行为)      QA-Explorer
  5 步          L0-L4 + 审查收尾    5 步 / 轻量3步      6 步 / 精简5步 / 轻量3步  探索测试
     │               │                   │                  │                  │
     └───────────────┴───────── shared subagents ──────────┴──────────────────┘
```

### 共享 Subagent

| Agent | 功能 |
|-------|------|
| story-writer | 用户故事：Epic 契约 + [story]/[enabler] + AC + 批次标注，不写结构设计 |
| story-executor | 有测试路径的逐故事 TDD + 批次单 commit；无测试路径报 BLOCKED |
| legacy-analyst | L0 侦察：change points / effect sketch / 测试盘点 / 改法建议（只读） |
| legacy-executor | L1-L4：安全网、两顶帽子主循环、出清；结构与语义分 commit |
| refactor-planner | 坏味道诊断（按阈值分类）+ 分步重构计划 + 批次 |
| refactor-executor | 行为保持型分批执行 + REFACTOR_LEDGER |
| code-reviewer | 按 profile（feature/legacy/refactor）审查：假测试 + 坏味道 + 专项检查 |
| branch-finisher | 分支收尾 |
| explore / librarian | 代码库搜索 / 外部研究 |
| metis / momus | 场景与档位预判 / 计划与故事评审（含 AC 映射与契约完整性） |
| oracle | 战略咨询 |

所有 agent 模型统一通过 `opencode.json` 或各文件 frontmatter 配置。

### Skill

| Skill | 消费者 | 内容 |
|-------|--------|------|
| brainstorm | Feature Step 1（唯一加载方） | 设计探索：提问澄清、方案对比、决策清单输出（契约 + 关键选择，不含结构设计） |
| design | Feature Step 1, code-reviewer, story-executor, refactor-planner, refactor-executor | 索引层（决策顺序 / YAGNI 闸门 / 自检）+ references/（GRASP 9、SOLID+包原则、DbC、GoF 23、分析模型 UML）按需读 |
| testing-techniques | story-executor, code-reviewer, legacy-executor, refactor-executor, refactor-planner | 索引层（四属性 / 假测试闸门 / 坏味道判级）+ references/（测试结构、替身、夹具、坏味道全集）按需读 |
| refactoring | story-executor, code-reviewer, refactor-executor, legacy-analyst, legacy-executor, refactor-planner | 小步行为保持：阈值/台账/红线 + references/（坏味道 24 类 + A1-A7、手法、流程、台账、Clean Code） |
| legacy-code | legacy-analyst, legacy-executor, code-reviewer | 遗留代码 L0-L4 节奏 + 7 参数 + 3 红线 + references/（接缝与特征测试、24 种解依赖、Sprout/Wrap） |
| refactoring-to-patterns | refactor-planner, refactor-executor, code-reviewer | 坏味道→模式：YAGNI 三问 + TO/TOWARDS/AWAY + references/（模式导向重构、演化链、评审表） |
| functional | code-reviewer, story-executor | 索引层（范式选型 / 反 FP 闸门 / 评审 16 项）+ references/（构建块 C++&Rust、FP↔OO、错误处理、性能）按需读 |
| gdb | Fix（根因是崩溃 / 内存破坏时） | GDB 调试：崩溃分析、运行时变量、core dump |
| init-deep / gh-pr / glab / issue-master / writing-skills / qnx / vcpkg / mull | 按需 | 见各自 SKILL.md |

### 新旧对照

| 旧 | 新 |
|----|----|
| Forge | Feature |
| Trace | Fix |
| Patch | Feature / Refactor 轻量档（小改下沉为档位） |

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

Tab 切到 Fix，给出复现步骤。根因调查后判定覆盖：有测试 → story-executor；无测试 → legacy-analyst 出 L0 → legacy-executor 走 L1-L4。

### Legacy (无测试代码)

要改的代码没有可靠测试时切到 Legacy。L0 侦察后拍板改法：Sprout/Wrap 降级到 Feature 轻量档；Direct Edit 继续走 L2-L4。

### Refactor (行为保持)

基线测试必须全绿。单一坏味道且 ≤2 文件走轻量档（跳过 planner），否则 planner 出计划、momus 评审、refactor-executor 分批执行。

### Feature (行为变更)

Tab 切到 Feature，描述功能。入口先定档位：轻量档跳过设计/故事/评审，精简档跳过 momus，完整档走满 6 步。

### QA-Explorer (前端探索测试)

提供目标 URL 与环境名称（必须非生产）。产出写入 `docs/qa/`。

## 文件结构

```
~/.config/opencode/
├── agents/
│   ├── Feature.md        # Primary: 行为变更（轻量/精简/完整档）
│   ├── Fix.md            # Primary: bug 修复
│   ├── Legacy.md         # Primary: 无测试代码
│   ├── Refactor.md       # Primary: 行为保持型重构
│   ├── QA-Explorer.md    # Primary: 前端探索测试
│   ├── story-writer.md
│   ├── story-executor.md
│   ├── legacy-analyst.md
│   ├── legacy-executor.md
│   ├── refactor-planner.md
│   ├── refactor-executor.md
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
│   ├── refactoring/SKILL.md + references/*.md
│   ├── legacy-code/SKILL.md + references/*.md
│   ├── refactoring-to-patterns/SKILL.md + references/*.md
│   ├── testing-techniques/SKILL.md + references/*.md
│   ├── functional/SKILL.md + references/*.md
│   └── ...（gdb / init-deep / gh-pr / glab / issue-master / mull / qnx / vcpkg / writing-skills）
└── AGENTS.md
```

### 项目内产物

| 路径 | 产出者 | 内容 |
|------|--------|------|
| `docs/stories/YYYY-MM-DD-<epic>.md` | story-writer | Epic 契约表 + `[story]` / `[enabler]` 故事清单 + 批次标注 |
| `docs/plans/*.md` | refactor-planner | 坏味道清单 + 分步重构计划 + 批次 |
| `docs/qa/`、`docs/qa-findings/` | QA-Explorer | 用例表与探索结果 |
| `docs/debt-ledger.md` | story-executor / legacy-executor / refactor-executor | 技术债登记，按文件集重叠并入批次 |
