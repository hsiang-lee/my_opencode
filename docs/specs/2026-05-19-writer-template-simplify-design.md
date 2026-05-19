# Spec-Writer / Plan-Writer 模板与工作流程简化 设计规范

> **状态:** 草稿

**目标:** 简化 spec-writer 和 plan-writer agent 的模板结构，消除"相同模板拉长简单功能"的问题，同时完整保留 TDD 铁律（RED → GREEN → REFACTOR）。

**架构:** 两个 agent 的模板从"全强制章节/步骤"改为"按复杂度按需选节"。spec-writer 按内容量决定是否开新节（≤3 行不拆分）；plan-writer 将每任务 6 步压缩为 4 项（RED 合并 verify、GREEN 合并 verify），Phase 0 只输出验证摘要而非 dispatch 指令，Phase 3 自检从产物中移除。

**技术栈:** 纯 Markdown agent 定义文件（`agents/spec-writer.md`、`agents/plan-writer.md`），无新依赖。

---

## 架构

### 组件概览

改动涉及 2 个现有 agent 定义文件，不新增文件：

```
agents/spec-writer.md   ── 改 Phase 2 模板规则、Phase 3 产物归属
agents/plan-writer.md   ── 改 Phase 0 输出格式、Phase 2 任务模板、Phase 3 产物归属
```

### 组件详情

#### 组件 A: `agents/spec-writer.md`（修改）

- **职责:** 将设计决策转化为正式设计文档。模板从全强制改为按复杂度按需选节。
- **修改点:**
  - Phase 2 文档结构模板
  - Phase 3 自检的产物归属
- **依赖:** 无新增依赖（仍依赖 brainstorm 输出的结构化设计决策）
- **不修改的部分:** Phase 1（解析设计决策）、Phase 4（输出格式）、职责边界、反合理化、红旗列表

#### 组件 B: `agents/plan-writer.md`（修改）

- **职责:** 从设计文档生成 TDD 实现计划。每任务模板从 6 步压缩为 3 项（RED / GREEN / REFACTOR，无 Commit）。
- **修改点:**
  - Phase 0 验证引用：输出格式从完整 dispatch 指令改为验证摘要
  - Phase 2 任务模板：从 6 步压缩为 3 项（RED / GREEN / REFACTOR）
  - Phase 3 自检：从产物中移除
- **依赖:** 无新增依赖（仍依赖 tdd / refactoring skill）
- **不修改的部分:** Phase 1（文件结构映射）、tdd skill 和 refactoring skill 的 Required 加载指令、职责边界、反合理化、红旗列表

---

## 数据流

不变。spec-writer 接收设计决策 → 生成设计文档；plan-writer 读取设计文档 → 验证引用 → 映射文件 → 分解任务 → 输出计划。

---

## 改动详情

### 改动 1：spec-writer Phase 2 模板 —— 从全强制改为按需选节

**改前（全强制 6 节模板）：**

```markdown
## 架构
### 组件概览
### 组件详情
#### 组件 A: [名称] ...
#### 组件 B: [名称] ...

## 数据流

## 错误处理

## 测试策略

## 约束与假设
```

所有章节无论内容多寡都必须出现，即使简单功能也被拉长。

**改后（按复杂度按需选节）：**

```markdown
## 架构
[单组件或改动简单：2-3 段文字直接描述。多组件时才展开 #### 组件 [字母] 模板]

## 数据流
[简单数据流：3-5 行文字。复杂数据流：ASCII 图]

## 错误处理
[≤3 个场景：段落描述。>3 个场景：表格]

## 测试策略
[≤3 条：列表。>3 条：展开为章节]

## 约束与假设
[≤3 条：列表。>3 条：展开为章节]
```

**总体原则（新增）：**

> 如果某节写完不超过 3 行，就不要开新节。将该内容合并到上一节，或改为 1-2 句的段落放在相关章节末尾。

具体规则：
- **架构/组件详情**：单组件或改动简单 → 2-3 段文字；多组件 → `#### 组件 [字母]` 逐组件展开
- **数据流**：简单 → 3-5 行文字；复杂 → ASCII 流程图
- **错误处理**：≤3 个场景 → 段落描述；>3 个 → 表格
- **测试策略 / 约束与假设**：≤3 条 → 直接列表；>3 条 → 各自展开为独立 `###` 章节

### 改动 2：spec-writer Phase 3 自检 —— 不写入产物

**改前：** Phase 3 自检流程在 agent 定义中列出，执行结果通过 Phase 4 输出格式中的"自检结果: [通过 / 发现并修复了 N 个问题]"隐式反映在输出中。

**改后：** Phase 3 自检保持为内部工作流程（保存前检查占位符、一致性、范围、歧义），修复发现的问题后直接保存。Phase 4 输出格式中**移除"自检结果"行**。

改后 Phase 4 输出格式：

```
设计文档路径: docs/specs/YYYY-MM-DD-<topic>-design.md
状态: DONE | NEEDS_CONTEXT
```

### 改动 3：plan-writer Phase 0 验证引用 —— 从 dispatch 指令改为验证摘要

**改前：**

```
并行 dispatch:
  Task(explore, "验证文件路径",
    "确认以下文件路径存在: [从设计文档提取的文件列表]")

  Task(explore, "验证代码模式",
    "搜索: [设计文档引用的代码模式] 确实在代码库中存在")

检查: 是否有冲突的现有实现？
```

**改后：**

```markdown
### 引用验证

- `path/to/existing/file.cpp` ✅ 存在
- `src/module/header.h` ✅ 存在
- `pattern::FunctionName` ✅ 匹配 3 处
- `path/to/missing.cpp` ❌ 不存在 — NEEDS_CONTEXT
```

**说明：** plan-writer 在写作前先验证所有引用（dispatch explore 并行执行），但最终计划中只输出验证结果摘要（✅/❌），不输出 dispatch 指令。如果发现 ❌，则标记 NEEDS_CONTEXT。

### 改动 4：plan-writer Phase 2 任务模板 —— 从 6 步压缩为 4 项

**改前（每任务 6 步）：**

```markdown
- [ ] **Step 1: 写失败测试** (RED)
  [实际测试代码]

- [ ] **Step 2: 验证测试失败** (Verify RED)
  运行: `具体命令`
  预期: FAIL with "function not defined"

- [ ] **Step 3: 最小实现** (GREEN)
  [实际实现代码]

- [ ] **Step 4: 验证测试通过** (Verify GREEN)
  运行: `具体命令`
  预期: PASS

- [ ] **Step 5: 重构** (REFACTOR)
  [如需要，清理重复、改进命名]

- [ ] **Step 6: 提交**
  git add [文件] && git commit -m "feat: [描述]"
```

**改后（每任务 3 项）：**

```markdown
- [ ] **RED:** `具体测试运行命令` → 预期: FAIL with "function not defined"
  ```cpp
  // 实际测试代码
  ```

- [ ] **GREEN:** [实现代码]
  ```cpp
  // 实际实现代码
  ```
  验证: `具体命令` → 预期: PASS

- [ ] **REFACTOR:** 
  <!-- 有坏味道时：展开分析 + 技术 + 验证 -->
  <!-- 无坏味道时：REFACTOR_SKIPPED — 无坏味道 -->

```

**合并映射：**

| 改前 6 步 | 改后 3 项 | 合并方式 |
|-----------|----------|----------|
| Step 1: RED（代码块） | **RED:** 命令 + 预期 + 代码块 | 原 Step 1 + Step 2 合并，失败预期紧跟命令 |
| Step 2: Verify RED（命令块） | 合并到 RED | — |
| Step 3: GREEN（代码块） | **GREEN:** 代码 + 验证行 | 原 Step 3 + Step 4 合并，验证缩为一行 |
| Step 4: Verify GREEN（命令块） | 合并到 GREEN（一行验证命令） | — |
| Step 5: REFACTOR | **REFACTOR:** 按坏味道 | 格式压缩，但保留强制 |
| Step 6: Commit | ❌ 已移除（Commit 由外部流程处理） | 删除 |

**REFACTOR 压缩规则（TDD 保留，格式紧凑）：**

- **有坏味道：** 展开分析出坏味道类型 → 技术 → 验证
  ```markdown
  - [ ] **REFACTOR:** 重复代码 → Extract Method → `extractHelpers()`
    验证: `ctest -R test_task_N` → 预期: PASS
  ```
- **无坏味道：** 一句话
  ```markdown
  - [ ] **REFACTOR:** REFACTOR_SKIPPED — 无坏味道
  ```

**不变的部分：** RED → GREEN → REFACTOR 三步顺序和存在性不可删除。tdd skill 和 refactoring skill 的 Required 加载指令保持原样。

### 改动 5：plan-writer Phase 3 自检 —— 从产物中移除

**改前：** Phase 3 包含 40 行的自检表（规范覆盖、占位符扫描、类型一致性、自包含），作为 agent 工作流程的一部分。自检结果虽无显式输出行要求，但自检流程本身冗长。

**改后：** Phase 3 改为内部流程。plan-writer 在保存前执行同样的自检（占位符扫描、一致性检查、覆盖验证），发现问题直接修复。自检内容和结果**不写入最终计划文档**。Phase 3 agent 定义保留为内部指引，但标注"内部流程，不写入产物"。

---

## 错误处理

无新增错误场景。现有错误处理策略不变：

- spec-writer：设计决策有歧义 → NEEDS_CONTEXT；文档有占位符 → 修复后保存
- plan-writer：引用验证发现文件不存在 → NEEDS_CONTEXT；任务有 TBD → 修复后保存

---

## 测试策略

- 本次改动为 agent 定义文件的模板文本修改，不涉及可执行代码，无单元测试
- 验证方式：在实际设计/计划编写任务中观察生成文档的长度和结构是否符合预期：
  1. 简单功能（单组件、≤3 错误场景）→ spec 文档不应出现拆分过细的空章节
  2. 简单任务 → plan 文档中每任务不应出现 6 步 checkbox
  3. plan 文档中不应出现 `Task(explore, ...)` dispatch 指令
  4. plan 文档中不应出现自检表

---

## 约束与假设

### 硬约束
- **TDD 铁律不可动摇**：RED → GREEN → REFACTOR 三步的完整语义必须保留，顺序不可改变。压缩只影响表达格式，不影响步骤的存在性。
- **REFACTOR 不可删除**：用户明确要求保留，即使无坏味道也必须出现条目（值为 REFACTOR_SKIPPED）。
- **占位符零容忍**：压缩模板后，"TBD"、"TODO"、不完整步骤的禁令保持原样。
- **tdd skill 和 refactoring skill 的 Required 加载指令不变**：压缩任务模板不等于弱化 TDD 流程。
- **职责边界不变**：spec-writer 只记录不决策，plan-writer 假设零上下文。

### 假设
- 简单功能的判定由编写者（spec-writer / plan-writer agent）根据设计输入自行判断，"≤3 行"、"≤3 条"是明确量化标准。
- plan-writer 在写作前执行的 explore dispatch 与当前行为一致，只是最终计划产物中不输出 dispatch 指令。
- 改动范围仅限于 `agents/spec-writer.md` 和 `agents/plan-writer.md` 两个文件。

### 明确的不做事项
- 不修改 `skills/tdd/SKILL.md` 和 `skills/refactoring/SKILL.md`
- 不修改 plan-executor、brainstorm 等其他 agent
- 不修改 spec-writer 的 Phase 1（解析设计决策）和 Phase 4（输出格式，除移除"自检结果"行外）
- 不修改 plan-writer 的 Phase 1（文件结构映射）
- 不引入新的 agent 或 skill
- 不改变 spec-writer 和 plan-writer 的职责边界声明
- 不删除或弱化反合理化和红旗列表
