# Patch / Forge / Trace — OpenCode 代码工作流系统

> 为 OpenCode 设计的三档工作流 Agent 系统：按变更规模选档位，纪律不随规模下降。

## 概述

**3 个代码工作流 Primary Agent + 1 个 QA Agent，用户 Tab 切换选择。**

- **Patch** — 小改：≤2 文件且 ≤50 行且不改公共接口 → 理解 → TDD → 审查 → 收尾（4 步）
- **Forge** — feature：设计 → 用户故事 → 评审 → 实现 → 审查 → 收尾（6 步，分精简/完整档）
- **Trace** — bug：复现 → 根因 → 测试覆盖分叉 → TDD 修复 → 审查 → 收尾（5 步）
- **QA-Explorer** — 前端探索测试：生成/执行用例，产出证据化 finding 报告（只报告，不修复）

**核心设计：Agent 不做意图猜测，用户选流程；档位由机械阈值判定，不凭感觉。**

## 变更分级

| 条件 | 去向 |
|------|------|
| 文件 ≤2 且改动 ≤50 行 且不改公共接口 | Patch |
| 文件 3-8 且无新增模块/公共接口/数据模型 | Forge 精简档（跳过 momus 评审） |
| 文件 >8，或新增模块/公共接口/数据结构/并发/权限/迁移 | Forge 完整档 |
| 行为与预期不符 | Trace |

## 架构

```
Tab 切换:

  Patch (小改)      Forge (feature)      Trace (bug)       QA-Explorer (前端)
  4 步              6 步 / 精简5步        5 步              探索测试
```

### 共享 Subagent

| Agent | 功能 |
|-------|------|
| story-writer | 用户故事：Epic 契约 + [story]/[enabler] + AC + 批次标注，不写结构设计 |
| story-executor | 逐故事 TDD（循环定义在 agent 正文）+ 特征测试门槛 + 批次单 commit |
| code-reviewer | 假测试 + 测试坏味道 + 设计审计 + Clean Code 审查 |
| branch-finisher | 分支收尾 |
| explore / librarian | 代码库搜索 / 外部研究 |
| metis / momus | 预规划分析 / 故事评审（含 AC 映射与契约完整性） |
| oracle | 战略咨询 |

所有 agent 模型统一通过 `opencode.json` 或各文件 frontmatter 配置。

### Skill

| Skill | 消费者 | 内容 |
|-------|--------|------|
| brainstorm | Forge Step 1（唯一加载方） | 设计探索：提问澄清、方案对比、决策清单输出（契约 + 关键选择，不含结构设计） |
| design | code-reviewer, story-executor（brainstorm 仅在用户明确要求选模式时例外） | 索引层（决策顺序 / YAGNI 闸门 / 自检）+ references/（GRASP 9、SOLID+包原则、DbC 精确语义、GoF 23）按需读 |
| testing-techniques | story-executor, code-reviewer | 索引层（四属性 / 假测试闸门 / 坏味道判级）+ references/（测试结构、替身、夹具、坏味道全集）按需读 |
| refactoring | story-executor, code-reviewer | 索引层（阈值/台账/红线）+ references/（坏味道 24 类 + A1-A7、手法、重构到模式、遗留代码接缝/解依赖、流程、台账、Clean Code）按需读 |
| functional | code-reviewer, story-executor | 索引层（范式选型 / 反 FP 闸门 / 评审 16 项）+ references/（构建块 C++&Rust、FP↔OO、错误处理、性能）按需读 |
| gdb | Trace（根因调查 / 崩溃复现时） | GDB 调试：崩溃分析、运行时变量、core dump |
| init-deep / gh-pr / glab / issue-master / writing-skills / qnx / vcpkg / mull | 按需 | 见各自 SKILL.md |

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

### Patch (小改)

Tab 切到 Patch，描述改动。Step 1 判定超界会直接让你切 Forge/Trace，不会「先做一点看看」。

### Forge (feature)

Tab 切到 Forge，描述功能。Forge 先定档位：精简档跳过 momus，完整档走满 6 步。

### Trace (bug)

Tab 切到 Trace，给出复现步骤。Trace 在根因调查后判定测试覆盖：有测试走 TDD，无测试先写特征测试再改。

### QA-Explorer (前端探索测试)

提供目标 URL 与环境名称（必须非生产）。产出写入 `docs/qa/`。

## 文件结构

```
~/.config/opencode/
├── agents/
│   ├── Patch.md          # Primary: 小改
│   ├── Forge.md          # Primary: feature（精简/完整档）
│   ├── Trace.md          # Primary: bug
│   ├── QA-Explorer.md    # Primary: 前端探索测试
│   ├── story-writer.md
│   ├── story-executor.md
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
│   ├── testing-techniques/SKILL.md + references/*.md
│   ├── functional/SKILL.md + references/*.md
│   └── ...（gdb / init-deep / gh-pr / glab / issue-master / mull / qnx / vcpkg / writing-skills）
└── AGENTS.md
```

### 项目内产物

| 路径 | 产出者 | 内容 |
|------|--------|------|
| `docs/stories/YYYY-MM-DD-<epic>.md` | story-writer | Epic 契约表 + `[story]` / `[enabler]` 故事清单 + 批次标注 |
| `docs/qa/`、`docs/qa-findings/` | QA-Explorer | 用例表与探索结果 |
| `docs/debt-ledger.md` | Patch / story-writer | 技术债登记，按文件集重叠并入批次 |
