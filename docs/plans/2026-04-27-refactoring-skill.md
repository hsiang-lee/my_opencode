# Plan: Add Refactoring Skill to TDD Workflow

**Design spec:** `docs/specs/2026-04-27-refactoring-skill-design.md`
**Plan path:** `docs/plans/2026-04-27-refactoring-skill.md`
**Task count:** 4
**Key dependencies:** Task 3 and 4 depend on Task 1 (skill must exist before plan-executor references it)

---

## Phase 0: Verify References

### Verification 1: File paths

```
并行 dispatch:
  Task(explore, "验证文件路径",
    "确认以下文件路径存在:
     - docs/specs/2026-04-27-refactoring-skill-design.md
     - skills/tdd/SKILL.md
     - skills/brainstorm/SKILL.md
     - agents/plan-executor.md")
```

### Verification 2: Code patterns

```
并行 dispatch:
  Task(explore, "验证代码模式",
    "搜索:
     1. skill 文件 frontmatter 模式: '---' 开始, 包含 'name:' 和 'description:' 字段
     2. plan-executor 中的 'Required: load tdd skill' 指令
     3. plan-executor 中的 'Step 3: REFACTOR' 段落")
```

### Check: Existing implementation conflicts?

- No existing `skills/refactoring/` directory or `SKILL.md`
- No existing `Required: load refactoring skill` in any file
- No existing smell-detection or refactoring flow in plan-executor

All clear.

---

## Phase 1: File Structure Mapping

| Action | File | Purpose |
|--------|------|---------|
| Create | `skills/refactoring/SKILL.md` | New refactoring skill with smell classification, cheat sheet, and guarded execution flow |
| Modify | `agents/plan-executor.md` (lines 22-28, 118-128) | Add refactoring skill loading; replace generic Step 3 with structured refactoring flow |

---

## Phase 2: Task Decomposition

---

### Task 1: Create `skills/refactoring/SKILL.md` with frontmatter, smell classification, and cheat sheet

**Files:**
- Create: `skills/refactoring/SKILL.md`
- Test: shell verification commands

- [ ] **Step 1: 写失败测试** (RED)

  Verify the skill file does NOT exist yet (feature absent):

  ```bash
  # RED: test that file does NOT exist
  test -f skills/refactoring/SKILL.md
  echo "RED VERIFY: exit code $? (expected: 1 — file should not exist)"
  ```

  Expected output:
  ```
  RED VERIFY: exit code 1 (expected: 1 — file should not exist)
  ```

- [ ] **Step 2: 验证测试失败** (Verify RED)

  Run:
  ```bash
  test -f skills/refactoring/SKILL.md && echo "FAIL: file already exists" || echo "PASS: file does not exist — RED confirmed"
  ```

  Expected: `PASS: file does not exist — RED confirmed`

- [ ] **Step 3: 最小实现** (GREEN)

  Create the file with frontmatter, smell classification table, and technique cheat sheet:

  ```bash
  mkdir -p skills/refactoring
  ```

  Write `skills/refactoring/SKILL.md`:

  ```markdown
  ---
  name: refactoring
  description: Automatically detect and eliminate code smells during the REFACTOR phase of the TDD cycle. Provides bad-smell classification, technique cheat sheet, and test-gated execution flow. One smell at a time, no behavior change.
  ---

  # Refactoring — 代码重构

  在 TDD 的 REFACTOR 阶段自动检测并消除代码坏味道。每次只处理一种坏味道，每个步骤由测试验证。

  **核心原则：没有测试失败，就不重构。结构变化，行为不变。**

  违反这条规则的文字就是违反规则的精神。

  ---

  ## 坏味道分类 (Bad-Smell Classification)

  以下表格列出常见的代码坏味道及其检测条件。由执行者（plan-executor）人工判断检测，不使用自动化静态分析工具。

  | # | 坏味道 | 描述 | 检测条件 |
  |---|--------|------|----------|
  | 1 | **重复代码 (Duplicated Code)** | 相同或相似的代码出现在多个位置 | 同一结构出现在 ≥2 个方法/类/文件中 |
  | 2 | **过长方法 (Long Method)** | 一个方法承担了过多职责 | 方法长度 > 20 行，或包含多个明显可提取的段落 |
  | 3 | **过大类 (Large Class)** | 一个类承担了过多职责 | 类有 > 10 个方法，或包含多个不相关的功能组 |
  | 4 | **过长参数列表 (Long Parameter List)** | 方法参数过多 | 参数个数 > 4 |
  | 5 | **依恋情结 (Feature Envy)** | 方法更多使用另一个类的特性而非自身 | 方法中超过 50% 的调用是对另一个类/对象的操作 |
  | 6 | **基本类型偏执 (Primitive Obsession)** | 使用基本类型表示领域概念，没有封装 | 存在重复出现的字符串/数值参数，应封装为值对象 |
  | 7 | **switch 语句 (Switch Statements)** | 根据类型代码做分支判断 | switch/case 或 if/else-if 链可根据对象类型替换 |
  | 8 | **冗赘类 (Lazy Class)** | 类承担的职责太少 | 类只有 1-2 个简单方法，可以内联到使用处 |
  | 9 | **过度泛化 (Speculative Generality)** | 为不存在的未来需求设计的抽象 | 抽象类只有一个实现，或参数有从不使用的标志位 |
  | 10 | **消息链 (Message Chains)** | 长链的方法调用 | 形如 `a.getB().getC().doSomething()` 的调用链长度 > 2 |
  | 11 | **中间人 (Middle Man)** | 类的大部分方法只是委托给其他类 | 类中 > 60% 的方法只是委托调用 |
  | 12 | **过度亲密 (Inappropriate Intimacy)** | 类之间过多访问彼此的私有成员 | 类 A 在方法中多次调用类 B 的 getter/setter |
  | 13 | **异曲同工的类 (Alternative Classes)** | 类似功能的类有不同的接口 | 两个类做相似的事情但方法名/签名不一致 |
  | 14 | **注释 (Comments)** | 代码不易读，用注释解释行为 | 注释在解释"做了什么"而不是"为什么这么做" |

  ---

  ## 坏味道 → 重构技术对照表 (Smell-to-Technique Cheat Sheet)

  | 坏味道 | 推荐重构技术 |
  |--------|-------------|
  | 重复代码 | Extract Method / Pull Up Method / Form Template Method |
  | 过长方法 | Extract Method / Replace Temp with Query / Introduce Parameter Object |
  | 过大类 | Extract Class / Extract Subclass / Extract Interface |
  | 过长参数列表 | Introduce Parameter Object / Preserve Whole Object |
  | 依恋情结 | Move Method / Extract Method |
  | 基本类型偏执 | Replace Primitive with Object / Replace Type Code with Subclasses |
  | switch 语句 | Replace Type Code with Strategy/State / Replace Conditional with Polymorphism |
  | 冗赘类 | Inline Class / Collapse Hierarchy |
  | 过度泛化 | Collapse Hierarchy / Inline Class / Remove Parameter |
  | 消息链 | Hide Delegate / Extract Method |
  | 中间人 | Remove Middle Man / Inline Method |
  | 过度亲密 | Move Method / Change Bidirectional Association to Unidirectional |
  | 异曲同工的类 | Rename Method / Move Method |
  | 注释 | Extract Method / Rename Method / Introduce Assertion |

  ---

  ## 重构技术速查 (Technique Quick Reference)

  | 技术 | 描述 | 操作指引 |
  |------|------|----------|
  | **Extract Method** | 将一段代码提取为独立方法 | 选中代码段 → 创建新方法 → 传入需要的参数 → 替换原位置为方法调用 |
  | **Move Method** | 将方法移动到更合适的类 | 确认方法应属于目标类 → 复制方法到目标类 → 在原类中委托调用 |
  | **Rename Method** | 改进方法名使其意图清晰 | 改为"做什么"的描述（动词+名词），不是"怎么做" |
  | **Extract Class** | 将类的一部分职责分离到新类 | 识别内聚的功能组 → 创建新类 → 移动相关字段和方法 |
  | **Inline Class** | 将职责少的类合并到使用它的类 | 把类的字段和方法移入调用方 → 删除原类 |
  | **Introduce Parameter Object** | 将多个参数封装为一个对象 | 创建参数对象类 → 替换方法签名 → 更新调用方 |
  | **Preserve Whole Object** | 传递整个对象而不是从中提取值 | 修改方法签名接收对象 → 方法内直接使用对象字段 |
  | **Replace Primitive with Object** | 将基本类型替换为值对象 | 创建值对象类 → 封装行为和验证 → 替换所有使用处 |
  | **Replace Conditional with Polymorphism** | 用多态替换条件分支 | 提取各分支为子类方法 → 父类声明虚方法 → 调用处改用多态分发 |
  | **Pull Up Method** | 将相同的方法提升到父类 | 确认子类中有相同方法 → 复制到父类 → 删除子类版本 |
  | **Form Template Method** | 用模板方法模式统一算法骨架 | 提取算法步骤为方法 → 父类定义模板方法 → 子类实现步骤差异 |
  | **Hide Delegate** | 隐藏委托关系 | 在委托类中添加方法 → 调用方改为直接调用委托类的方法 |
  | **Remove Middle Man** | 移除中间委托层 | 调用方直接调用实际执行者 → 删除中间方法 |
  | **Introduce Assertion** | 将隐式假设转为显式断言 | 识别前置条件 → 添加 `assert` 或条件检查 |

  ```

- [ ] **Step 4: 验证测试通过** (Verify GREEN)

  Run:
  ```bash
  # Verify file exists
  test -f skills/refactoring/SKILL.md && echo "FILE_EXISTS: PASS" || echo "FILE_EXISTS: FAIL"
  # Verify frontmatter
  head -4 skills/refactoring/SKILL.md | grep -q 'name: refactoring' && echo "FRONTMATTER_NAME: PASS" || echo "FRONTMATTER_NAME: FAIL"
  head -4 skills/refactoring/SKILL.md | grep -q 'description:' && echo "FRONTMATTER_DESC: PASS" || echo "FRONTMATTER_DESC: FAIL"
  # Verify smell table exists
  grep -q 'Duplicated Code' skills/refactoring/SKILL.md && echo "SMELL_TABLE: PASS" || echo "SMELL_TABLE: FAIL"
  # Verify cheat sheet exists
  grep -q 'Extract Method' skills/refactoring/SKILL.md && echo "CHEAT_SHEET: PASS" || echo "CHEAT_SHEET: FAIL"
  ```

  Expected:
  ```
  FILE_EXISTS: PASS
  FRONTMATTER_NAME: PASS
  FRONTMATTER_DESC: PASS
  SMELL_TABLE: PASS
  CHEAT_SHEET: PASS
  ```

- [ ] **Step 5: 重构** (REFACTOR)

  Verify YAML frontmatter is properly closed (no content leaks into frontmatter):

  ```bash
  # Verify frontmatter closes properly on line 4
  sed -n '4p' skills/refactoring/SKILL.md | grep -q '^---$'
  if [ $? -eq 0 ]; then
    echo "FRONTMATTER_CLOSE: PASS"
  else
    echo "FRONTMATTER_CLOSE: FAIL — line 4 should be '---'"
  fi
  ```

  If FAIL, fix the file.

- [ ] **Step 6: 提交**

  ```bash
  git add skills/refactoring/SKILL.md && git commit -m "feat: create refactoring skill with smell classification and cheat sheet"
  ```

---

### Task 2: Add execution flow, error handling, and anti-patterns to `skills/refactoring/SKILL.md`

**Files:**
- Modify: `skills/refactoring/SKILL.md` (append after technique quick reference)
- Test: shell verification commands

- [ ] **Step 1: 写失败测试** (RED)

  Verify execution flow section does NOT exist yet:

  ```bash
  grep -q '## 执行流程' skills/refactoring/SKILL.md
  echo "RED VERIFY: exit code $? (expected: 1 — flow section should not exist)"
  ```

  Expected: `RED VERIFY: exit code 1 (expected: 1 — flow section should not exist)`

- [ ] **Step 2: 验证测试失败** (Verify RED)

  ```bash
  grep -q '## 执行流程' skills/refactoring/SKILL.md && echo "FAIL: flow section already exists" || echo "PASS: flow section does not exist — RED confirmed"
  ```

  Expected: `PASS: flow section does not exist — RED confirmed`

- [ ] **Step 3: 最小实现** (GREEN)

  Append the following to `skills/refactoring/SKILL.md`:

  ```markdown

  ---

  ## 执行流程 (Execution Flow)

  在 TDD 绿色阶段通过后（所有测试通过），plan-executor 使用本流程执行重构：

  ```
  1. 确认所有测试通过 (GREEN confirmed)
     │
  2. 所有测试通过？──否──► 停止。修复代码。不进入重构。
     │是
  3. 扫描代码：检测一种坏味道（从坏味道分类表中逐一比对）
     │
  4. 发现坏味道？──否──► 报告 "REFACTOR_SKIPPED: 未检测到坏味道"。进入提交。
     │是
  5. 选择对应的重构技术（从对照表中选择）
     │
  6. 应用重构：仅做结构性变更，不改变行为
     │
  7. 运行所有测试
     │
  8. 测试通过？──否──► 回滚本次重构改动。报告 "REFACTOR_FAILED: [坏味道] → [技术] 导致测试失败"。停止重构，进入提交。
     │是
  9. 还有更多坏味道？──是──► 回到步骤 3（一次只处理一种）
     │否
  10. 报告 "REFACTOR_DONE: 已消除 N 种坏味道"。进入提交。
  ```

  ### 执行规则

  - **一次一种坏味道。** 每次只应用一种重构技术，验证通过后才处理下一个。
  - **不变更行为。** 重构只改变结构：不添加新功能、不修改公共 API、不添加新的公开接口。
  - **测试通过后才继续。** 任何一步测试失败 -> 回滚该步 -> 报告 -> 停止。
  - **无中间提交。** 整个 RED → GREEN → REFACTOR 循环完成后才进行一次任务级提交。

  ### 输出状态

  执行完成后向 plan-executor 报告以下状态之一：

  | 状态 | 含义 | 下一步 |
  |------|------|--------|
  | `REFACTOR_SKIPPED` | 未检测到坏味道 | 直接进入提交 (Step 4) |
  | `REFACTOR_DONE` | 成功消除 N 种坏味道 | 进入提交 (Step 4) |
  | `REFACTOR_FAILED` | 某步重构导致测试失败（已回滚） | 进入提交 (Step 4)，但提交信息中标注失败详情 |

  ---

  ## 错误处理

  | 场景 | 处理方式 |
  |------|----------|
  | GREEN 后测试失败 | 不进入重构。先修复生产代码。 |
  | 重构步骤导致测试失败 | 回滚该单步重构改动。报告 "REFACTOR_FAILED: [坏味道] → [技术] broke test"。停止重构，进入提交。 |
  | 检测到多种坏味道 | 一次处理一种。每一步独立验证。 |
  | 未检测到坏味道 | 报告 "REFACTOR_SKIPPED: 未检测到代码坏味道"。进入提交。 |

  ---

  ## 红线 (Hard Constraints)

  - **没有测试失败，就不重构。** 任何测试失败时禁止重构。
  - **一次一种坏味道。** 应用一种重构技术，验证，重复。
  - **不变更行为。** 重构只改变结构——不添加功能、不修改 API、不新增公开接口。
  - **回滚红色。** 重构步骤导致测试失败，立即回滚该步。
  - **无中间提交。** 整个 RED → GREEN → REFACTOR 循环完成后才提交。

  ---

  ## 假设 (Assumptions)

  - 坏味道检测依赖执行者的人工判断（不引入自动化静态分析工具）。
  - 本技能不替换或修改现有 TDD 技能——它补充 REFACTOR 阶段。
  - Plan-executor 已通过 `Required` 指令加载本技能。

  ```

- [ ] **Step 4: 验证测试通过** (Verify GREEN)

  Run:
  ```bash
  grep -q '## 执行流程' skills/refactoring/SKILL.md && echo "FLOW_SECTION: PASS" || echo "FLOW_SECTION: FAIL"
  grep -q '一次一种坏味道' skills/refactoring/SKILL.md && echo "ONE_AT_A_TIME: PASS" || echo "ONE_AT_A_TIME: FAIL"
  grep -q 'REFACTOR_SKIPPED' skills/refactoring/SKILL.md && echo "SKIPPED_STATUS: PASS" || echo "SKIPPED_STATUS: FAIL"
  grep -q 'REFACTOR_FAILED' skills/refactoring/SKILL.md && echo "FAILED_STATUS: PASS" || echo "FAILED_STATUS: FAIL"
  grep -q 'REFACTOR_DONE' skills/refactoring/SKILL.md && echo "DONE_STATUS: PASS" || echo "DONE_STATUS: FAIL"
  grep -q '没有测试失败，就不重构' skills/refactoring/SKILL.md && echo "HARD_CONSTRAINT: PASS" || echo "HARD_CONSTRAINT: FAIL"
  ```

  Expected:
  ```
  FLOW_SECTION: PASS
  ONE_AT_A_TIME: PASS
  SKIPPED_STATUS: PASS
  FAILED_STATUS: PASS
  DONE_STATUS: PASS
  HARD_CONSTRAINT: PASS
  ```

- [ ] **Step 5: 重构** (REFACTOR)

  Ensure consistent markdown formatting (all headings use `##`, all code blocks use triple backticks):

  ```bash
  # Count headings to ensure consistent level
  echo "Heading levels in skill:"
  grep -n '^#' skills/refactoring/SKILL.md | head -20
  # Ensure no single backtick code fences
  grep -n '^```' skills/refactoring/SKILL.md && echo "CODE_FENCES: PASS" || echo "CODE_FENCES: WARN — no fenced blocks found"
  ```

  No changes needed if output looks consistent.

- [ ] **Step 6: 提交**

  ```bash
  git add skills/refactoring/SKILL.md && git commit -m "feat: add execution flow, error handling, and constraints to refactoring skill"
  ```

---

### Task 3: Add `Required: load refactoring skill` to `agents/plan-executor.md`

**Files:**
- Modify: `agents/plan-executor.md` (lines 22-28)
- Test: shell verification commands

- [ ] **Step 1: 写失败测试** (RED)

  Verify the refactoring skill loading directive does NOT exist yet:

  ```bash
  grep -q 'load refactoring skill' agents/plan-executor.md
  echo "RED VERIFY: exit code $? (expected: 1 — refactoring skill load should not exist)"
  ```

  Expected: `RED VERIFY: exit code 1 (expected: 1 — refactoring skill load should not exist)`

- [ ] **Step 2: 验证测试失败** (Verify RED)

  ```bash
  grep -q 'load refactoring skill' agents/plan-executor.md && echo "FAIL: refactoring load already exists" || echo "PASS: refactoring load does not exist — RED confirmed"
  ```

  Expected: `PASS: refactoring load does not exist — RED confirmed`

- [ ] **Step 3: 最小实现** (GREEN)

  Edit `agents/plan-executor.md`, replacing the existing REQUIRED block:

  **Old (lines 22-28):**
  ```
  ## REQUIRED: Load tdd skill

  ```
  加载 tdd skill 前禁止开始任何工作。
  TDD skill 定义了完整的 RED-GREEN-REFACTOR 流程和测试编写规范。
  这不是可选的。
  ```
  ```

  **New:**
  ```
  ## REQUIRED: Load core skills

  ```
  加载以下技能前禁止开始任何工作：

  1. tdd skill — 定义了完整的 RED-GREEN-REFACTOR 流程和测试编写规范。
  2. refactoring skill — 定义了 REFACTOR 阶段的坏味道检测与重构执行流程。

  这不是可选的。
  ```
  ```

  Apply with edit tool:

  ```
  oldString: "## REQUIRED: Load tdd skill\n\n```\n加载 tdd skill 前禁止开始任何工作。\nTDD skill 定义了完整的 RED-GREEN-REFACTOR 流程和测试编写规范。\n这不是可选的。\n```"
  newString: "## REQUIRED: Load core skills\n\n```\n加载以下技能前禁止开始任何工作：\n\n1. tdd skill — 定义了完整的 RED-GREEN-REFACTOR 流程和测试编写规范。\n2. refactoring skill — 定义了 REFACTOR 阶段的坏味道检测与重构执行流程。\n\n这不是可选的。\n```"
  ```

- [ ] **Step 4: 验证测试通过** (Verify GREEN)

  Run:
  ```bash
  grep -q 'load refactoring skill' agents/plan-executor.md && echo "REFACTORING_LOAD: PASS" || echo "REFACTORING_LOAD: FAIL"
  grep -q '加载以下技能前禁止' agents/plan-executor.md && echo "LOAD_PREAMBLE: PASS" || echo "LOAD_PREAMBLE: FAIL"
  grep -q '1. tdd skill' agents/plan-executor.md && echo "TDD_ITEM: PASS" || echo "TDD_ITEM: FAIL"
  grep -q '2. refactoring skill' agents/plan-executor.md && echo "REFACTORING_ITEM: PASS" || echo "REFACTORING_ITEM: FAIL"
  ```

  Expected:
  ```
  REFACTORING_LOAD: PASS
  LOAD_PREAMBLE: PASS
  TDD_ITEM: PASS
  REFACTORING_ITEM: PASS
  ```

- [ ] **Step 5: 重构** (REFACTOR)

  Verify formatting consistency — ensure blank lines separate sections properly:

  ```bash
  # Show the modified section
  awk '/^## REQUIRED/,/^```$/' agents/plan-executor.md | head -10
  ```

  Confirm the section structure is clean (heading, blank line, code fence, content, code fence, blank line).

- [ ] **Step 6: 提交**

  ```bash
  git add agents/plan-executor.md && git commit -m "feat: add Required: load refactoring skill to plan-executor"
  ```

---

### Task 4: Replace Step 3 in `agents/plan-executor.md` with structured refactoring flow

**Files:**
- Modify: `agents/plan-executor.md` (lines 118-128)
- Test: shell verification commands

- [ ] **Step 1: 写失败测试** (RED)

  Verify the old generic refactoring step still exists (to confirm it needs replacement):

  ```bash
  grep -q '删除重复' agents/plan-executor.md && echo "OLD_STEP3_EXISTS: yes" || echo "OLD_STEP3_EXISTS: no"
  ```

  Expected: `OLD_STEP3_EXISTS: yes` (old content is present, needs replacement)

  Now verify the new structured flow does NOT exist:

  ```bash
  grep -q '扫描代码：检测一种坏味道' agents/plan-executor.md
  echo "RED VERIFY: exit code $? (expected: 1 — new flow should not exist)"
  ```

  Expected: `RED VERIFY: exit code 1 (expected: 1 — new flow should not exist)`

- [ ] **Step 2: 验证测试失败** (Verify RED)

  ```bash
  grep -q '扫描代码：检测一种坏味道' agents/plan-executor.md && echo "FAIL: new flow already exists" || echo "PASS: new flow does not exist — RED confirmed"
  ```

  Expected: `PASS: new flow does not exist — RED confirmed`

- [ ] **Step 3: 最小实现** (GREEN)

  Edit `agents/plan-executor.md`, replacing the old Step 3 (lines 116-129):

  **Old (lines 116-129):**
  ```
  ---

  ## Step 3: REFACTOR — 清理

  只有在所有测试通过之后：

  - 删除重复
  - 改进命名（描述做什么，不是怎么做）
  - 提取辅助函数

  保持测试绿色。**不要添加新行为。**

  提交重构（如有更改）。
  ```

  **New:**
  ```
  ---

  ## Step 3: REFACTOR — 按技能执行重构

  只有在 Step 2 GREEN 所有测试通过之后，才进入重构阶段。

  ### 3.1 确认绿色状态

  运行测试确认所有测试通过：

  ```bash
  [运行测试命令]
  ```

  预期：全部 PASS。

  测试失败？→ 停止。修复代码。不进入重构。

  ### 3.2 检查并逐一消除坏味道

  遵循 `skills/refactoring/SKILL.md` 定义的执行流程：

  1. **扫描坏味道** — 从坏味道分类表中比对当前代码，识别一种坏味道
  2. **选择技术** — 从对照表中选择对应的重构技术
  3. **应用重构** — 仅做结构性变更，不改变行为
  4. **运行测试验证** — 运行全部测试确认绿色
  5. **测试通过？** → 继续；失败 → 回滚本次重构，报告 REFACTOR_FAILED，进入提交
  6. **重复** — 继续扫描下一种坏味道，直到无更多坏味道

  ### 3.3 报告重构结果

  根据重构结果输出状态：

  - `REFACTOR_SKIPPED: 未检测到坏味道` → 直接进入 Step 4 提交
  - `REFACTOR_DONE: 已消除 N 种坏味道` → 进入 Step 4 提交
  - `REFACTOR_FAILED: [坏味道] → [技术] 导致测试失败（已回滚）` → 进入 Step 4 提交

  ### 3.4 提交

  ```bash
  # 如有重构变更
  git add [变更文件] && git commit -m "refactor: [坏味道] → [技术]"
  ```

  保持测试绿色。**不要添加新行为。**
  ```

  Apply with edit tool.

- [ ] **Step 4: 验证测试通过** (Verify GREEN)

  Run:
  ```bash
  # Verify old generic refactoring is gone
  grep -q '删除重复' agents/plan-executor.md && echo "OLD_CONTENT_REMOVED: FAIL" || echo "OLD_CONTENT_REMOVED: PASS"
  # Verify new structured flow exists
  grep -q '按技能执行重构' agents/plan-executor.md && echo "NEW_STEP3_TITLE: PASS" || echo "NEW_STEP3_TITLE: FAIL"
  grep -q '扫描代码：检测一种坏味道\|扫描坏味道' agents/plan-executor.md && echo "SCAN_STEP: PASS" || echo "SCAN_STEP: FAIL"
  grep -q 'REFACTOR_SKIPPED' agents/plan-executor.md && echo "SKIPPED_STATUS: PASS" || echo "SKIPPED_STATUS: FAIL"
  grep -q 'REFACTOR_DONE' agents/plan-executor.md && echo "DONE_STATUS: PASS" || echo "DONE_STATUS: FAIL"
  grep -q 'REFACTOR_FAILED' agents/plan-executor.md && echo "FAILED_STATUS: PASS" || echo "FAILED_STATUS: FAIL"
  grep -q '不要添加新行为' agents/plan-executor.md && echo "NO_NEW_BEHAVIOR: PASS" || echo "NO_NEW_BEHAVIOR: FAIL"
  ```

  Expected:
  ```
  OLD_CONTENT_REMOVED: PASS
  NEW_STEP3_TITLE: PASS
  SCAN_STEP: PASS
  SKIPPED_STATUS: PASS
  DONE_STATUS: PASS
  FAILED_STATUS: PASS
  NO_NEW_BEHAVIOR: PASS
  ```

- [ ] **Step 5: 重构** (REFACTOR)

  Verify the Step 4 heading is still intact (should not have been disturbed by the edit):

  ```bash
  grep -q '## Step 4: Repeat' agents/plan-executor.md && echo "STEP4_HEADING: PASS" || echo "STEP4_HEADING: FAIL — Step 4 heading was modified"
  ```

  If PASS, no changes needed.

- [ ] **Step 6: 提交**

  ```bash
  git add agents/plan-executor.md && git commit -m "feat: replace generic REFACTOR step with structured refactoring flow"
  ```

---

## Phase 3: Self-Review

### 1. 规范覆盖

| 设计文档规范 | 对应任务 |
|-------------|----------|
| Component A: `skills/refactoring/SKILL.md` new | Task 1, Task 2 |
| Bad-smell classification | Task 1 (smell table) |
| Smell-to-technique cheat sheet | Task 1 (cheat sheet) |
| Guarded execution flow | Task 2 (execution flow section) |
| Error handling (revert on red, skip on clean) | Task 2 (error handling section) |
| Component B: `agents/plan-executor.md` modified | Task 3, Task 4 |
| `Required: load refactoring skill` before Step 3 | Task 3 |
| After Step 2 GREEN, trigger refactoring | Task 4 (3.1, 3.2) |
| One smell at a time | Task 2 (execution rules), Task 4 (step 3.2) |
| No intermediate commits | Task 2 (execution rules) |
| Testing strategy (green → load skill → detect → revert) | Task 4 (flow) |

### 2. 占位符扫描

- [ ] 无 "TBD"、"TODO"、"稍后实现"
- [ ] 无 "添加适当的错误处理"（所有错误处理已具体实现）
- [ ] 无空测试（每个 RED 有具体验证命令和预期输出）
- [ ] 无 "类似任务 N"（每个任务完整写出所有步骤）
- [ ] 无未定义的引用（所有类型/函数/文件路径都已定义）

### 3. 类型一致性

- `skills/refactoring/SKILL.md` — 前 matter 包含 `name: refactoring` 和 `description:`，与 `skills/tdd/SKILL.md` 和 `skills/brainstorm/SKILL.md` 格式一致
- `agents/plan-executor.md` — 修改后保持原 frontmatter 不变；Required 指令语法与加载 tdd skill 一致
- 状态码 `REFACTOR_SKIPPED` / `REFACTOR_DONE` / `REFACTOR_FAILED` 在 skill 和 plan-executor 中定义一致

### 4. 自包含

- Task 1: 独立创建 skill 文件，不依赖其他任务
- Task 2: 追加内容到已创建的 skill 文件，仅依赖 Task 1 的文件存在
- Task 3: 独立修改 Required 块，不依赖其他任务
- Task 4: 修改 Step 3 段落，不依赖其他任务（但内容引用了 skill 文件路径）

---

## Summary

| 任务 | 文件 | 动作 | 步骤数 |
|------|------|------|--------|
| Task 1 | `skills/refactoring/SKILL.md` | Create (frontmatter + smell table + cheat sheet) | 6 |
| Task 2 | `skills/refactoring/SKILL.md` | Append (execution flow + error handling + constraints) | 6 |
| Task 3 | `agents/plan-executor.md` | Modify (Required block) | 6 |
| Task 4 | `agents/plan-executor.md` | Modify (Step 3 content) | 6 |

**关键依赖:** Task 1 → Task 2 (同文件追加); Task 3, Task 4 需在 Task 1 之后执行（plan-executor 引用的 skill 必须先存在）
