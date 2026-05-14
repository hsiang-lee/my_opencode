# CREATIVE & Debug 工作流 Agent 系统

> 为 OpenCode 设计的双主 Agent 工作流系统

## 概述

**2 个 Primary Agent，各一个固定工作流，用户 Tab 切换选择。**

 - **Creative** — 新功能开发强制流程：设计 → 文档 → 计划 → 评审 → 实现 → 审查 → 收尾
- **Debug** — Bug 修复强制流程：复现 → 根因调查 → TDD修复 → 审查 → 收尾

**核心设计：Agent 不做意图判断，用户选择走哪个流程。**

## 架构

```
Tab 切换:

  Creative (新功能)       Debug (Bug修复)        build (灵活开发)     plan (只读分析)
  强制 CREATIVE 流程      强制 DEBUG 流程         日常编码             代码阅读
```

### 共享 Subagent

| Agent | 功能 | 模型 |
|-------|------|------|
| brainstorm | 交互式设计探索 | deepseek/deepseek-v4-flash |
| spec-writer | 设计文档编写 | deepseek/deepseek-v4-pro |
| plan-writer | 实现计划编写 | deepseek/deepseek-v4-pro |
| plan-executor | TDD 计划执行 + 防假测试 | deepseek/deepseek-v4-flash |
| code-reviewer | 代码审查 + 假测试检测 | deepseek/deepseek-v4-pro |
| branch-finisher | 分支收尾 | deepseek/deepseek-v4-flash |
| explore | 代码库搜索 | deepseek/deepseek-v4-flash |
| librarian | 外部研究 | deepseek/deepseek-v4-flash |
| metis | 预规划分析 | deepseek/deepseek-v4-pro |
| momus | 计划评审 | deepseek/deepseek-v4-pro |
| oracle | 战略咨询 | deepseek/deepseek-v4-pro |

### Skill

| Skill | 消费者 | 内容 |
|-------|-------|------|
| brainstorm | CREATIVE Step 1 | 设计探索方法：提问澄清、方案提出、展示设计、对比框架 |
| tdd | plan-writer, plan-executor | TDD RED-GREEN-REFACTOR + 单元测试技术 + 防假测试 |
| refactoring | plan-executor | REFACTOR 阶段坏味道检测与重构执行流程 |
| using-git-worktrees | CREATIVE/Debug, branch-finisher | Git Worktree 管理 |
| gdb | plan-executor (可选) | C/C++ 运行时调试：崩溃分析、变量检查、内存调试 |
| init-deep | - | 层级 AGENTS.md 文件生成与维护 |
| gh-pr | branch-finisher | GitHub Pull Request 创建与管理 |
| glab | - | GitLab CLI (glab 命令) |
| issue-master | - | 需求拆分与 Issue 创建 |
| writing-skills | - | Skill 编写方法论 |
| qnx | - | QNX 目标系统连接与部署 |
| vcpkg | - | vcpkg 包管理：CMakePresets 集成、自定义端口/Registry、依赖管理 |
| mull | - | Mull mutation testing 工具 |

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

在现有 `~/.config/opencode/AGENTS.md` 中更新 Agent 使用指南：

```markdown
| **CREATIVE** | 新功能开发强制流程 | 新功能开发，Tab 切换到 Creative |
| **Debug** | Bug修复强制流程 | Bug 修复，Tab 切换到 Debug |
```

### 4. 配置模型 (可选)

```json
{
  "agent": {
    "plan-executor": {
      "model": "deepseek/deepseek-v4-flash"
    }
  }
}
```

## 使用

### Creative (新功能开发)

1. Tab 切换到 Creative
2. 描述你要做的功能
3. CREATIVE 自动走 7 步流程，每一步不可跳过

### Debug (Bug 修复)

1. Tab 切换到 Debug
2. 描述 bug 和复现步骤
3. Debug 自动走 5 步流程，先找根因再修复

### build / plan (日常开发)

- build: 灵活编码，小改动和探索
- plan: 只读分析，阅读和规划

## 文件结构

```
~/.config/opencode/
├── agents/
│   ├── Creative.md      # Primary: 新功能 CREATIVE 流程
│   ├── Debug.md         # Primary: Bug DEBUG 流程
│   ├── brainstorm.md    # Subagent: 交互式设计探索
│   ├── spec-writer.md   # Subagent: 设计文档编写
│   ├── plan-writer.md   # Subagent: 实现计划编写
│   ├── plan-executor.md # Subagent: TDD 计划执行
│   ├── code-reviewer.md # Subagent: 代码审查 + 假测试检测
│   ├── branch-finisher.md # Subagent: 分支收尾
│   ├── explore.md       # Subagent: 代码库搜索
│   ├── librarian.md     # Subagent: 外部研究
│   ├── metis.md         # Subagent: 预规划分析
│   ├── momus.md         # Subagent: 计划评审
│   └── oracle.md        # Subagent: 战略咨询
├── skills/
│   ├── brainstorm/SKILL.md
│   ├── tdd/SKILL.md
│   ├── refactoring/SKILL.md
│   ├── using-git-worktrees/SKILL.md
│   ├── gdb/SKILL.md
│   ├── init-deep/SKILL.md
│   ├── gh-pr/SKILL.md
│   ├── glab/SKILL.md
│   ├── issue-master/SKILL.md
│   ├── mull/SKILL.md
│   ├── mull/mull.yml
│   ├── qnx/SKILL.md
│   ├── vcpkg/SKILL.md
│   └── writing-skills/SKILL.md
└── AGENTS.md           # Agent 使用指南
```
