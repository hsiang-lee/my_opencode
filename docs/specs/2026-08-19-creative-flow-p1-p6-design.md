# Creative 流程 P1（批量执行）+ P6（规格化计划）设计规范

> **状态:** 已批准 (2026-08-19，含 P1a/P6a 修订)

**目标:** 降低 Creative 流程的执行延迟，消除结构性往返成本，同时保持 TDD 纪律与批次单 commit + 抢救协议。通过 P1 将 plan-executor/code-reviewer 从逐任务 dispatch 改为批次粒度；通过 P6 将计划从「完整代码」降为「完整规格」，让生产代码只在 executor 带测试反馈下被书写一次。

**架构:** P1 改变 Subagent 派发粒度与协议（executor 领批次、reviewer 按 SHA 区间整批审查），commit 采用批次单 commit + 抢救协议，不改变 TDD 纪律与上下文隔离；P6 重定义 plan-writer 计划格式（锁 WHAT、交还 HOW），同步更新 executor 职权条款、reviewer 核对项、momus 审查标准与 README 描述。

**技术栈:** Markdown 提示词文件（`agents/*.md`），无代码成分，无单元测试框架。

---

## 背景与问题

用户反馈 Creative 流程（7 步：设计探索 → spec-writer → plan-writer → momus 评审 → plan-executor → code-reviewer → branch-finisher）执行缓慢。诊断出两个结构性成本，用户已批准修复：

### 问题 1：逐任务派发导致往返膨胀（P1 针对）

- 现状：Creative 对**每个任务** dispatch 1 次 `plan-executor` + 1 次 `code-reviewer`。
- 量化：一个含 4 个任务的计划 = **8 次 subagent 运行** + 8 次经 Creative 中转，且**全部串行**。
- 每个任务都经历「Creative → executor → Creative → reviewer → Creative」的完整切换，往返开销在任务数量上线性放大。

### 问题 2：计划层伪 TDD 与生产代码写两遍（P6 针对）

- 现状：plan-writer 在**无编译器/测试反馈**的情况下盲写完整实现代码（对实现的预测）；executor 再将这份预测代码誊写、适配进真实环境。
- 后果：
  1. 生产代码被书写两次（一次在计划里，一次在 implementation 里），两处可能漂移。
  2. 计划层面是伪 TDD：**实现决策发生在反馈回路之外**，违背 TDD「先测试后实现、靠反馈驱动」的核心。

### 核心洞察

- **TDD 中测试就是规格。** 测试的输入→预期输出 行为清单即行为规格。
- 计划锁定 **WHAT**（改什么、测什么、接口长什么样、怎么验证），executor 在测试反馈下实现 **HOW**（生产代码本体的唯一一次书写）。

---

## 目标与非目标

### 目标

- 将 4 任务计划的 subagent 运行次数从 **8 次降到 4 次**（1 批次 = 1 次 executor + 1 次 reviewer），消除经 Creative 的中转往返。
- 让生产代码只被书写一次（executor 的 GREEN 步），消除计划层重复书写与漂移风险。
- 让计划成为「可验证的规格」，而非「预测代码」。
- 在减少往返的同时**不减少纪律**：每任务完整 TDD 红绿循环、批次单 commit + 抢救协议、executor/reviewer 全新上下文隔离，全部保留。

### 非目标（Non-goals，明确不做）

- **`agents/Debug.md` 不改**。它不走 plan-writer，直接以「根因 + 修复策略 + 测试类型」dispatch executor，本身已是规格式；Debug 为单任务派发，与批次无关。
- **模型配置不改**。用户已另批方案 A'，留作独立任务，本设计不触碰。
- **P2 流水线并行不做**。批次 K 审查与批次 K+1 执行重叠执行，留作第二批（本设计明确排除）。
- **tdd / refactoring 等 skill 不改**。TDD 纪律本身不变，变化的是计划格式与派发粒度。
- **spec-writer / brainstorm / metis / librarian / explore / branch-finisher / oracle 不改**。

---

## P1 设计：批量执行

### 批次规则

- **领批方式**：plan-executor 一次领取一个**批次**，批次 = 2–4 个内聚任务，**硬上限 4**。
- **内聚规则**：同模块 / 同文件的任务放同批（减少上下文切换，提高单批效率）。
- **批次预标注（P6a 决策）**：plan-writer 在计划输出中**预标注建议批次划分**（它拥有全部内聚信息）；Creative dispatch 时**默认遵循**，可调整。
- **批内执行**：批次内**逐任务**执行完整 TDD 红绿循环 + **批次单 commit**（纪律不减少，只减少往返；逐任务 commit 的回滚粒度收益因合并时 squash 而不存在）。
- **完成条件**：批次内全部任务 **GREEN 后一次 commit**（批次单 commit），然后 executor 才返回 Creative。
- **BLOCKED 抢救路径**：批次中途卡死时，将已完成且测试通过的任务**抢救 commit**（message 标明含哪些任务、哪个任务为何卡死），保证重派时新 executor 面对干净基线。
- **批次划分**：建议批次由 plan-writer 预标注（见上），最终由 Creative dispatch 时指定批次内容与 SHA 基线。

### 批内状态处理

- 某任务 **BLOCKED** → 已完成且测试通过的任务**抢救 commit**（不丢弃，不回滚已提交成果；message 标明含哪些任务、哪个任务为何卡死），executor 返回**逐任务状态清单**（哪些 DONE / 哪些 BLOCKED，Blocked 附原因）。
- Creative 收到批内部分 BLOCKED：**默认单独重派该任务**（上下文最小、反馈最快）——**仅当与后续批次内聚时**才并入下一批重派；或**升级用户**（符合既有 BLOCKED 升级逻辑与 3 次熔断）。

### Reviewer 批次协议

- **审查范围**：code-reviewer 按**批次 SHA 区间**（本批基线 SHA .. 本批 HEAD SHA）整批审查，而非逐任务。
- **逐任务核对**：虽按批次范围审查，但 reviewer **逐任务**核对测试证据（每个任务的测试是否覆盖其行为规格、是否通过），不因批量而合并跳过；**以测试规格为单位，不依赖 commit 边界**（批次单 commit 不影响 reviewer 的逐任务核对）。
- **输入契约（P6a 决策）**：Creative 的 Step 6 dispatch 块**显式传入**：计划文件路径 + 批次任务清单 + 测试规格 + SHA 区间。
- 审查产出仍按 Critical / Important / Minor 分级；Critical/Important 返回 Step 5 修复。

### P1 保留不变项（强调）

- TDD 纪律（每任务 RED→GREEN→REFACTOR）不变。
- **commit 粒度为批次单 commit + 抢救协议**（非逐任务 commit）。
- 上下文隔离不变：executor 与 reviewer 每次 dispatch 均为全新上下文，由 Creative 提供精准策划。

---

## P6 设计：计划从「完整代码」降为「完整规格」

### WHAT / HOW 划分表

| 维度 | 归属 | 内容 | plan-writer 是否产出 |
|------|------|------|---------------------|
| 精确锚点 | **WHAT** | file:line — 修改哪些文件哪些位置 | 必须，具体到 `file:line` |
| 测试规格（= 行为规格） | **WHAT** | 每任务 输入→预期输出 行为清单，含边界情况和错误路径 | 必须，完整列出，逐条锁定 |
| 接口签名 | **WHAT** | 函数签名 / 类型 / 模块边界 | 必须，防漂移 |
| 验证命令 | **WHAT** | 可复制粘贴执行的命令（RED/GREEN 验证） | 必须 |
| 声明式产物全文 | **WHAT** | schema / config / 数据文件等「代码即规格」的内容 | 必须，保留全文 |
| 生产代码本体 | **HOW** | GREEN 步实现代码 | **不产出，留白**（唯一一次书写在 executor，带测试反馈） |
| 测试的机械细节 | **HOW** | import 路径等 | 不锁死（但**断言/行为锁定**） |
| REFACTOR 手法 | **HOW** | 重构的具体技术选择 | 不锁死 |

### 任务模板（重写后）

```markdown
### Task N: [组件名称]

**What（计划锁定，不可改）:**

**Files:**
- Create: `exact/path/to/file.ext`
- Modify: `exact/path/to/existing.ext:123-145`
- Test: `tests/exact/path/to/test.ext`

**接口签名:**
- [函数/类型签名 + 模块边界，防漂移]

**测试规格（= 行为规格, executor 据此写测试, 断言/行为不许改）:**
- 输入: [具体输入, 含边界情况] → 预期输出: [具体返回值/行为]
- 输入: [错误路径输入] → 预期: [错误处理行为]
- ...

**声明式产物（如适用, 保留全文）:**
```[schema/config/数据内容全文]
```

**验证命令（可复制粘贴）:**
- RED 验证: `具体命令` → 预期: FAIL with [具体错误]
- GREEN 验证: `具体命令` → 预期: PASS

**How（executor 在 HOW 内自由, plan 有意留白）:**
- [GREEN 实现本体 / 测试机械细节(import 路径等, 断言除外) / REFACTOR 手法 —— 由 executor 在测试反馈下决定]
```

### 各角色设计要点

- **plan-writer 职责（P6a 决策）**：plan-writer 从设计决策**推导文件映射**（其现有 Phase 0 引用验证 / Phase 1 文件结构映射即为此职责）——file:line 级映射是 plan-writer 的**执行规格**职责，设计文档不再代劳；设计文档只做**决策记录**（WHY + WHAT 决策）。设计 / 计划每层信息只写一次。
- **executor 职权条款改写**：计划锁 WHAT（测试规格、签名、锚点），executor 在 HOW 内有自由，边界是设计文档 + TDD 纪律。
- **「没有占位符」原则修订**：**WHAT 部分禁止占位符**（锚点 / 签名 / 命令 / 测试规格必须具体）；**HOW 部分有意留白**（实现本体不写）。占位符禁令仍适用于 WHAT，但不再要求 HOW 也写满。
- **momus 审查标准更新**：检查「每个任务有可验证的验收标准（锚点 + 测试规格 + 验证命令）」，**不再期望 / 不要求完整实现代码**。

---

## 验证方案

> 本项目为 markdown 提示词文件，无单元测试框架，验证为策略级静态一致性检查：
>
> - **grep 一致性**：确认无旧的逐任务粒度 commit、「完整代码」等旧措辞残留，批次 / SHA 区间 / 批次单 commit 术语在相关文件间一致。
> - **跨文件契约核对**：Creative Step 5/6 dispatch 块与 executor/reviewer 输入契约逐项对得上。
> - **git diff 审查**：改动仅触及目标文件，未越界触碰非目标文件（Debug.md、skill、spec-writer 等）。
> - **部署冒烟**：`install.sh` 部署 → 重启 opencode → 新会话冒烟（配置非热加载）。

---

## 部署与生效

- 通过 `install.sh`（将 `agents/*.md` 部署到 `~/.config/opencode/agents/`）发布。
- **配置非热加载**：重启 opencode 后新会话生效；当前已打开会话仍使用旧配置，行为变化需在新会话验证。
- README 的安装流程与文件结构保持不变。

---

## 风险与缓解

| 风险 | 缓解 |
|------|------|
| **executor 判断权重上升**：P6 将实现本体决策交给 executor，执行者对 HOW 的自由度增大，可能偏离设计意图。 | 测试规格锁定断言与行为（WHAT 不可改），executor 的 HOW 自由被可执验证的测试边界约束；reviewer 新增「测试是否符合计划测试规格」核对项兜底。 |
| **批次失败的有界浪费**：批次内后续任务可能在先前任务失败后才暴露问题，浪费已耗算力。| 批次硬上限 4 限制浪费上界；批内 BLOCKED 时将已完成且测试通过的任务**抢救 commit** 不白费；reviewer 按批次整批审查保证失败尽早暴露；Critical/Important 回 Step 5 修复。 |
| **共享文件任务批次冲突**：同批内任务修改同一文件导致 commit 冲突。| 批次内聚规则要求同模块/同文件放同批；批次单 commit 整体提交，冲突风险低且可控。 |
| **批次过大超出单次上下文**：4 个任务可能超过 executor 单次执行上下文。| 硬上限 4 即为边界；若超限，Creative 拆分为多个批次。 |
| **「HOW 留白」被误读为「规格缺失」**：实现代码缺位可能让 momus/执行者误以为占位符。 | 明确区分「WHAT 占位符（禁止）」与「HOW 留白（有意）」，在 plan-writer 核心原则与 momus 审查标准中双重声明。 |
| **批次状态处理遗漏已提交成果**：部分 BLOCKED 时可能误丢弃已完成 commit。 | 明确「已完成且测试通过的任务**抢救 commit**」；Creative 按逐任务状态清单决定**默认单独重派该任务**（仅当与后续批次内聚时才并入）或升级用户。 |

---

## 交付物

- 本文档：`docs/specs/2026-08-19-creative-flow-p1-p6-design.md`
- 涉及文件改动（仅文件名，不带章节细节）：
  - `agents/Creative.md`
  - `agents/plan-writer.md`
  - `agents/plan-executor.md`
  - `agents/code-reviewer.md`
  - `agents/momus.md`
  - `README.md`
