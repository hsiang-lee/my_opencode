---
name: init-deep
description: Generate and maintain hierarchical AGENTS.md files for projects. Analyzes project structure, scores directories by complexity, and generates context files at appropriate levels. Supports update and create-new modes.
---

# Init-Deep — 项目结构文档生成与维护

生成层级化 AGENTS.md 文件。根目录 + 按复杂度评分的子目录。

## 使用方式

```
/init-deep                      # 更新模式：修改已有 + 在需要处新建
/init-deep --create-new         # 重写模式：读取已有 → 全部删除 → 从零生成
/init-deep --max-depth=2        # 限制目录深度（默认: 3）
```

---

## 工作流概览

1. **发现 + 分析**（并行）
   - 立即启动后台 explore agents
   - 主会话：bash 结构分析 + LSP codemap + 读取已有 AGENTS.md
2. **评分与决策** — 根据综合分析确定 AGENTS.md 位置
3. **生成** — 先写根目录，再并行写子目录
4. **审查** — 去重、精简、验证

<critical>
**TodoWrite 记录所有阶段。实时标记 in_progress → completed。**
```
TodoWrite([
  { id: "discovery", content: "启动 explore agents + LSP codemap + 读取已有文件", status: "pending", priority: "high" },
  { id: "scoring", content: "评分目录，确定生成位置", status: "pending", priority: "high" },
  { id: "generate", content: "生成 AGENTS.md 文件（根目录 + 子目录）", status: "pending", priority: "high" },
  { id: "review", content: "去重、验证、精简", status: "pending", priority: "medium" }
])
```
</critical>

---

## Phase 1: 发现与分析（并行）

**标记 "discovery" 为 in_progress。**

### 立即启动后台 Explore Agents

不要等 — 这些在后台异步运行，主会话同时进行其他工作。

```
// 一次全部启动
Task(explore, "探索项目结构", "项目结构: 预测标准模式 → 只报告偏差")
Task(explore, "查找入口点", "入口点: 找到 main 文件 → 报告非标准组织方式")
Task(explore, "查找约定", "约定: 找到配置文件 → 报告项目特有规则")
Task(explore, "查找反模式", "反模式: 找到 DO NOT / NEVER / ALWAYS / DEPRECATED 注释 → 列出禁止的模式")
Task(explore, "探索构建/CI", "构建/CI: 找到 CI 配置、Makefile → 报告非标准模式")
Task(explore, "查找测试模式", "测试模式: 找到测试配置和结构 → 报告特有约定")
```

<dynamic-agents>
**动态 Agent 生成**: bash 分析后，根据项目规模额外生成 explore agents：

| 因素 | 阈值 | 额外 agents |
|------|------|------------|
| **文件总数** | >100 | 每 100 个文件 +1 |
| **总行数** | >10k | 每 10k 行 +1 |
| **目录深度** | >=4 | +2 深度探索 |
| **大文件 (>500 行)** | >10 个 | +1 复杂度热点 |
| **Monorepo** | 检测到 | 每个包/工作区 +1 |
| **多语言** | >1 | 每种语言 +1 |

```bash
# 先测量项目规模
total_files=$(find . -type f -not -path '*/node_modules/*' -not -path '*/.git/*' | wc -l)
total_lines=$(find . -type f \( -name "*.ts" -o -name "*.py" -o -name "*.go" \) -not -path '*/node_modules/*' -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}')
large_files=$(find . -type f \( -name "*.ts" -o -name "*.py" \) -not -path '*/node_modules/*' -exec wc -l {} + 2>/dev/null | awk '$1 > 500 {count++} END {print count+0}')
max_depth=$(find . -type d -not -path '*/node_modules/*' -not -path '*/.git/*' | awk -F/ '{print NF}' | sort -rn | head -1)
```
</dynamic-agents>

### 主会话：并行分析

**后台 agents 运行时**，主会话执行：

#### 1. Bash 结构分析

```bash
# 目录深度 + 文件数
find . -type d -not -path '*/\.*' -not -path '*/node_modules/*' -not -path '*/venv/*' -not -path '*/dist/*' -not -path '*/build/*' | awk -F/ '{print NF-1}' | sort -n | uniq -c

# 每个目录的文件数（top 30）
find . -type f -not -path '*/\.*' -not -path '*/node_modules/*' | sed 's|/[^/]*$||' | sort | uniq -c | sort -rn | head -30

# 按扩展名的代码集中度
find . -type f \( -name "*.py" -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.go" -o -name "*.rs" \) -not -path '*/node_modules/*' | sed 's|/[^/]*$||' | sort | uniq -c | sort -rn | head -20

# 已有 AGENTS.md / CLAUDE.md
find . -type f \( -name "AGENTS.md" -o -name "CLAUDE.md" \) -not -path '*/node_modules/*' 2>/dev/null
```

#### 2. 读取已有 AGENTS.md

```
对于每个已有文件:
  Read(filePath=file)
  提取: 关键信息、约定、反模式
  存入 EXISTING_AGENTS 映射
```

如果是 `--create-new`：先全部读取（保留上下文）→ 再全部删除 → 重新生成。

#### 3. LSP Codemap（如果有）

```
LspServers()  # 检查可用性

# 入口点（并行）
LspDocumentSymbols(filePath="src/index.ts")
LspDocumentSymbols(filePath="main.py")

# 关键符号（并行）
LspWorkspaceSymbols(filePath=".", query="class")
LspWorkspaceSymbols(filePath=".", query="interface")
LspWorkspaceSymbols(filePath=".", query="function")

# 关键导出的引用的集中度
LspFindReferences(filePath="...", line=X, character=Y)
```

**LSP 不可用时**：回退到 explore agents + AST-grep。

### 收集后台结果

```
// 主会话分析完成后，收集所有 task 结果
for each task_id: background_output(task_id="...")
```

**合并：bash + LSP + 已有 + explore 发现。标记 "discovery" 为 completed。**

---

## Phase 2: 评分与位置决策

**标记 "scoring" 为 in_progress。**

### 评分矩阵

| 因素 | 权重 | 高阈值 | 来源 |
|------|------|--------|------|
| 文件数 | 3x | >20 | bash |
| 子目录数 | 2x | >5 | bash |
| 代码比例 | 2x | >70% | bash |
| 特有模式 | 1x | 有自己的配置 | explore |
| 模块边界 | 2x | 有 index.ts/__init__.py | bash |
| 符号密度 | 2x | >30 符号 | LSP |
| 导出数 | 2x | >10 导出 | LSP |
| 引用集中度 | 3x | >20 引用 | LSP |

### 决策规则

| 分数 | 动作 |
|------|------|
| **根目录 (.)** | 始终创建 |
| **>15** | 创建 AGENTS.md |
| **8-15** | 如果是独立领域则创建 |
| **<8** | 跳过（父级覆盖） |

### 输出

```
AGENTS_LOCATIONS = [
  { path: ".", type: "root" },
  { path: "src/hooks", score: 18, reason: "高复杂度" },
  { path: "src/api", score: 12, reason: "独立领域" }
]
```

**标记 "scoring" 为 completed。**

---

## Phase 3: 生成 AGENTS.md

**标记 "generate" 为 in_progress。**

<critical>
**文件写入规则**: 如果目标路径已有 AGENTS.md → 用 Edit 工具。如果不存在 → 用 Write 工具。
绝不使用 Write 覆盖已有文件。先通过 Read 或发现结果确认是否存在。
</critical>

### 根目录 AGENTS.md（完整版）

```markdown
# 项目知识库

**生成时间:** {TIMESTAMP}
**提交:** {SHORT_SHA}
**分支:** {BRANCH}

## 概述
{1-2 句: 项目是什么 + 核心技术栈}

## 结构
```
{root}/
├── {dir}/    # {仅注释非显而易见的用途}
└── {entry}
```

## 去哪找
| 任务 | 位置 | 备注 |
|------|------|------|

## 代码地图
{来自 LSP - 如果不可用或项目 <10 个文件则跳过}

| 符号 | 类型 | 位置 | 引用 | 角色 |
|------|------|------|------|------|

## 约定
{仅列出与标准不同的}

## 反模式（本项目）
{明确在此禁止的}

## 特有风格
{项目特有的}

## 命令
```bash
{开发/测试/构建}
```

## 备注
{陷阱/注意事项}
```

**质量门槛**: 50-150 行，无通用建议，无明显信息。

### 子目录 AGENTS.md（并行）

为每个位置启动写入任务：

```
for loc in AGENTS_LOCATIONS (除根目录):
  Task(general, "生成 AGENTS.md", "为 {loc.path} 生成 AGENTS.md
     - 原因: {loc.reason}
     - 最多 30-80 行
     - 绝不重复父级内容
     - 包含: OVERVIEW (1 行), STRUCTURE (如果 >5 个子目录), WHERE TO LOOK, CONVENTIONS (如果不同), ANTI-PATTERNS")
```

**等待全部完成。标记 "generate" 为 completed。**

---

## Phase 4: 审查与去重

**标记 "review" 为 in_progress。**

对每个生成的文件：
- 删除通用建议
- 删除与父级重复的内容
- 精简到大小限制
- 验证电报式风格

**标记 "review" 为 completed。**

---

## 最终报告

```
=== init-deep 完成 ===

模式: {update | create-new}

文件:
  [OK] ./AGENTS.md (根目录, {N} 行)
  [OK] ./src/hooks/AGENTS.md ({N} 行)

目录分析数: {N}
AGENTS.md 创建数: {N}
AGENTS.md 更新数: {N}

层级:
  ./AGENTS.md
  └── src/hooks/AGENTS.md
```

---

## 反模式

- **固定 agent 数量**: 必须根据项目大小/深度变化
- **串行执行**: 必须并行（explore + LSP 并行）
- **忽略已有**: 始终先读已有文件，即使 --create-new
- **过度文档化**: 不是每个目录都需要 AGENTS.md
- **冗余**: 子级不重复父级内容
- **通用内容**: 删除适用于所有项目的内容
- **冗长风格**: 电报式，否则就是死
