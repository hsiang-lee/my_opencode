# Creative 流程 P1（批量执行）+ P6（规格化计划）实现计划

> **状态:** 待 momus 评审
>
> **设计文档:** `docs/specs/2026-08-19-creative-flow-p1-p6-design.md`（已批准，含 P1a/P6a 修订 + 3 项缺口裁决）
>
> **目标一句话:** 将 Creative 流程的 Subagent 派发从「逐任务」改为「批次粒度」（P1），将计划从「完整代码」降为「完整规格」（P6），使一个 4 任务计划的 subagent 运行次数从 8 次降到 4 次，生产代码只在 executor 带测试反馈下被书写一次，同时保留每任务完整 TDD 红绿循环与批次单 commit + 抢救协议。
>
> **本仓库定位:** 这是本仓库第一份按新 P6 格式撰写的计划。每个任务锁定 WHAT（锚点 / 接口签名 / 测试规格 / 验证命令），正文改写措辞（HOW）有意留白，由 plan-executor 依据设计文档撰写。

---

## 执行注意事项（executor 开工前必读）

1. **分支检查（开工第一步，先于一切）:**
   ```bash
   git status
   git branch --show-current
   ```
   若当前在 `main` 或 `master`，创建并切换特性分支（AGENTS.md 禁止直接提交主分支）：
   ```bash
   git checkout -b feature/creative-flow-p1-p6
   ```
2. **设计文档纳入:** `docs/specs/2026-08-19-creative-flow-p1-p6-design.md` 目前**未提交**。随**批次 A 的第一个 commit** 一并纳入（`git add docs/specs/2026-08-19-creative-flow-p1-p6-design.md` 连同该批任务产物）。
3. **配置非热加载:** 无需重启 opencode 验证 agent 行为；**静态 grep 断言即为验收**。改动仅触及 markdown 提示词文件，无单元测试框架。
4. **严禁触碰:** `agents/Debug.md`、`agents/spec-writer.md` 及其余 agents、`agents/code-reviewer.md` 之外的非目标文件、`skills/`、`docs/specs/`（设计文档本身）、`install.sh`。git diff 必须仅触及目标文件。
5. **TDD 映射:** 本项目测试 = grep/文本断言。每个任务先运行该任务的 grep 断言确认当前状态（RED：正断言失败 = 新内容尚不存在），完成正文改写后断言翻转（GREEN）。**断言必须先于改写运行。** 参考 `tdd`/`refactoring` skill。

---

## 批次总览表

| 批次 | 内聚主题 | 任务 | commit 策略 |
|------|----------|------|-------------|
| **A** | 计划规格化核心（新格式源头 + 评审标准联动） | Task 1 plan-writer.md + Task 2 momus.md | 批次 A 全部 GREEN 后一次提交，message 含 Task 1/2 + 设计文档 |
| **B** | 编排协议（Creative dispatch 契约） | Task 3 Creative.md | 批次 B GREEN 后一次提交 |
| **C** | 执行/审查协议 | Task 4 plan-executor.md + Task 5 code-reviewer.md | 批次 C GREEN 后一次提交 |
| **D** | 文档同步 + 全局一致性收尾 | Task 6 README.md + Task 7 全局一致性检查 | 批次 D GREEN 后一次提交；Task 7 为验证型（若发现跨文件契约缺失，修复后并入同批 commit） |

**预标注说明（P6a）:** 各批次按文件内聚划分，批内任务同属一个改动模块。**每批 2–4 个任务，硬上限 4**；单任务亦可独立成批——当该任务是后续批次的上游契约依赖时（如本计划批次 B 的 Task 3 为 Task 4/5 定义 dispatch 契约），可与 plan-writer 批次预标注规则一致地独立成批。Creative dispatch 时默认遵循本预标注，可在 dispatch 时调整批次内容与 SHA 基线。

**关键依赖:**
- Task 1（plan-writer 定义 WHAT/HOW/批次术语）→ 无前置，为源头。
- Task 3（Creative 定义 Step 5/6 dispatch 契约字段）→ 定义 executor（Task 4）/ reviewer（Task 5）输入契约的上游。Task 3 应在 Task 4/5 之前完成（跨文件契约断言：Creative ⊇ executor/reviewer）。
- Task 7（全局一致性）→ 依赖 Task 1–6 全部完成，作为最终收尾。

---

## Task 1: plan-writer 新格式（WHAT 锁 / HOW 留白 + 批次预标注）

**Files:**
- Modify: `agents/plan-writer.md:1-10`（frontmatter description L2）
- Modify: `agents/plan-writer.md:14-18`（核心原则 L16）
- Modify: `agents/plan-writer.md:61-105`（Phase 2 任务分解 / TDD 任务模板）
- Modify: `agents/plan-writer.md:108-151`（Phase 3 自检 / 反合理化 / 红旗）
- Modify: `agents/plan-writer.md:154-160`（输出块）

**接口签名（新增/修改章节）:**
- **frontmatter description**（L2）: 删除「完整代码」措辞，改为「完整规格（WHAT 锁 / HOW 留白）」表述。
- **核心原则**（L16）: 从「没有占位符。每步含实际的代码和命令。」修订为「**WHAT 部分禁止占位符**（锚点/签名/命令/测试规格必须具体）；**HOW 部分有意留白**（实现本体不写，由 executor 在测试反馈下书写一次）。」保留「违反这条规则的文字就是违反规则的精神」。
- **Phase 2 TDD 任务模板**（L67-99）: 整体替换为设计文档 L103-133 的 WHAT/HOW 模板，含固定章节标题：
  - `**What（计划锁定，不可改）:**`
    - `**Files:**`（Create/Modify/Test，精确到 file:line）
    - `**接口签名:**`
    - `**测试规格（= 行为规格, executor 据此写测试, 断言/行为不许改）:**`
    - `**声明式产物（如适用, 保留全文）:**`
    - `**验证命令（可复制粘贴）:**`（RED 验证 + GREEN 验证，各含预期输出）
  - `**How（executor 在 HOW 内自由, plan 有意留白）:**`（GREEN 实现本体 / 测试机械细节 / REFACTOR 手法 — 由 executor 决定）
- **Phase 2 新增「批次预标注」小节**（置于 TDD 任务模板之后）: 要求 plan-writer 在计划输出中**预标注建议批次划分**（每批 2–4 个任务，硬上限 4，按文件内聚分组），并在批次总览表给出每批 commit 策略（批次单 commit / 抢救 commit）。
- **Phase 3 占位符扫描**（L115-123）: 修订为「扫描 WHAT 部分占位符（禁止）」+「区分 WHAT 占位符（禁止）与 HOW 留白（有意）」。原「描述要做什么而不展示怎么做的步骤」条目修订为「WHAT 部分缺锚点/签名/命令/测试规格」。
- **输出块**（L154-160）: 新增 `批次: [每批任务清单]` 行。

**测试规格（grep 断言，改前 FAIL / 改后 PASS）:**

正断言（新术语在 `agents/plan-writer.md` 必须出现）:
- `WHAT` 出现
- `HOW` 出现
- `测试规格` 出现
- `验证命令` 出现
- `预标注` 出现
- `批次单 commit` 出现
- `What（计划锁定，不可改）` 出现
- `How（executor 在 HOW 内自由, plan 有意留白）` 出现
- `声明式产物` 出现（补充：WHAT 模板的声明式产物章节必须被断言覆盖，避免测试盲区）

负断言（旧措辞必须在 `agents/plan-writer.md` 中消失）:
- `完整代码` grep 返回空
- `核心原则：没有占位符。每步含实际的代码和命令。` 这一整句消失
- 旧 TDD 模板的章节标题 `**行为描述:**` 和 `**测试策略:**` 消失（被 WHAT/HOW 模板取代）

**验证命令:**

```bash
# RED（改前）: 正断言应为 FAIL（新术语不存在）
grep -c "预标注" agents/plan-writer.md        # 预期改前: 0, 改后: ≥1
grep -c "What（计划锁定，不可改）" agents/plan-writer.md  # 预期改前: 0, 改后: ≥1

# GREEN（改后）: 负断言应为空
grep -n "完整代码" agents/plan-writer.md      # 预期: (无输出)
grep -n "核心原则：没有占位符。每步含实际的代码和命令。" agents/plan-writer.md  # 预期: (无输出)
grep -n "核心原则：没有占位符" agents/plan-writer.md  # 预期: (无输出)

# 正断言复核（改后）
grep -n "WHAT\|HOW\|测试规格\|验证命令\|预标注\|批次单 commit" agents/plan-writer.md
```

**How（留白，依据设计文档 L103-133、L137、L139 撰写）:**
- 新任务模板的正文措辞、批次预标注小节写法、核心原则措辞由 executor 依据设计文档撰写。注意：计划全文用词与下文 Task 2/Task 3 中的跨文件契约术语保持一致（`测试规格`、`验证命令`、`批次单 commit`、`WHAT`、`HOW`）。

---

## Task 2: momus 审查标准（检查「锚点 + 测试规格 + 验证命令」，不再要求完整实现代码）

**Files:**
- Modify: `agents/momus.md:15-19`（CRITICAL FIRST RULE 之后 / Your Purpose 之前，可选新增鉴别声明）
- Modify: `agents/momus.md:43-85`（What You Check — 检查项 4/7 联动）
- Modify: `agents/momus.md:86-99`（What You Do NOT Check / IMPORTANT 说明）

**接口签名（新增/修改检查项）:**
- **What You Check #4「QA Scenario Executability」**（L64-67）: 与「每任务有可验证的验收标准」对齐，明确验收标准 = **锚点 + 测试规格 + 验证命令** 三者齐备。
- **What You Check #7「Verifiability」**（L76-77）: 修订「clear success criterion」为「每个任务有可验证的验收标准（**锚点 + 测试规格 + 验证命令**）」。
- **新增一个 What You Check 检查项**（置于 #8 TDD Discipline 后）: 「**WHAT 占位符 vs HOW 留白区分**」——检查 WHAT 部分（锚点/签名/测试规格/验证命令）无占位符；**不再期望 / 不要求完整实现代码**（HOW 有意留白是合法的，不是缺陷）。
- **What You Do NOT Check**（L88-96）: 新增「是否有 HOW 实现本体代码」——明确 HOW 留白不构成 REJECT 理由。

**测试规格（grep 断言，改前 FAIL / 改后 PASS）:**

正断言（在 `agents/momus.md` 中必须出现）:
- `测试规格` 出现
- `验证命令` 出现
- `HOW` 出现（HOW 留白概念）
- `WHAT` 出现

负断言:（momus.md 原本无「完整实现代码」要求，此任务无强制负断言；仅确认不新增「需要完整代码」类措辞）

**验证命令:**

```bash
# RED（改前）: 正断言应为 FAIL
grep -c "测试规格" agents/momus.md        # 预期改前: 0, 改后: ≥1
grep -c "验证命令" agents/momus.md        # 预期改前: 0, 改后: ≥1

# GREEN（改后）
grep -n "HOW\|WHAT\|测试规格\|验证命令" agents/momus.md
grep -n "完整实现代码" agents/momus.md    # 预期: (无输出) — 不新增要求完整代码的措辞
```

**How（留白，依据设计文档 L140、L171）:**
- 检查项正文措辞、新增项的句式由 executor 依据设计文档撰写。重点是双重声明「WHAT 占位符禁止 / HOW 留白有意」，消除「HOW 留白被误读为规格缺失」风险。

---

## Task 3: Creative 编排协议（批次 dispatch 契约 + 抢救协议）

**Files:**
- Modify: `agents/Creative.md:110-145`（dot 流程图 — Step 5/6 标签可加批次语义）
- Modify: `agents/Creative.md:151-163`（铁律检查表 — Step 5 行）
- Modify: `agents/Creative.md:165-177`（用户交互暂停规则 — BLOCKED 抢救/升级）
- Modify: `agents/Creative.md:205-247`（流程伪代码 — Step 5/6 dispatch 块重写；Step 4 评审要点）
- Modify: `agents/Creative.md:260-278`（@oracle 触发条件 — 可选）
- Modify: `agents/Creative.md:282-291`（Subagent 状态处理表 — BLOCKED 抢救协议）

**接口签名（跨文件契约 — 本文档是上游定义者，字段逐项列出）:**

**Step 5 dispatch 块**（替换现在 L232-236 的 `Task: "Execute Task N"` 与 `对每个任务: 宣布 → 执行 → 审查`）。新块必须含**全部下列字段**：
1. **计划文件路径** — 本批次依据的计划（`docs/plans/...md`）
2. **批次任务清单** — 本批次包含哪些任务（Task N 列表，引用 plan-writer 预标注，可调整）
3. **锚点** — 每任务 file:line（从计划中携带）
4. **测试规格** — 每任务的测试规格（从计划中携带，或指明「见计划 Phase 2 对应任务」）
5. **SHA 基线** — 本批次的 commit 起点（rebase 基线 / 上次 commit HEAD）
6. **Required** — `Load tdd skill + refactoring skill`

**Step 6 dispatch 块**（替换现在 L238-241 的 `Task: "Review implementation"`）。新块必须含**全部下列字段**：
1. **计划文件路径** — code-reviewer 逐任务核对测试证据的依据
2. **批次任务清单** — 本批次审查范围的任务列表
3. **测试规格** — 每任务测试规格，供 reviewer 核对「测试是否符合计划测试规格」
4. **SHA 区间** — `基线 SHA .. 本批 HEAD SHA`，供整批 `git diff`

**铁律检查表 Step 5 行**（L159-160）: 从「没有计划 → 禁止实现」「Step 5 每任务: 无失败测试 → 禁写生产代码」扩展为批次视角：`Step 5: 无计划/无批次预标注 → 禁止实现`；保留 `Step 5 每任务: 无失败测试 → 禁写生产代码`。

**Subagent 状态处理表 BLOCKED 行**（L289）: 从「评估: 上下文不足→提供更多; 太复杂→换更强模型或分解; 计划错误→升级用户」扩展批次语义：批内部分 BLOCKED → **默认单独重派该任务**（上下文最小、反馈最快）；**仅当与后续批次内聚时**才并入下一批重派；或按既有 BLOCKED 升级逻辑与 3 次熔断升级用户。接收 executor 返回的**逐任务状态清单**（哪些 DONE / 哪些 BLOCKED，Blocked 附原因）。

**用户交互暂停规则 BLOCKED 升级**（L176）: 暂停场景列表确认含「BLOCKED 升级」。

**dot 图 Step 5/6**（L118-119 节点 label）: Step 5 可标注「执行批次任务」、Step 6 标注「按批次审查」；门 gate6 语义不变（Critical/Important → 回 Step 5 修复）。

**测试规格（grep 断言，改前 FAIL / 改后 PASS）:**

正断言（在 `agents/Creative.md` 中必须出现）:
- `批次单 commit` 出现
- `抢救 commit` 出现
- `SHA 基线` 出现（Step 5 块 — 由 `基线 SHA` 或 `SHA 基线` 体现）
- `批次 SHA 区间` 出现（Step 6 块 — 由 `SHA 区间` / `基线 SHA .. 本批 HEAD SHA` 体现）
- `逐任务状态清单` 出现
- `批次任务清单` 出现

负断言（旧措辞在 `agents/Creative.md` 中必须消失）:
- `Task: "Execute Task N"` 消失（Step 5）
- `对每个任务: 宣布 → 执行 → 审查` 消失（逐任务 dispatch 措辞）
- `逐任务单独 commit` 不应出现（grep 返回空）

跨文件契约断言（本节内自检，最终由 Task 7 复核）:
- Step 5 块字段 ⊇ executor 输入契约字段（Task 4 声称接受的字段：计划文件路径/批次任务清单/锚点/测试规格/SHA 基线）
- Step 6 块字段 ⊇ reviewer 输入契约字段（Task 5 声称接受的字段：计划文件路径/批次任务清单/测试规格/SHA 区间）

**验证命令:**

```bash
# RED（改前）: 正断言应为 FAIL
grep -c "批次单 commit" agents/Creative.md    # 预期改前: 0, 改后: ≥1
grep -c "抢救 commit" agents/Creative.md      # 预期改前: 0, 改后: ≥1
grep -c "SHA 基线" agents/Creative.md         # 预期改前: 0, 改后: ≥1
grep -c "批次 SHA 区间" agents/Creative.md    # 预期改前: 0, 改后: ≥1

# GREEN（改后）: 负断言应为空
grep -n 'Task: "Execute Task N"' agents/Creative.md   # 预期: (无输出)
grep -n "对每个任务: 宣布 → 执行 → 审查" agents/Creative.md  # 预期: (无输出)
grep -n "逐任务单独 commit" agents/Creative.md         # 预期: (无输出)

# 正断言复核（改后）
grep -n "批次单 commit\|抢救 commit\|SHA 基线\|批次 SHA 区间\|逐任务状态清单\|批次任务清单" agents/Creative.md
```

**How（留白，依据设计文档 L56-84、L137-140、L172）:**
- Step 5/6 dispatch 块字段的正文措辞、批内状态处理、BLOCKED 抢救协议、批次单 commit message 模板，由 executor 依据设计文档撰写。字段名与 Task 4/Task 5 中的输入契约字段名保持一致（`计划文件路径`、`批次任务清单`、`锚点`、`测试规格`、`SHA 基线`、`SHA 区间`）。

---

## Task 4: plan-executor 大批量协议（批次单 commit + 抢救协议 + 逐任务状态清单）

**Files:**
- Modify: `agents/plan-executor.md:1-10`（frontmatter description L2）
- Modify: `agents/plan-executor.md:33-40`（铁律 — Step 4 COMMIT 语义）
- Modify: `agents/plan-executor.md:64-87`（Step 1 RED — 提交命令区）
- Modify: `agents/plan-executor.md:90-108`（Step 2 GREEN — 提交命令区）
- Modify: `agents/plan-executor.md:158-168`（升级路径 — 返回内容含逐任务状态清单）

**接口签名（新增/修改章节）:**

**frontmatter description**（L2）: 保留 TDD 纪律表述，从「严格遵循计划步骤」扩展批次语义（若适用可加「领批次执行」）。

**铁律**（L36-39）: Step 4 `COMMIT: 提交 ✓` 修订为批次视角：`COMMIT: 批内全部 GREEN 后一次提交（批次单 commit）✓`。保留 RED/GREEN/REFACTOR 逐任务完整循环。

**Step 1 RED 提交命令**（L83-86）：删除/改写逐任务 `git commit -m "test: add failing test for [行为]"`，明确**不再逐任务 commit**；测试此刻**暂不提交**，待批内全部 GREEN 后随批次单 commit 一并提交。

**Step 2 GREEN 提交命令**（L105-108）：同理删除/改写逐任务 `git commit -m "feat: implement [行为]"`。

**新增「批次协议」章节**（置于 Step 4 Repeat 附近或铁律之后）:
- **批次单 commit**：批次内**逐任务**执行完整 TDD 红绿循环（纪律不减），全部任务 GREEN 后**一次 commit**。message 含**批次内任务清单** + 引用计划文件。
- **抢救 commit**：批次中途 BLOCKED 时，对**已完成且测试通过**的任务**抢救 commit**（message 标明含哪些任务、哪个任务为何卡死），保证重派时新 executor 面对干净基线；不回滚已提交成果。
- **逐任务状态清单**：批次结束返回 Creative 时，产出**逐任务状态清单**（哪些 DONE / 哪些 BLOCKED，Blocked 附原因）。

**升级路径表**（L160-165）: DONE 行返回内容补充「逐任务状态清单」；BLOCKED 行补充「已完成的测试通过任务已抢救 commit」。

**输入契约（本 agent 声称接受的字段）:**
1. 计划文件路径
2. 批次任务清单
3. 锚点
4. 测试规格
5. SHA 基线

**测试规格（grep 断言，改前 FAIL / 改后 PASS）:**

正断言（在 `agents/plan-executor.md` 中必须出现）:
- `批次单 commit` 出现
- `抢救 commit` 出现
- `逐任务状态清单` 出现
- `批次任务清单` 出现

负断言（旧措辞在 `agents/plan-executor.md` 中必须消失）:
- `git commit -m "test: add failing test for [行为]"` 消失
- `git commit -m "feat: implement [行为]"` 消失
- `逐任务单独 commit` 不应出现

**验证命令:**

```bash
# RED（改前）: 正断言应为 FAIL
grep -c "批次单 commit" agents/plan-executor.md   # 预期改前: 0, 改后: ≥1
grep -c "抢救 commit" agents/plan-executor.md     # 预期改前: 0, 改后: ≥1
grep -c "逐任务状态清单" agents/plan-executor.md  # 预期改前: 0, 改后: ≥1

# GREEN（改后）: 负断言应为空
grep -n 'git commit -m "test: add failing test for \[行为\]"' agents/plan-executor.md  # 预期: (无输出)
grep -n 'git commit -m "feat: implement \[行为\]"' agents/plan-executor.md            # 预期: (无输出)
grep -n "逐任务单独 commit" agents/plan-executor.md                                  # 预期: (无输出)

# 正断言复核（改后）
grep -n "批次单 commit\|抢救 commit\|逐任务状态清单\|批次任务清单" agents/plan-executor.md
```

**How（留白，依据设计文档 L60-71、L82-84、L167-168）:**
- 批次协议章节正文、批次单 commit message 模板、抢救 commit 措辞，由 executor 依据设计文档撰写。输入契约字段名须与 Task 3 的 Step 5 dispatch 块字段名逐字一致。

---

## Task 5: code-reviewer 批次审查协议（按 SHA 区间整批审查 + 逐任务核对测试证据）

**Files:**
- Modify: `agents/code-reviewer.md:1-10`（frontmatter description L2）
- Modify: `agents/code-reviewer.md:20-28`（Phase 1 Gather Evidence — SHA 区间）
- Modify: `agents/code-reviewer.md:31-60`（Phase 2 假测试检测 — 前置测试规格核对）
- Modify: `agents/code-reviewer.md:84-89`（Phase 3 需求符合 — 测试规格核对项）

**接口签名（新增/修改章节）:**

**frontmatter description**（L2）: 从「用于每个实现任务完成后的审查」改为「按批次 SHA 区间整批审查，逐任务核对测试证据」。

**Phase 1 Gather Evidence**（L20-28）: `git diff --stat BASE_SHA..HEAD_SHA` 注释明确 `BASE_SHA` = 批次基线 SHA、`HEAD_SHA` = 本批 HEAD（来自 dispatch 块的 **SHA 区间**）。

**Phase 2 假测试检测前置**（Phase 2 章节开头，L32 附近）新增「测试规格核对」: 无论按批次审查，reviewer **逐任务核对测试证据**——每个任务的测试是否覆盖其行为规格（对照 dispatch 块携带的**测试规格**）、是否通过；**以测试规格为单位，不依赖 commit 边界**（批次单 commit 不影响逐任务核对）。

**Phase 3 需求符合**（L84-89）: 「所有计划需求满足？」升级为「每个任务的测试**是否符合计划的测试规格**（断言/行为匹配，不因批量而合并跳过）」。

**输入契约（本 agent 声称接受的字段）:**
1. 计划文件路径
2. 批次任务清单
3. 测试规格
4. SHA 区间

**测试规格（grep 断言，改前 FAIL / 改后 PASS）:**

正断言（在 `agents/code-reviewer.md` 中必须出现）:
- `批次 SHA 区间` 出现
- `测试规格` 出现
- `批次任务清单` 出现
- `计划文件路径` 出现
- `逐任务核对` 出现（每个任务核对行为）

负断言（旧措辞在 `agents/code-reviewer.md` 中必须消失）:
- `每个实现任务完成后` 消失（frontmatter description）
- `逐任务单独 commit` 不应出现

**验证命令:**

```bash
# RED（改前）: 正断言应为 FAIL
grep -c "批次 SHA 区间" agents/code-reviewer.md   # 预期改前: 0, 改后: ≥1
grep -c "测试规格" agents/code-reviewer.md        # 预期改前: 0, 改后: ≥1
grep -c "计划文件路径" agents/code-reviewer.md    # 预期改前: 0, 改后: ≥1

# GREEN（改后）: 负断言应为空
grep -n "每个实现任务完成后" agents/code-reviewer.md  # 预期: (无输出)

# 正断言复核（改后）
grep -n "批次 SHA 区间\|测试规格\|批次任务清单\|计划文件路径\|逐任务核对" agents/code-reviewer.md
```

**How（留白，依据设计文档 L73-79）:**
- Phase 1/Phase 2 前置/Phase 3 核对项正文，由 executor 依据设计文档撰写。输入契约字段名须与 Task 3 的 Step 6 dispatch 块字段名逐字一致（`计划文件路径`、`批次任务清单`、`测试规格`、`SHA 区间`）。

---

## Task 6: README 文档同步（共享 Subagent 描述 + 批次语义）

**Files:**
- Modify: `README.md:5-13`（概述 — Creative 流程描述，可选）
- Modify: `README.md:25-37`（共享 Subagent 表 — plan-writer / plan-executor / code-reviewer 三行描述）

**接口签名（新增/修改章节）:**

**共享 Subagent 表**（L29-31，三行）:
- `plan-writer`（L29）: 功能描述从「实现计划编写」改为反映「完整规格：WHAT 锁（锚点/测试规格/验证命令）+ HOW 留白 + 批次预标注」。
- `plan-executor`（L30）: 功能描述从「TDD 计划执行 + 防假测试」补充「按批次执行 + 批次单 commit + 抢救协议」。
- `code-reviewer`（L31）: 功能描述从「代码审查 + 假测试检测」补充「按批次 SHA 区间审查 + 逐任务核对测试证据」。

**概述**（L5-13）: Creative 流程描述若含「逐任务」语义则同步为批次语义（此文件当前概述未含逐任务字样，无强制改动；仅与上表联动保持术语一致）。

**测试规格（grep 断言，改前 FAIL / 改后 PASS）:**

正断言（在 `README.md` 中必须出现）:
- `批次` 出现（至少 1 次，反映在共享 Subagent 表的 batch 语义）
- Shared Subagent 表三行描述中反映新语义（通过 `批次` 或等价词体现）

负断言:（README.md 原本无旧逐任务措辞，无强制负断言；确认不引入矛盾表述）

**验证命令:**

```bash
# RED（改前）: 正断言应为 FAIL
grep -c "批次" README.md        # 预期改前: 0, 改后: ≥1

# GREEN（改后）
grep -n "批次\|plan-writer\|plan-executor\|code-reviewer" README.md
```

**How（留白，依据设计文档 L7、L179-185）:**
- 三行功能描述措辞、概述同步由 executor 依据设计文档撰写，与 Task 1/3/4/5 的术语保持一致（`批次`、`WHAT`/`HOW`、`批次单 commit`、`批次 SHA 区间`）。

---

## Task 7: 全局一致性检查（跨文件契约收尾，验证型）

**Files:**
- 无文件为固有修改目标。此任务为**跨文件契约最终核对**。若核对发现缺失/矛盾，修复对应文件（修复内容并入本批次 commit）。

**接口签名（核对的跨文件契约，逐项列出）:**

1. **Creative Step 5 dispatch 块字段 ⊇ executor 输入契约字段**
   - Creative 含: `计划文件路径`、`批次任务清单`、`锚点`、`测试规格`、`SHA 基线`、Required skills
   - executor 声称接受: `计划文件路径`、`批次任务清单`、`锚点`、`测试规格`、`SHA 基线`
   - 核对: executor 的每个输入契约字段在 Creative Step 5 块中都能找到

2. **Creative Step 6 dispatch 块字段 ⊇ reviewer 输入契约字段**
   - Creative 含: `计划文件路径`、`批次任务清单`、`测试规格`、`SHA 区间`
   - reviewer 声称接受: `计划文件路径`、`批次任务清单`、`测试规格`、`SHA 区间`
   - 核对: reviewer 的每个输入契约字段在 Creative Step 6 块中都能找到

3. **术语全局一致:** `批次单 commit`、`抢救 commit`、`批次 SHA 区间` 在 Creative / plan-executor / code-reviewer / plan-writer 四文件间一致出现

4. **负断言全绿:** 所有旧措辞（`完整代码`、`逐任务单独 commit`、`Execute Task N`、`对每个任务: 宣布 → 执行 → 审查`、`每个实现任务完成后`、逐任务 commit 命令）在指定文件中 grep 返回空

5. **git diff 越界检查:** 改动仅触及 6 个目标文件 + 本计划文件；`agents/Debug.md`、`agents/spec-writer.md` 及其他 agents、`skills/`、`docs/specs/`、`install.sh` 未被触碰

**测试规格（grep 断言）:**

正断言（全局）:
- `批次单 commit` 在 agents/Creative.md、agents/plan-executor.md、agents/plan-writer.md 均出现
- `抢救 commit` 在 agents/Creative.md、agents/plan-executor.md 均出现
- `批次 SHA 区间`（或 `SHA 区间`）在 agents/Creative.md、agents/code-reviewer.md 均出现
- `测试规格` 在 Creative/plan-writer/plan-executor/code-reviewer/momus 均出现

负断言（全局，各指定文件 grep 返回空）:
- `完整代码` → agents/plan-writer.md 空
- `逐任务单独 commit` → agents/Creative.md、agents/plan-executor.md、agents/code-reviewer.md 空
- `Task: "Execute Task N"` → agents/Creative.md 空
- `对每个任务: 宣布 → 执行 → 审查` → agents/Creative.md 空
- `每个实现任务完成后` → agents/code-reviewer.md 空

**验证命令:**

```bash
# 跨文件契约 1: Creative Step5 ⊇ executor
echo "=== Creative Step5 字段 ==="
grep -n "批次任务清单\|锚点\|测试规格\|SHA 基线\|计划文件路径" agents/Creative.md
echo "=== executor 输入契约字段 ==="
grep -n "批次任务清单\|锚点\|测试规格\|SHA 基线\|计划文件路径" agents/plan-executor.md
# 人工核对: executor 每个字段在 Creative 输出中能找到

# 跨文件契约 2: Creative Step6 ⊇ reviewer
echo "=== Creative Step6 字段 ==="
grep -n "批次任务清单\|测试规格\|SHA 区间\|计划文件路径" agents/Creative.md
echo "=== reviewer 输入契约字段 ==="
grep -n "批次任务清单\|测试规格\|SHA 区间\|计划文件路径" agents/code-reviewer.md
# 人工核对: reviewer 每个字段在 Creative 输出中能找到

# 术语全局一致
for f in agents/Creative.md agents/plan-executor.md agents/plan-writer.md; do
  echo "$f: 批次单 commit = $(grep -c '批次单 commit' $f)"
done

# 负断言全绿
grep -n "完整代码" agents/plan-writer.md                             # 预期空
grep -rn "逐任务单独 commit" agents/Creative.md agents/plan-executor.md agents/code-reviewer.md  # 预期空
grep -n 'Task: "Execute Task N"' agents/Creative.md                  # 预期空
grep -n "对每个任务: 宣布 → 执行 → 审查" agents/Creative.md            # 预期空
grep -n "每个实现任务完成后" agents/code-reviewer.md                  # 预期空

# git 越界检查
git diff --name-only
# 预期仅包含: agents/Creative.md agents/plan-writer.md agents/plan-executor.md \
#             agents/code-reviewer.md agents/momus.md README.md \
#             以及 docs/plans/2026-08-19-creative-flow-p1-p6.md docs/specs/2026-08-19-creative-flow-p1-p6-design.md
```

**How（留白）:**
- 逐项执行上述核对命令并记录结果。任何一项 FAIL 则修复对应文件使其通过（修复后并入本批次 commit）。全部 PASS 即本批次 Task 7 GREEN，随后执行批次 D 单 commit。

---

## 批次 commit 策略（executor 执行）

**批次 A（Task 1 + Task 2 + 设计文档）:**
```bash
git add agents/plan-writer.md agents/momus.md docs/specs/2026-08-19-creative-flow-p1-p6-design.md
git commit -m "feat(plan): 规格化计划格式 (WHAT 锁/HOW 留白 + 批次预标注) + momus 审查标准联动

- Task 1: plan-writer Phase 2 任务模板改为 WHAT/HOW, 核心原则修订, 新增批次预标注
- Task 2: momus 审查标准改为锚点+测试规格+验证命令, 不要求完整实现代码
- 纳入未提交的设计文档 (P6a 决策)"
```

**批次 B（Task 3）:**
```bash
git add agents/Creative.md
git commit -m "feat(flow): Creative 批次 dispatch 协议 + 抢救协议

- Step 5/6 dispatch 块改为批次粒度, 显式传入批次任务清单/锚点/测试规格/SHA 基线/SHA 区间
- 批内 BLOCKED 抢救 commit + 逐任务状态清单 + 默认单独重派"
```

**批次 C（Task 4 + Task 5）:**
```bash
git add agents/plan-executor.md agents/code-reviewer.md
git commit -m "feat(exec): executor 批次单 commit/抢救协议 + reviewer 批次 SHA 区间审查

- Task 4: executor 逐任务 commit 改为批次单 commit, 新增抢救协议与逐任务状态清单
- Task 5: reviewer 按批次 SHA 区间整批审查 + 逐任务核对测试证据"
```

**批次 D（Task 6 + Task 7）:**
```bash
git add README.md
# 若 Task 7 需修复文件, 一并 git add 对应文件
git commit -m "docs(readme): 共享 Subagent 描述同步批次语义 + 跨文件契约一致性确认"
```

**BLOCKED 抢救 commit 模板（任一批次中途 BLOCKED 时）:**
```bash
# 对已完成且测试通过的任务
git add <已完成任务的成果文件>
git commit -m "wip(抢救): 批次 X 部分完成 (Task P, Q), 保留已通过成果

- 已完成并测试通过: Task P, Q
- BLOCKED: Task R — <原因>
- 供重派 executor 面对干净基线"
```

---

## 最终全局一致性检查清单（跨文件契约逐项断言）

> 由 Task 7 执行。此项亦作为 momus 评审本计划时的核对参考。

| # | 断言 | 检查命令 | 预期 |
|---|------|----------|------|
| 1 | Creative Step5 ⊆ executor 契约 | 见 Task 7 验证命令 | executor 每字段在 Creative 中有对应 |
| 2 | Creative Step6 ⊆ reviewer 契约 | 见 Task 7 验证命令 | reviewer 每字段在 Creative 中有对应 |
| 3 | `批次单 commit` 三文件一致 | `grep -c 批次单 commit` ×3 | Creative/executor/plan-writer 均 ≥1 |
| 4 | `抢救 commit` 两文件一致 | `grep -c 抢救 commit` ×2 | Creative/executor 均 ≥1 |
| 5 | `批次 SHA 区间` 两文件一致 | `grep -c` ×2 | Creative/reviewer 均 ≥1 |
| 6 | `测试规格` 五文件一致 | `grep -c` ×5 | Creative/plan-writer/executor/reviewer/momus 均 ≥1 |
| 7 | 负断言: 旧措辞全消失 | 见 Task 7 验证命令 | 全部 grep 返回空 |
| 8 | git diff 不越界 | `git diff --name-only` | 仅 6 目标文件 + 计划 + 设计文档 |
| 9 | HOW 留白合法性 | `grep -n "HOW" plan-writer` | HOW 留白被 plan-writer 与 momus 双重声明（非缺陷） |
| 10 | 设计文档未越界修改 | `git status docs/specs/` | 设计文档仅纳入不修改 |

---

## 输出

```
计划路径: docs/plans/2026-08-19-creative-flow-p1-p6.md
任务数量: 7
批次: 4（A: Task1+2 / B: Task3 / C: Task4+5 / D: Task6+7）
关键依赖: Task1→(术语源头) Task3→Task4/5(dispatch 契约上游); Task7 依赖 Task1-6(最终收尾)
状态: 待 momus 评审
```
