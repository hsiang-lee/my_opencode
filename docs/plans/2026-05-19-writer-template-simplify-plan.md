# Plan: spec-writer / plan-writer 模板与工作流程简化

> **设计文档:** `docs/specs/2026-05-19-writer-template-simplify-design.md`

**目标:** 修改 `agents/spec-writer.md` 和 `agents/plan-writer.md`，简化输出模板结构、减少冗余，完整保留 TDD 铁律（RED → GREEN → REFACTOR）。

**架构:** 5 项改动、5 个任务。每任务 3 项（RED / GREEN / REFACTOR），Commit 由外部流程处理。

---

## 引用验证

- `agents/spec-writer.md` ✅ 存在（144 行）
- `agents/plan-writer.md` ✅ 存在（156 行）
- `docs/specs/2026-05-19-writer-template-simplify-design.md` ✅ 存在（268 行）
- Phase 2 在 spec-writer.md:46 匹配 ✅
- Phase 2 在 plan-writer.md:61 匹配 ✅
- 无冲突的现有实现 ✅

---

## Task 1: spec-writer — Phase 2 模板从全强制改为按需选节

**Files:**
- Modify: `agents/spec-writer.md:46-100`

**变动范围：** Phase 2 的文档结构模板和章节展开规则。

- [ ] **RED:** `rg -n "### 组件概览" agents/spec-writer.md` → 预期: `69:### 组件概览`
  ```bash
  # 确认当前存在强制 6 节模板（组件概览、组件详情、数据流、错误处理、测试策略、约束与假设全部强制出现）
  rg -n "组件概览|组件详情|## 数据流|## 错误处理|## 测试策略|## 约束与假设" agents/spec-writer.md
  # 预期: 匹配 6 处（line 69, 72, 85, 89, 93, 97），证明当前为全强制模板
  ```

- [ ] **GREEN:** 将 lines 46-100 替换为按需选节模板和展开规则
  ```markdown
  ## Phase 2: 编写设计文档

  ```
  输出路径: docs/specs/YYYY-MM-DD-<topic>-design.md
  ```

  ### 文档结构

  按复杂度按需选节。总体原则：**如果某节写完不超过 3 行，就不要开新节。** 将该内容合并到上一节，或改为 1-2 句段落放在相关章节末尾。

  ```markdown
  # [功能名称] 设计规范

  > **状态:** 草稿 | 已批准 | 已实现

  **目标:** [一句话描述要构建什么]

  **架构:** [2-3 句话描述方案]

  **技术栈:** [关键技术/库]

  ---

  ## 架构
  [单组件或改动简单：2-3 段文字直接描述。多组件时才展开 #### 组件 [字母] 逐组件描述]

  ## 数据流
  [简单数据流：3-5 行文字。复杂数据流：ASCII 图]

  ## 错误处理
  [≤3 个场景：段落描述。>3 个场景：表格]

  ## 测试策略
  [≤3 条：列表。>3 条：展开为独立 ### 章节]

  ## 约束与假设
  [≤3 条：列表。>3 条：展开为独立 ### 章节]
  ```

  **各章节展开规则：**

  - **架构/组件详情**：单组件或改动简单 → 2-3 段文字直接描述，不拆分组件详情子节。多组件时 → 展开为 `#### 组件 [字母]` 逐组件描述（含职责、接口、依赖、错误处理）。
  - **数据流**：简单数据流（单路径、无分支）→ 3-5 行文字描述。复杂数据流（多分支、异步、回调）→ ASCII 流程图。
  - **错误处理**：≤3 个错误场景 → 段落描述。>3 个错误场景 → 表格（场景 | 处理方式）。
  - **测试策略**：≤3 条策略 → 直接列表。>3 条 → 展开为独立 `### 测试策略` 章节。
  - **约束与假设**：≤3 条 → 直接列表。>3 条 → 展开为独立 `### 约束与假设` 章节（含硬约束、假设、明确的不做事项）。
  ```
  验证: `rg -n "组件概览" agents/spec-writer.md` → 预期: 无匹配（旧强制模板已移除）

- [ ] **REFACTOR:** REFACTOR_SKIPPED — 无坏味道

---

## Task 2: spec-writer — Phase 3/4 自检不写入产物

**Files:**
- Modify: `agents/spec-writer.md:104-127`

**变动范围：** Phase 3 标注为内部流程，Phase 4 输出格式移除"自检结果"行。

- [ ] **RED:** `rg -n "自检结果" agents/spec-writer.md` → 预期: `125:自检结果: [通过 / 发现并修复了 N 个问题]`
  ```bash
  # 确认当前 Phase 4 输出格式包含 "自检结果" 行
  rg -n "Phase 3: 自检" agents/spec-writer.md
  # 预期: 104:## Phase 3: 自检 （无 "内部流程" 标注）
  ```

- [ ] **GREEN:** 将 lines 104-127 替换为内部流程标注 + 精简的输出格式
  ```markdown
  ## Phase 3: 自检（内部流程，不写入产物）

  保存前用新眼光检查，发现问题直接修复后保存：

  1. **占位符扫描**: 任何 "TBD"、"TODO"、不完整的部分或模糊需求？修复。
  2. **内部一致性**: 各部分相互矛盾吗？架构与功能描述匹配吗？
  3. **范围检查**: 这对于单个实现计划是否足够集中？
  4. **歧义检查**: 任何需求有两种不同解读？如果是，选一个并明确。

  修复发现的任何问题。不需要重新审核 — 直接修复并继续。

  > **此阶段为 agent 内部工作流程，自检内容和结果不写入最终设计文档。**

  ---

  ## Phase 4: 输出

  文件写入后报告路径。git commit 由 captain 处理。

  ### 输出格式

  ```
  设计文档路径: docs/specs/YYYY-MM-DD-<topic>-design.md
  状态: DONE | NEEDS_CONTEXT
  ```
  ```
  验证: `rg -n "自检结果" agents/spec-writer.md` → 预期: 无匹配

- [ ] **REFACTOR:** REFACTOR_SKIPPED — 无坏味道

---

## Task 3: plan-writer — Phase 0 验证引用改为摘要格式

**Files:**
- Modify: `agents/plan-writer.md:34-47`

**变动范围：** Phase 0 从输出 dispatch 指令改为输出验证结果摘要（✅/❌）。

- [ ] **RED:** `rg -n "并行 dispatch" agents/plan-writer.md` → 预期: `39:并行 dispatch:`
  ```bash
  # 确认当前 Phase 0 包含 Task(explore, ...) dispatch 指令格式
  rg -n "Task\(explore" agents/plan-writer.md
  # 预期: 40:  Task(explore, "验证文件路径",
  ```

- [ ] **GREEN:** 将 lines 34-47 替换为摘要格式 + 内部执行说明
  ```markdown
  ## Phase 0: 验证引用（可并行）

  读取设计文档后，并行 dispatch explore 验证所有引用。最终计划中只输出验证结果摘要（✅/❌），不输出 dispatch 指令。

  ### 引用验证

  - `path/to/existing/file.cpp` ✅ 存在
  - `src/module/header.h` ✅ 存在
  - `pattern::FunctionName` ✅ 匹配 3 处
  - `path/to/missing.cpp` ❌ 不存在 — NEEDS_CONTEXT

  如果发现 ❌，标记 NEEDS_CONTEXT 并停止。
  ```
  验证: `rg -n "并行 dispatch" agents/plan-writer.md` → 预期: 无匹配

- [ ] **REFACTOR:** REFACTOR_SKIPPED — 无坏味道

---

## Task 4: plan-writer — Phase 2 任务模板 6 步压缩为 3 项

**Files:**
- Modify: `agents/plan-writer.md:61-100`

**变动范围：** TDD 任务模板代码块（lines 67-94）和粒度要求（lines 96-100）。移除 Commit 步骤。RED 合并 verify、GREEN 合并 verify、REFACTOR 强制保留但格式压缩。

- [ ] **RED:** `rg -n "Step 6: 提交" agents/plan-writer.md` → 预期: `92:- [ ] **Step 6: 提交**`
  ```bash
  # 确认当前为 6 步模板
  rg -n "Step [1-6]:" agents/plan-writer.md
  # 预期: 匹配 6 处（lines 75, 78, 82, 85, 89, 92）
  ```

- [ ] **GREEN:** 将 lines 61-100 替换为 3 项模板 + REFACTOR 规则 + 更新的粒度要求
  ```markdown
  ## Phase 2: 任务分解

  ### TDD 任务结构

  每个任务按 RED-GREEN-REFACTOR 分解为 3 项。Commit 由外部流程（plan-executor / branch-finisher）处理，不包含在任务模板中。

  ```markdown
  ### Task N: [组件名称]

  **Files:**
  - Create: `exact/path/to/file.ext`
  - Modify: `exact/path/to/existing.ext:123-145`
  - Test: `tests/exact/path/to/test.ext`

  - [ ] **RED:** `具体测试运行命令` → 预期: FAIL with "function not defined"
    ```cpp
    // 实际测试代码
    ```

  - [ ] **GREEN:** [实现代码简述]
    ```cpp
    // 实际实现代码
    ```
    验证: `具体命令` → 预期: PASS

  - [ ] **REFACTOR:** 
    <!-- 有坏味道：展开。无坏味道：REFACTOR_SKIPPED — 无坏味道 -->
  ```

  **REFACTOR 规则（强制存在）：**

  - **有坏味道时** — 展开为：坏味道类型 → 重构技术 → 验证
    ```markdown
    - [ ] **REFACTOR:** 重复代码 → Extract Method → `extractHelpers()`
      验证: `ctest -R test_task_N` → 预期: PASS
    ```
  - **无坏味道时** — 一句话
    ```markdown
    - [ ] **REFACTOR:** REFACTOR_SKIPPED — 无坏味道
    ```

  ### 粒度要求

  - 每项 2-5 分钟可执行完毕
  - 原子化：一个动作
  - 自包含：不依赖理解其他任务
  ```
  验证: `rg -n "Step [1-6]:" agents/plan-writer.md` → 预期: 无匹配（6 步已替换为 3 项）

- [ ] **REFACTOR:** REFACTOR_SKIPPED — 无坏味道

---

## Task 5: plan-writer — Phase 3 自检不写入产物

**Files:**
- Modify: `agents/plan-writer.md:104-125`

**变动范围：** Phase 3 自检标注为内部流程，压缩占位符禁止列表为 1 行。自检内容不写入最终计划文档。

- [ ] **RED:** `rg -n "Phase 3: 自检" agents/plan-writer.md` → 预期: `104:## Phase 3: 自检`
  ```bash
  # 确认当前无 "内部流程" 标注
  rg -n "不写入产物" agents/plan-writer.md
  # 预期: 无匹配
  ```

- [ ] **GREEN:** 将 lines 104-125 替换为内部流程标注 + 压缩的自检清单
  ```markdown
  ## Phase 3: 自检（内部流程，不写入产物）

  保存前执行自检，发现问题直接修复。自检内容和结果不写入最终计划文档。

  1. **规范覆盖** — 浏览设计文档的每个部分。能指向实现它的任务吗？
  2. **占位符扫描** — 禁止出现："TBD"、"TODO"、"添加适当的错误处理"（无实际代码）、"类似任务 N"、引用未定义的类型/函数。
  3. **类型一致性** — 后面的任务使用的类型、方法签名和属性名与前面的任务一致吗？
  4. **自包含** — 每个任务可以独立理解和执行吗？

  > **此阶段为 agent 内部工作流程，自检内容不写入产物。**
  ```
  验证: `rg -n "### 1\. 规范覆盖" agents/plan-writer.md` → 预期: 无匹配（旧展开格式已压缩）
  验证: `rg -n "不写入产物" agents/plan-writer.md` → 预期: 2 处匹配（Phase 3 标题 + 底注）

- [ ] **REFACTOR:** REFACTOR_SKIPPED — 无坏味道

---

## 关键依赖

```
Task 1 ──┐
         ├──► 无依赖（不同行范围）
Task 2 ──┘
Task 3 ──┐
Task 4 ──┼──► 无依赖（不同行范围）
Task 5 ──┘
```

5 个任务均可并行执行。Task 1/2 修改同一文件 `agents/spec-writer.md` 但互不重叠的行范围（46-100 vs 104-127），同理 Task 3/4/5 修改 `agents/plan-writer.md` 的行范围（34-47, 61-100, 104-125）也互不重叠。
