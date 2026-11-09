# Epic: 重构即设计 —— 单一循环、单一坏味道目录、四场景主线

**来源**：`/tmp/opencode/redesign-plan.md`（唯一事实源，第 36/80/99/168 行已更正安全网归属）+ 用户拍板补充（全量 4 批 / Fix 童子军限定 / Feature 留白清单条件 / 统一循环方案 A / 无测试自补安全网三分类）。
**范围**：4 批 + 1 个 B1 修正批，**34 个唯一文件**（40 次文件触达；`agents/Fix.md` 在 S3、S7、S24 各一次），含 **4 个删除 + 2 个新建**。

---

## 一、Epic 目标

1. 设计与重构的顺序倒过来：设计只产出最小决策 + 留白清单，结构由坏味道在重构时长出。
2. 场景合并：`Legacy` 不再是 primary 场景；无测试不再切场景——改动点无覆盖由 Feature/Fix/story-executor **自己补安全网**后继续 TDD，Refactor 只在整段存量代码行为保持型重构时进入。
3. **重构循环只有一个实现**：`refactor-executor` 自控循环；Feature/Fix 的 REFACTOR 阶段与 Refactor 场景都调用它，各自只传 `scope / mode / 基线 / 轮次上限`。
4. **坏味道只有一个家**：`smells-catalog.md` 统一名称 + 特征 + 首选手法；`smells-classic.md` / `smells-agent.md` 删除。
5. 统一「何时读什么」：6 个核心 skill 各有「何时读 / 何时不读」，AGENTS.md 承载全局时机表。
6. 抽象闸门统一：同一概念**第二次变化**才抽象；接口数 > 真实变体数 → AWAY。
7. 童子军规则有硬边界，不成为夹带手段。
8. **安全网三分类**：新增代码 → 直接 TDD；既有代码缺测试但能直接写测试 → 直接补测试；既有代码难测 → 才用 legacy-code（找接缝 → 特征测试 → 解依赖）。legacy-code 条件加载，非常驻。

## 二、非目标（Epic 级不做什么）

- 不引入 CI / 结对 / 计划扑克 / 迭代长度等团队实践。
- 不新增 skill 目录；「重构即设计」只作为 `design` 的 reference。
- 不改 `code-reviewer` 的 Critical / Important 分级口径；只改 profile=refactor 的核对对象措辞。
- 不改 `QAExplorer`；不改 `Fix` 的复现 / 根因 / 假设三段方法论。
- 不重写 `legacy-analyst` / `legacy-executor` 的 L0–L4 内部流程（只改入口归属）。
- 不让 Refactor 改行为：唯一验收 = 行为不变；行为变更退回 Feature。
- 不把「改动点无测试」当成切 Refactor 的理由；不把 legacy-code 写成常驻加载。
- 不把循环步骤写进 `Refactor.md` 或 `story-executor.md`（只允许在 `refactor-executor.md` 有一份）。
- 不把任何 skill 改成「全量通读」；references 按索引单点打开。

## 三、核心设计决策

| # | 落点 | 落地位置 |
|---|------|----------|
| D1 | 设计只做最小决策：目标/非目标 + 接口契约 + 留白清单；不预选模式 | `agents/Feature.md` S3、`skills/design/SKILL.md` S9 |
| D2 | 稳定中间形式：先到可工作的最直白形态，重复出现第二次再抽象 | 新增 `design/references/refactoring-as-design.md` S10 |
| D3 | 无测试不是独立场景，也不是切 Refactor 的理由：改动点无覆盖在自己流程内补安全网 | `AGENTS.md` S1/S24、`agents/Feature.md` S3/S24、`agents/story-executor.md` S5/S24、删除 `agents/Legacy.md` S3 |
| D4 | 统一时机表：6 skill 只在触发点加载 | `AGENTS.md` S1 + 各 SKILL S9/S15/S18/S19/S20/S22/S23 |
| D5 | 童子军规则限定：同一函数 / 有测试 / 独立 commit / ≤10 行；超出记台账交 Refactor | `agents/Fix.md` S7、`skills/refactoring/SKILL.md` S15 |
| D6 | **Refactor = 存量腐坏代码的重构通道**，不是新功能的设计阶段 | `agents/Refactor.md` S2、`AGENTS.md` S1 |
| D7 | **统一循环**：`refactor-executor` 自控七步，两个入口只差安全网前置与 scope | `agents/refactor-executor.md` S6、`agents/story-executor.md` S5、`agents/Refactor.md` S2 |
| D8 | **坏味道单一事实源**：`smells-catalog.md`；删 classic/agent | `skills/refactoring/references/smells-catalog.md` S16、S17 |
| D9 | `refactor-planner` 退役、`momus` 退出 Refactor | S2/S4、`AGENTS.md` S1、`README.md` S8 |
| D10 | **安全网归属修正**（B1 执行后的语义纠偏）：自补安全网三分类；Refactor 先评估覆盖 | S24 |

### 两种设计的边界

**Refactor 边界定义**

| 维度 | 内容 |
|---|---|
| 对象 | 已积累大量坏味道、设计变形的既有代码；**可能完全没有测试** |
| 第一步 | **先评估 scope 的现有测试覆盖**：已覆盖 → 直接进重构循环；未覆盖 → 安全网（legacy-analyst 侦察 → legacy-executor 建网：找接缝 → 特征测试锁现状 → 解依赖）；先有测试再动结构 |
| 主体 | 调用 `refactor-executor` 自控循环；Refactor 只负责范围收敛与安全网前置（不代替 Feature/Fix 补改动点的测试） |
| 上模式 | 循环内结构指向已知模式时用 refactoring-to-patterns（TO / TOWARDS / AWAY），过 YAGNI 三问 |
| 不做什么 | 不改行为、不加功能、不顺手扩大范围；行为变更退回 Feature |
| 唯一验收 | **行为不变**（测试期望值不变）+ 聚焦点无 Critical/Major |

**Feature / Fix（边写边设计）vs Refactor（存量腐坏）**

| | Feature / Fix | Refactor |
|---|---|---|
| 设计方式 | TDD 边写边设计：测试定接口，重构定结构 | 安全网就位后，同样走「扫描→决策→执行」循环 |
| 重构时机 | 每故事 GREEN 后立刻 dispatch 循环子 agent | 独立场景，范围收敛后调用同一个循环子 agent |
| 触发 | 本次改动引入或触碰到的坏味道；改动点无覆盖 → 自己补安全网（新增代码直接 TDD） | 存量腐坏：跨模块、多坏味道、设计已变形；进入后先评估覆盖 |
| 交付 | 行为变更 + 本故事代码无坏味道 | **零行为变更** + 聚焦点无 Critical/Major |

**统一循环（唯一实现在 `refactor-executor.md`）**

```
入参：scope / mode(tdd|legacy) / 基线（命令 + N passed）/ 轮次上限
循环：1 扫描（坏味道 24 类 + A1-A7 + design 职责 + functional 简化）
     → 2 选择（影响面 > 因果上游 > 改动风险）
     → 3 决策（常规手法 / 重构到模式 / 已无 Critical/Major → 结束）
     → 4 执行（一次一种，最小步，不改行为）
     → 5 验证（全量绿 + 期望值不变；红 → 回滚并停止）
     → 6 记账（台账追加本轮）
     → 7 判断（还有 Critical/Major → 回 1；只剩 Minor → 结束）
出参：每轮记录 + 最终扫描结论 + REFACTOR_LEDGER
```

---

## 四、契约（输入状态 → 输出状态，每文件一句）

### 全局不变式（G1–G9）

- **G1** `./scripts/lint-skills.sh` 末尾输出 `lint-skills: OK`，退出码 0。
- **G2** 不新增 `skills/<new-skill>/` 目录；`skills/*/SKILL.md` 目录数不增加。
- **G3** 每个新增/修改的 reference 含字面量 `SKILL.md`（反向链接）且被对应 `SKILL.md` 用 `references/<name>.md` 命中。
- **G4** 6 个核心 skill（design / functional / refactoring / refactoring-to-patterns / legacy-code / testing-techniques）各有且仅有一处「何时读」和一处「何时不读」。
- **G5** `legacy-analyst`、`legacy-executor` 文件保留；只由 `Refactor` 调度。
- **G6** `code-reviewer` 的 Critical / Important 判级段落零 diff（只改 profile=refactor 的核对对象措辞）。
- **G7** `agents/Refactor.md` 无「档位」、无 `refactor-planner` / `momus`；`agents/refactor-planner.md` 不存在。
- **G8** 单一事实源：坏味道名称/特征/手法 → `smells-catalog.md`；手法步骤 → `techniques.md`；模式结构 → `gof.md`；演化路径 → `evolution.md`；解依赖技术 → `dependency-breaking.md`。
- **G9** 重构循环只有一份实现（`agents/refactor-executor.md`）；`Refactor.md` / `story-executor.md` 只写 dispatch 契约，不写七步细节。

### 逐文件契约

| 编号 | 文件 | 输入状态 → 输出状态 |
|------|------|---------------------|
| C1 | `AGENTS.md` | 5 场景 + Refactor 两档 + momus 评计划 → 4 场景 + 两种设计边界 + 时机表 + Refactor 无档位、调用循环子 agent、planner/momus 移出；无覆盖自补安全网（三分类）、新增代码直接 TDD |
| C2 | `agents/Refactor.md` | 档位 + planner/momus + 批处理 → 范围收敛 + 先评估覆盖 + 安全网（未覆盖才派 legacy-*）+ dispatch 循环 + 审查 + 收尾（不写循环细节） |
| C3 | `agents/Legacy.md` | 存在的 primary agent → 文件不存在 |
| C4 | `agents/refactor-planner.md` | 存在的 subagent → 文件不存在 |
| C5 | `agents/Feature.md` | Step 1「关键选择」→ 目标/非目标 + 契约 + 留白清单；每故事 dispatch 循环；无 Legacy 引用；改动点无覆盖自补安全网（三分类）、legacy-code 条件加载 |
| C6 | `agents/story-executor.md` | 自己重构 + `task` 无 executor → REFACTOR 阶段 dispatch `refactor-executor`（mode=tdd）+ `task: refactor-executor: allow`；Triangulation 语义修正；无覆盖自补安全网、不返回 BLOCKED |
| C7 | `agents/Fix.md` | 4B 直调 legacy-* + 无童子军 + Legacy 引用 → 自补安全网（三分类）+ 童子军四限 + 零 Legacy |
| C8 | `agents/metis.md` | 5 场景含 Legacy + Refactor 档位 + 下游 planner → 4 场景 + 安全网 + 无 planner |
| C9 | `agents/momus.md` | 三类输入含 refactor-plan + Legacy 引用 → 两类输入（story / legacy-report），无计划评审 |
| C10 | `agents/branch-finisher.md` | 变更来源含 Legacy → 仅 Feature / Fix / Refactor |
| C11 | `agents/legacy-analyst.md` | 「用于 Legacy 场景入口」→「由 Refactor 安全网阶段调度」；H1 不改 |
| C12 | `agents/legacy-executor.md` | 「用于 Legacy 场景执行阶段」→「由 Refactor 安全网阶段调度」；H1 不改 |
| C13 | `agents/refactor-executor.md` | 按 planner 计划分批 → 自控七步循环；入参 scope/mode/基线/轮次上限；出参每轮记录 + 结论 + 台账 |
| C14 | `agents/code-reviewer.md` | profile=refactor 核对「计划步 + 台账」→ 核对「整分支 diff + REFACTOR_LEDGER」；分级口径不变 |
| C15 | `README.md` | 五场景 + Legacy 章节 + planner → 四场景 + 统一循环 + 安全网 + 无 planner |
| C16 | `skills/design/SKILL.md` | 单一设计流程 → 设计三档 + 何时不设计 + 第二次变化闸门 + 索引新 reference + 何时读/不读 |
| C17 | `skills/design/references/refactoring-as-design.md` | 不存在 → 存在，≤80 行，4 书论断/稳定中间形式/留白模板/反例，带 `SKILL.md` 反链 |
| C18 | `skills/design/references/analysis-uml.md` | 「分析设计混在一起 = 都没想清」→ 连续迭代 + 七步工序 + UML 何时不必画 |
| C19 | `skills/design/references/gof.md` | 仅 23 模式目录 → 增加「症状 → 候选模式」反查表 + LoD + 共同重用全称消歧 |
| C20 | `skills/design/references/grasp.md` | Booch 附录缺链接/对象语义 → 补入附录，总行数 ≤100 |
| C21 | `skills/design/references/contracts.md` | 仅新增契约 → 增加「重构触及公开签名后复检前置/后置/不变式」 |
| C22 | `skills/refactoring/SKILL.md` | 索引指向 smells-classic/agent + 使用者含 planner → 索引指向 smells-catalog；重构是设计工具 + 童子军四限 + 何时读/不读 |
| C23 | `skills/refactoring/references/smells-catalog.md` | 不存在 → 存在，150–200 行带目录；8 分区；名称/特征/来源/首选手法/误用条件 |
| C24 | `skills/refactoring/references/smells-classic.md` | 存在的 reference → 文件不存在（内容并入 C23） |
| C25 | `skills/refactoring/references/smells-agent.md` | 存在的 reference → 文件不存在（内容并入 C23） |
| C26 | `skills/refactoring/references/techniques.md` | 手法速查 + 3 手法一行用途 → 补 3 手法步骤、Optional/Assertion 边界；坏味道名称行移除 |
| C27 | `skills/refactoring/references/workflow.md` | 流程未指向 catalog → 引用 smells-catalog，无 classic/agent 残留 |
| C28 | `skills/refactoring-to-patterns/SKILL.md` | 使用者含 planner + 无停止判据 → TOWARDS 3 条停止判据 + 接口数红线 + 删除重复坏味道表 + 何时读/不读 |
| C29 | `skills/refactoring-to-patterns/references/evolution.md` | 内含「坏味道→目标模式」表 + 指向 smells-classic → 表移除、指针改 smells-catalog |
| C30 | `skills/legacy-code/SKILL.md` | 无策略入口 → 四大策略入口 + 可测性坏味道引用 catalog + 何时读/不读 |
| C31 | `skills/legacy-code/references/seams.md` | 无依赖选择判据 → 「特征测试用真实依赖还是替身」判据 |
| C32 | `skills/legacy-code/references/dependency-breaking.md` | 24 技术均一行用途 → 技术 1–8 各有 `→` 操作步骤，9–24 保持一行 |
| C33 | `skills/testing-techniques/SKILL.md` | 仅测试质量 → 增加「测试即设计工具」段 + 何时读/不读 |
| C34 | `skills/functional/SKILL.md` | 仅有边界表 → 增加显式「何时读 / 何时不读」行 |

**新增对外接口**：无（本项目无编译单元，接口 = 文件形态与命令输出）。

---

## 五、无测试项目的 RED 证据定义（story-executor 按此验收）

本仓库全是 markdown，无编译、无单测。**每个故事的 RED / GREEN 一律用只读命令定义**：

- **RED** = 下列之一：
  1. `./scripts/lint-skills.sh` 输出含 `MISSING` / `ORPHAN` / `NO-BACK` / `NO-TOC` 或退出码非 0；
  2. `grep` / `wc` 结果等于「改动前旧状态」的期望值（旧表述命中 > 0、新表述 = 0、行数越界）。
- **GREEN** = 同一命令输出等于 AC 期望值，且 `./scripts/lint-skills.sh` 输出 `lint-skills: OK`。

**`BASE` 定义**：本文所有 `git diff <BASE>..<HEAD>` 中的 `<BASE>` = 该批次 dispatch 时的 HEAD（批次起始 commit）。executor 在批次开始时记录 `BASE=$(git rev-parse HEAD)` 并写入批次报告。

**命令约束**：所有 `grep` 必须带明确文件或目录路径（`<file>`、`skills/refactoring/references/…`、`agents/`），禁止裸 `grep` 依赖 cwd 递归。

**禁止**：为让 grep 通过而注释旧表述、把新行塞进代码块、或新增无关同义行刷命中。审查以 `git diff <BASE>..<HEAD> -- <file>` 人工核对语义。

---

## 六、故事清单

### B1 主线（契约批，串行，8 故事 / 15 文件）

文件集：`AGENTS.md`、`agents/Refactor.md`、`agents/Legacy.md`(删)、`agents/refactor-planner.md`(删)、`agents/Feature.md`、`agents/story-executor.md`、`agents/Fix.md`、`agents/metis.md`、`agents/momus.md`、`agents/branch-finisher.md`、`agents/legacy-analyst.md`、`agents/legacy-executor.md`、`agents/refactor-executor.md`、`agents/code-reviewer.md`、`README.md`

---

#### S1 [enabler] AGENTS.md 四场景 + 两种设计边界 + 时机表

**AC**
1. `grep -c "Legacy" AGENTS.md` = **0**；`grep -c "^| Legacy |" AGENTS.md` = **0**。
2. 时机表 7 行全部是表格行且首格为「建模」（无括注）：`grep -cE "^\| *(需求→接口|建模|写测试|实现|第一次出现重复|同一概念第二次变化|审查) *\|" AGENTS.md` = **7**。
3. 两种设计边界表：`grep -c "边写边设计" AGENTS.md` ≥ **1**；`grep -c "存量腐坏" AGENTS.md` ≥ **1**；`grep -cE "^\| *(设计方式|重构时机|触发|交付) *\|" AGENTS.md` = **4**；「触发」行含自补安全网语义：`grep -c "改动点无覆盖\|自己补安全网" AGENTS.md` ≥ **1**。
4. Refactor 无规模档位：`grep -cE "Refactor.*(轻量档|完整档)|Refactor：(单一坏味道|多处坏味道)" AGENTS.md` = **0**；`grep -cE "是否先收敛范围|规模只影响" AGENTS.md` ≥ **1**。
5. 统一循环入口：`grep -c "循环子 agent\|重构循环" AGENTS.md` ≥ **1**；`grep -c "refactor-executor" AGENTS.md` ≥ **1**。
6. planner 退役、momus 不评 Refactor：`grep -c "refactor-planner" AGENTS.md` = **0**；`grep -c "重构计划" AGENTS.md` = **0**。
7. 子代理表保留两者且 executor 描述含安全网：`grep -c "legacy-analyst\|legacy-executor" AGENTS.md` ≥ **2**；`grep -c "Refactor.*安全网" AGENTS.md` ≥ **1**。
8. 场景表 4 行且第 2 行是 Refactor（行为不变）：`grep -cE "^\| *[1-4] *\| *(Fix|Refactor|Feature|QAExplorer)" AGENTS.md` = **4**；`grep -cE "^\| *2 \|.*Refactor" AGENTS.md` = **1**；无「无测试→Refactor」行：`grep -cE "^\| *2 \|.*无测试.*Refactor" AGENTS.md` = **0**。
9. 无覆盖自补安全网、Refactor 先评估、三分类优先级：`grep -c "自己补安全网" AGENTS.md` ≥ **1**；`grep -c "先评估" AGENTS.md` ≥ **1**；TDD 段无转交语义：`grep -c "不.*转交\|自己补" AGENTS.md` ≥ **1**；`grep -cE "新增代码直接 TDD|白纸" AGENTS.md` ≥ **1**；`grep -cE "既有.*无覆盖|仅.*既有" AGENTS.md` ≥ **1**；能直接补测试不走重技术 `grep -cE "能直接.*测试|直接补测试|容易.*测试" AGENTS.md` ≥ **1**；难测判据 `grep -cE "难测|无法构造|依赖硬编码|全局.*状态" AGENTS.md` ≥ **1**。

**验证命令**
- RED: `grep -c "Legacy" AGENTS.md` → >0；`grep -c "需求→接口" AGENTS.md` → 0
- GREEN: 上述 9 条成立；`./scripts/lint-skills.sh` → `lint-skills: OK`

**不做什么**：不改输出风格 / 红线 / 反合理化 / Build / vcpkg / 分支提交段；不新增场景；不改 Feature 三档阈值；不动 Fix 的 5 步；不把七步循环抄进 AGENTS；不保留「无测试 → 停下转交 Refactor」表述。

**批次**：B1

---

#### S2 [enabler] Refactor.md 重写：收敛 + 安全网 + dispatch 循环

**AC**
1. 定位与唯一验收：`grep -c "存量腐坏代码" agents/Refactor.md` = **1**；`grep -c "行为不变" agents/Refactor.md` ≥ **2**。
2. 无档位 / 无 Legacy / 无 planner / 无 momus：`grep -c "档位" agents/Refactor.md` = **0**；`grep -c "Legacy" agents/Refactor.md` = **0**；`grep -c "refactor-planner" agents/Refactor.md` = **0**；`grep -c "momus" agents/Refactor.md` = **0**。
3. 不重写循环：`grep -c "扫描 → 选择\|扫描→选择" agents/Refactor.md` = **0**；`grep -c "记账" agents/Refactor.md` = **0**；`grep -c "轮次上限" agents/Refactor.md` = **0**；且 `grep -c "分批" agents/Refactor.md` = **0**。
4. 只做 dispatch：`grep -c "refactor-executor" agents/Refactor.md` ≥ **2**；`grep -c "dispatch" agents/Refactor.md` ≥ **2**。
5. 范围收敛：`grep -c "聚焦点" agents/Refactor.md` ≥ **2**；`grep -c "200 行" agents/Refactor.md` = **1**；`grep -cE ">1 类|> 1 类" agents/Refactor.md` ≥ **1**；`grep -c "收敛" agents/Refactor.md` ≥ **2**。
6. 安全网：`grep -c "先有测试再重构" agents/Refactor.md` ≥ **1**；`找接缝` / `特征测试` / `解依赖` 各 ≥1 次。
7. 审查契约钉死：`grep -c "profile=refactor" agents/Refactor.md` ≥ **1**；`grep -c "REFACTOR_LEDGER" agents/Refactor.md` ≥ **1**；`grep -c "整分支" agents/Refactor.md` ≥ **1**；`grep -c "code-reviewer" agents/Refactor.md` ≥ **1**。
8. 停止判据：`grep -c "停止判据" agents/Refactor.md` ≥ **1**；`grep -c "连续一轮" agents/Refactor.md` ≥ **1**。
9. permission.task：`grep -c "^    refactor-executor: allow" agents/Refactor.md` = **1**；`grep -c "^    legacy-analyst: allow" agents/Refactor.md` = **1**；`grep -c "^    legacy-executor: allow" agents/Refactor.md` = **1**；`grep -c "^    refactor-planner: allow" agents/Refactor.md` = **0**；`grep -c "^    momus: allow" agents/Refactor.md` = **0**。
10. 重构到模式出口：`grep -c "refactoring-to-patterns" agents/Refactor.md` ≥ **1**；`grep -c "TO / TOWARDS / AWAY\|TO/TOWARDS/AWAY" agents/Refactor.md` ≥ **1**。

**验证命令**
- RED: `grep -c "档位" agents/Refactor.md` → >0；`grep -c "存量腐坏代码" agents/Refactor.md` → 0
- GREEN: 上述 10 条成立；`./scripts/lint-skills.sh` → OK

**不做什么**：不写 A–G 七步、不写轮次上限、不写记账格式；不保留 planner/momus 调用；不引入档位表；不复制 legacy-* 的 L0–L4 细节；不改「行为变更退回 Feature」。

**批次**：B1

---

#### S3 [enabler] Legacy 退场 + Feature 最小设计（含 Feature/Fix 引用收尾）

**Files**：删除 `agents/Legacy.md`；`agents/Feature.md`、`agents/Fix.md`、`agents/branch-finisher.md`、`agents/legacy-analyst.md`、`agents/legacy-executor.md`

**AC**
1. `test ! -f agents/Legacy.md` → 退出码 0。
2. Feature 零 Legacy：`grep -c "Legacy" agents/Feature.md` = **0**（覆盖原 251/361 行）；Fix 零 Legacy：`grep -c "Legacy" agents/Fix.md` = **0**（覆盖原 56/126 行）；branch-finisher 零 Legacy：`grep -c "Legacy" agents/branch-finisher.md` = **0**。
3. 两 subagent 场景名清零、H1 保留：`grep -c "Legacy 场景" agents/legacy-analyst.md` = **0**；`grep -c "Legacy 场景" agents/legacy-executor.md` = **0**；`grep -c "^# Legacy-Analyst" agents/legacy-analyst.md` = **1**；`grep -c "^# Legacy-Executor" agents/legacy-executor.md` = **1**。
4. 入口归属：`grep -c "Refactor 安全网" agents/legacy-analyst.md` ≥ **1**；`grep -c "Refactor 安全网" agents/legacy-executor.md` ≥ **1**。
5. branch-finisher 来源三选：`grep -c "Feature / Fix / Refactor" agents/branch-finisher.md` = **1**。
6. Feature 最小设计：`grep -c "留白清单" agents/Feature.md` ≥ **2**；`grep -cE "≥ ?2 ?个候选|本可以引入抽象" agents/Feature.md` ≥ **1**；`grep -c "平凡改动\|无需留白" agents/Feature.md` ≥ **1**；`grep -c "关键选择" agents/Feature.md` = **0**。
7. Feature 每故事 dispatch 循环：`grep -c "refactor-executor" agents/Feature.md` ≥ **1**；`grep -c "不跨故事积累\|及时重构" agents/Feature.md` ≥ **1**。
8. Feature/Fix 的最小决策骨架仍在：`grep -c "非目标" agents/Feature.md` ≥ **1**；`grep -c "前置 / 后置 / 不变式" agents/Feature.md` ≥ **1**。
9. subagent 的 L0/L2 主体不动：`grep -c "L0" agents/legacy-analyst.md` ≥ **1**；`grep -c "L2" agents/legacy-executor.md` ≥ **1**。
10. Feature 自补安全网与 legacy-code 条件加载：`grep -c "自己补安全网" agents/Feature.md` ≥ **1**；`grep -c "legacy-code" agents/Feature.md` ≥ **1**；条件加载措辞 `grep -cE "条件|仅.*遗留|既有.*无覆盖" agents/Feature.md` ≥ **1**；触发限定 `grep -cE "既有|遗留代码" agents/Feature.md` ≥ **1**；新增代码直接 TDD `grep -cE "新增代码|白纸|新代码" agents/Feature.md` ≥ **1**；能直接补测试不走重技术 `grep -cE "能直接.*测试|直接补测试|容易.*测试" agents/Feature.md` ≥ **1**；难测判据 `grep -cE "难测|无法构造|依赖硬编码|全局.*状态" agents/Feature.md` ≥ **1**。

**验证命令**
- RED: `test ! -f agents/Legacy.md` → 非 0；`grep -c "Legacy" agents/Feature.md` → >0
- GREEN: 10 条成立；`./scripts/lint-skills.sh` → OK

**不做什么**：不删 `skills/legacy-code/**`；不删两个 subagent 文件；不改 H1；不把 L0–L4 搬进 Refactor；不改 Fix 的五步主流程（童子军在 S7）；不用 `grep -rn ... agents/` 做本故事 AC；不把 legacy-code 写成 Feature 的常驻加载。

**批次**：B1

---

#### S4 [enabler] refactor-planner 退役 + metis/momus 对齐

**Files**：删除 `agents/refactor-planner.md`；`agents/metis.md`、`agents/momus.md`

**AC**
1. `test ! -f agents/refactor-planner.md` → 退出码 0。
2. metis 四场景、零 Legacy、零 planner：`grep -c "Legacy" agents/metis.md` = **0**；`grep -c "4 个执行场景" agents/metis.md` ≥ **1**；`grep -c "refactor-planner" agents/metis.md` = **0**。
3. metis 不给 Refactor 档位、指向安全网：`grep -cE "Refactor：(单一坏味道|多处坏味道)" agents/metis.md` = **0**；`grep -c "安全网" agents/metis.md` ≥ **1**；`grep -c "循环子 agent\|refactor-executor" agents/metis.md` ≥ **1**。
4. momus 两类输入、零 plan、零 Legacy：`grep -c "refactor-plan" agents/momus.md` = **0**；`grep -c "重构计划" agents/momus.md` = **0**；`grep -c "Legacy" agents/momus.md` = **0**（覆盖原 94 行）；`grep -cE "^\| \`(story|legacy-report)\`" agents/momus.md` = **2**。
5. momus 只服务 Feature：`grep -c "用于 Feature Step 3" agents/momus.md` ≥ **1**；`grep -c "input_type: refactor-plan" agents/momus.md` = **0**。

**验证命令**
- RED: `grep -c "refactor-planner" agents/metis.md` → >0；`grep -c "refactor-plan" agents/momus.md` → >0
- GREEN: 5 条成立；`./scripts/lint-skills.sh` → OK

**不做什么**：不把 planning 责任转给 refactor-executor；不删 momus 的 story / legacy-report 能力；不改 code-reviewer；不新增 agent 文件；metis 的中文「遗留改造」小节可保留但不出现 Legacy 场景名。

**批次**：B1

---

#### S5 [enabler] story-executor：REFACTOR 阶段 dispatch 循环 + Triangulation

**AC**
1. 零 Legacy：`grep -c "Legacy" agents/story-executor.md` = **0**；`grep -c "BLOCKED(需 legacy-executor)" agents/story-executor.md` = **0**。
2. 无测试不转交、自己补安全网 + 三分类优先级：`grep -c "BLOCKED(需 Refactor" agents/story-executor.md` = **0**；`grep -c "自己补安全网" agents/story-executor.md` ≥ **1**；`grep -c "legacy-code" agents/story-executor.md` ≥ **1**；条件加载 `grep -cE "条件|仅.*遗留|既有.*无覆盖" agents/story-executor.md` ≥ **1**；触发限定 `grep -cE "既有|遗留代码" agents/story-executor.md` ≥ **1**；新增代码直接 TDD `grep -cE "新增代码|白纸|新代码" agents/story-executor.md` ≥ **1**；能直接补测试不走重技术 `grep -cE "能直接.*测试|直接补测试|容易.*测试" agents/story-executor.md` ≥ **1**；难测判据 `grep -cE "难测|无法构造|依赖硬编码|全局.*状态" agents/story-executor.md` ≥ **1**。
3. REFACTOR 改为 dispatch：`grep -c "refactor-executor" agents/story-executor.md` ≥ **2**；`grep -c "mode=tdd\|mode = tdd" agents/story-executor.md` ≥ **1**。
4. 新增权限：`grep -c "^    refactor-executor: allow" agents/story-executor.md` = **1**。
5. 及时重构定位：`grep -c "循环内及时设计\|不跨故事积累" agents/story-executor.md` ≥ **1**。
6. 不重写循环：`grep -c "轮次上限" agents/story-executor.md` = **0**；`grep -c "记账" agents/story-executor.md` = **0**。
7. Triangulation 修正：`grep -c "怕过度泛化" agents/story-executor.md` = **0**；`grep -c "第二个样例" agents/story-executor.md` ≥ **1**；`grep -c "Triangulation" agents/story-executor.md` = **1**。
8. 批次协议与台账不动：`grep -c "REFACTOR_LEDGER" agents/story-executor.md` ≥ **1**；`grep -c "批次单 commit" agents/story-executor.md` ≥ **1**。

**验证命令**
- RED: `grep -c "怕过度泛化" agents/story-executor.md` → 1（唯一 RED 依据）；`grep -c "Legacy" agents/story-executor.md` → 0（实测基线，非 RED 依据）
- GREEN: 8 条成立；`./scripts/lint-skills.sh` → OK

**不做什么**：不改 RED / GREEN 判定与测试粒度；不改批次协议与台账 11 项；不写七步入参细节（只写 dispatch 契约）；不改 Fake It / Obvious Implementation；不写「无测试 → 返回 BLOCKED / 转交 Refactor」。

**批次**：B1

---

#### S6 [enabler] refactor-executor：自控七步循环（唯一实现）

**AC**
1. 入参四件套：`grep -c "scope" agents/refactor-executor.md` ≥ **1**；`grep -c "mode" agents/refactor-executor.md` ≥ **1**；`grep -c "基线" agents/refactor-executor.md` ≥ **1**；`grep -c "轮次上限" agents/refactor-executor.md` ≥ **1**。
2. 七步动词各 ≥1 次：`扫描` / `选择` / `决策` / `执行` / `验证` / `记账` / `判断`（均 `grep -c "<词>" agents/refactor-executor.md`）。
3. 三扫描源：`grep -c "A1-A7" agents/refactor-executor.md` ≥ **1**；`grep -c "design" agents/refactor-executor.md` ≥ **1**；`grep -c "functional" agents/refactor-executor.md` ≥ **1**。
4. 出参三件：`grep -c "每轮记录" agents/refactor-executor.md` ≥ **1**；`grep -c "最终扫描结论" agents/refactor-executor.md` ≥ **1**；`grep -c "REFACTOR_LEDGER" agents/refactor-executor.md` ≥ **1**。
5. 零计划依赖：`grep -c "按计划" agents/refactor-executor.md` = **0**；`grep -c "refactor-planner" agents/refactor-executor.md` = **0**；`grep -c "B1/B2" agents/refactor-executor.md` = **0**；`grep -c "分批" agents/refactor-executor.md` = **0**。
6. 行为保持与回滚：`grep -c "回滚" agents/refactor-executor.md` ≥ **1**；`grep -c "期望值不变" agents/refactor-executor.md` ≥ **1**。
7. 模式闸门：`grep -c "YAGNI" agents/refactor-executor.md` ≥ **1**；`grep -c "TO/TOWARDS/AWAY\|TO / TOWARDS / AWAY" agents/refactor-executor.md` ≥ **1**。
8. 两入口：`grep -c "tdd" agents/refactor-executor.md` ≥ **1**；`grep -c "legacy" agents/refactor-executor.md` ≥ **1**。

**验证命令**
- RED: `grep -c "按计划" agents/refactor-executor.md` → >0；`grep -c "轮次上限" agents/refactor-executor.md` → 0
- GREEN: 8 条成立；`./scripts/lint-skills.sh` → OK

**不做什么**：不保留「按计划/分批」语义；不把 planner 逻辑塞回来；不改 code-reviewer；不写并行批次；不做行为变更。

**批次**：B1

---

#### S7 [enabler] Fix：童子军四限 + 4B 自补安全网（与 S3 同文件）

**AC**
1. 零 Legacy / 零 legacy 调度：`grep -c "Legacy" agents/Fix.md` = **0**；`grep -c "legacy-analyst" agents/Fix.md` = **0**；`grep -c "legacy-executor" agents/Fix.md` = **0**；`grep -c "^    legacy-" agents/Fix.md` = **0**。
2. 童子军四限：`grep -c "童子军" agents/Fix.md` ≥ **1**；`grep -c "同一函数" agents/Fix.md` ≥ **1**；`grep -c "独立 commit" agents/Fix.md` ≥ **1**；`grep -c "≤ ?10 ?行\|10 行" agents/Fix.md` ≥ **1**。
3. 越界处置 + 自补安全网 + 三分类优先级：`grep -c "台账" agents/Fix.md` ≥ **1**；`grep -c "Refactor" agents/Fix.md` ≥ **2**；`grep -c "自己补安全网" agents/Fix.md` ≥ **1**；`grep -c "legacy-code" agents/Fix.md` ≥ **1**；条件加载 `grep -cE "条件|仅.*遗留|既有.*无覆盖" agents/Fix.md` ≥ **1**；触发限定 `grep -cE "既有|遗留代码" agents/Fix.md` ≥ **1**；能直接补测试不走重技术 `grep -cE "能直接.*测试|直接补测试|容易.*测试" agents/Fix.md` ≥ **1**；难测判据 `grep -cE "难测|无法构造|依赖硬编码|全局.*状态" agents/Fix.md` ≥ **1**。
4. profile 不含 legacy：`grep -c "profile=\[feature|legacy\]" agents/Fix.md` = **0**；`grep -c "profile=feature" agents/Fix.md` ≥ **1**。
5. 及时重构：`grep -c "refactor-executor" agents/Fix.md` ≥ **1**；`grep -c "mode=tdd\|mode = tdd" agents/Fix.md` ≥ **1**。
6. 5 步骨架不变：`grep -c "Step [1-5]/5" agents/Fix.md` ≥ **5**。

**验证命令**
- RED: `grep -c "童子军" agents/Fix.md` → 0；`grep -c "Legacy" agents/Fix.md` → >0
- GREEN: 6 条成立；`./scripts/lint-skills.sh` → OK

**不做什么**：不改复现 / 根因 / 假设 / 3+ 假设失败规则；不改红线 1–3；不加档位；不把童子军扩到 ≥2 函数或 >10 行；不改 code-reviewer。

**决策记录**：旧语义「4B 无测试 → 转交 Refactor 安全网」作废，改为 Fix 自己补安全网并继续 5 步（修正见 S24，风险 R1 同步更新）。

**批次**：B1

---

#### S8 [enabler] code-reviewer 口径 + README 同步

**Files**：`agents/code-reviewer.md`、`README.md`

**AC**
1. code-reviewer 无计划核对：`grep -c "重构计划" agents/code-reviewer.md` = **0**；`grep -c "计划步" agents/code-reviewer.md` = **0**。
2. 改为整分支 diff + 台账：`grep -c "整分支" agents/code-reviewer.md` ≥ **1**；`grep -c "REFACTOR_LEDGER" agents/code-reviewer.md` ≥ **1**；`grep -c "profile=refactor" agents/code-reviewer.md` ≥ **1**。
3. profile 枚举措辞保留：`grep -c "feature|legacy|refactor" agents/code-reviewer.md` = **2**。
4. 分级口径零 diff：`git diff <BASE>..<HEAD> -- agents/code-reviewer.md | grep -cE "^[-+].*(Critical|Important)"` = **0**。
5. README 零 Legacy / 零 planner：`grep -c "Legacy" README.md` = **0**；`grep -c "Legacy.md" README.md` = **0**；`grep -c "refactor-planner" README.md` = **0**。
6. README 四 Agent：`grep -c "4 个 Primary Agent" README.md` = **1**；`grep -c "统一循环\|循环子 agent" README.md` ≥ **1**；`grep -c "安全网" README.md` ≥ **1**。
7. README 保留两个 legacy subagent：`grep -c "legacy-analyst\|legacy-executor" README.md` ≥ **2**；文件树无 Legacy.md / refactor-planner.md：`grep -c "refactor-planner.md\|Legacy.md" README.md` = **0**。

**验证命令**
- RED: `grep -c "重构计划" agents/code-reviewer.md` → >0；`grep -c "Legacy" README.md` → >0
- GREEN: 7 条成立；`./scripts/lint-skills.sh` → OK

**不做什么**：不改 Critical / Important 分级阈值；不改 Phase 1–5 审查步骤；不改 feature / legacy 两个 profile 的加载集合；不改 README 安装步骤与「新旧对照」表；不写团队实践。

**批次**：B1（检查点）

---

### B1 修正批（S24，单故事；排在 B1 原批之后、B2 之前）

> 起因：B1 原批（commit 8a3424f）把「改动点无测试」写成「停下转交 Refactor 安全网」，与正确语义相反。S24 只修语义，不动其他骨架。

#### S24 [enabler] 无测试安全网归属修正（Feature/Fix/story-executor 自补；Refactor 先评估）

**Files**：`AGENTS.md`、`agents/Feature.md`、`agents/Fix.md`、`agents/story-executor.md`、`agents/Refactor.md`

**AC**
1. 转交语义清零：`grep -c "BLOCKED(需 Refactor" agents/story-executor.md` = **0**；`grep -c "BLOCKED(需 legacy" agents/story-executor.md` = **0**。
2. 自补安全网三处：`grep -c "自己补安全网" agents/Feature.md` ≥ **1**；`grep -c "自己补安全网" agents/Fix.md` ≥ **1**；`grep -c "自己补安全网" agents/story-executor.md` ≥ **1**。
3. legacy-code 条件加载三处：`grep -c "legacy-code" agents/Feature.md` ≥ **1**；`grep -c "legacy-code" agents/Fix.md` ≥ **1**；`grep -c "legacy-code" agents/story-executor.md` ≥ **1**；且加载条件是「条件/仅遗留/既有且无覆盖」而非常驻：`grep -cE "条件|仅.*遗留|既有.*无覆盖" agents/Feature.md` ≥ **1**；`grep -cE "条件|仅.*遗留|既有.*无覆盖" agents/story-executor.md` ≥ **1**。
4. Refactor 先评估覆盖：`grep -cE "先评估|评估.*覆盖" agents/Refactor.md` ≥ **1**；`grep -cE "已覆盖.*直接|有覆盖.*直接" agents/Refactor.md` ≥ **1**。
5. 场景表无「无测试→Refactor」：`grep -cE "^\| *2 \|.*无测试.*Refactor" AGENTS.md` = **0**。
6. 触发条件限定为「既有遗留代码」，新增代码直接 TDD：`grep -cE "既有|遗留代码" agents/Feature.md` ≥ **1**；`grep -cE "既有|遗留代码" agents/Fix.md` ≥ **1**；`grep -cE "既有|遗留代码" agents/story-executor.md` ≥ **1**；`grep -cE "新增代码|白纸|新代码" agents/Feature.md` ≥ **1**；`grep -cE "新增代码|白纸|新代码" agents/story-executor.md` ≥ **1**。
7. 三分类优先级（能直接补测试就不上重技术；难测才用 legacy-code）：`grep -cE "能直接.*测试|直接补测试|容易.*测试" agents/Feature.md` ≥ **1**；`grep -cE "能直接.*测试|直接补测试|容易.*测试" agents/story-executor.md` ≥ **1**；`grep -cE "难测|无法构造|依赖硬编码|全局.*状态" agents/Feature.md` ≥ **1**；`grep -cE "难测|无法构造|依赖硬编码|全局.*状态" agents/story-executor.md` ≥ **1**；`grep -c "难测" agents/story-executor.md` ≥ **1**。
8. 全局：`./scripts/lint-skills.sh` → `lint-skills: OK`。

**验证命令**
- RED: `grep -c "BLOCKED(需 Refactor" agents/story-executor.md` → >0（8a3424f 现状）；`grep -c "自己补安全网" agents/story-executor.md` → 0
- GREEN: 8 条成立；`./scripts/lint-skills.sh` → `lint-skills: OK`

**不做什么**：不改 code-reviewer 分级；不改 Refactor 的「范围收敛 / dispatch refactor-executor / 审查 / 收尾」骨架；不改 B2–B4 文件；不把 legacy-code 写成常驻加载；不给「无测试」一个统一的处理分支（三分类必须分开）。

**批次**：B1（修正）

---

### B2 设计主线（机械批，与 B3/B4 可并行，6 故事 / 6 文件）

文件集：`skills/design/SKILL.md`、`skills/design/references/refactoring-as-design.md`(新)、`analysis-uml.md`、`gof.md`、`grasp.md`、`contracts.md`

---

#### S9 [enabler] design/SKILL：设计三档 + 何时不设计 + 索引新 reference

**AC**
1. `grep -c "设计三档" skills/design/SKILL.md` = **1**；`最小设计` / `留白` / `交给重构` 各 ≥1 次。
2. `grep -c "何时不设计" skills/design/SKILL.md` ≥ **1**。
3. 模式闸门：`grep -c "第二次变化" skills/design/SKILL.md` ≥ **1**；`grep -c "变化\*\*已经发生\*\*" skills/design/SKILL.md` = **0**。
4. 索引新 reference：`grep -c "references/refactoring-as-design.md" skills/design/SKILL.md` = **1**。
5. 何时读 / 不读：`grep -c "何时读" skills/design/SKILL.md` = **1**；`grep -c "何时不读" skills/design/SKILL.md` = **1**。
6. 行数：`wc -l < skills/design/SKILL.md` ≤ **100** 或 `grep -c "目录" skills/design/SKILL.md` ≥ **1**。
7. `./scripts/lint-skills.sh` → OK。

**验证命令**
- RED: `grep -c "设计三档" skills/design/SKILL.md` → 0
- GREEN: 7 条成立

**不做什么**：不新增 skill；不改职责三问与契约判据；不删索引已有行；不把 reference 内容复制进来。

**批次**：B2

---

#### S10 [enabler] 新增 design/references/refactoring-as-design.md（≤80 行）

**AC**
1. `test -f skills/design/references/refactoring-as-design.md` → 0。
2. `wc -l < skills/design/references/refactoring-as-design.md` ≤ **80**。
3. 反向链接：`grep -c "SKILL.md" skills/design/references/refactoring-as-design.md` ≥ **1**。
4. 内容落点：`稳定中间形式` / `留白清单` / `反例` / `预先设计` / `第二次变化` 各 ≥1 次。
5. 被索引命中：`grep -c "references/refactoring-as-design.md" skills/design/SKILL.md` = **1**。
6. `./scripts/lint-skills.sh` → `lint-skills: OK`，无 `NO-BACK` / `ORPHAN`。

**验证命令**
- RED: lint → `MISSING design references/refactoring-as-design.md`
- GREEN: 6 条成立

**不做什么**：不写实现代码示例；不复述 gof/grasp 目录；不超过 80 行；不新增二级索引。

**批次**：B2

---

#### S11 [enabler] analysis-uml：连续迭代 + 七步 + UML 何时不必画

**AC**
1. `grep -c "混在一起" skills/design/references/analysis-uml.md` = **0**。
2. `grep -c "连续迭代" skills/design/references/analysis-uml.md` ≥ **1**。
3. `grep -c "七步" skills/design/references/analysis-uml.md` ≥ **1**；`grep -cE "^ *[0-9]+\. " skills/design/references/analysis-uml.md` ≥ **5**。
4. `grep -c "何时不必画" skills/design/references/analysis-uml.md` ≥ **1**。
5. `grep -c "SKILL.md" skills/design/references/analysis-uml.md` ≥ **1**。
6. `./scripts/lint-skills.sh` → OK。

**验证命令**
- RED: `grep -c "混在一起" skills/design/references/analysis-uml.md` → >0
- GREEN: 6 条成立

**不做什么**：不重写用例/领域模型/顺序图已有段落；不新增 reference；不改索引行名称。

**批次**：B2

---

#### S12 [enabler] gof：症状→候选模式反查 + LoD + 共同重用全称

**AC**
1. 反查表锁定格式（第二列加粗模式名）：`grep -cE "^\| [^|]+ \| \*\*[A-Z][A-Za-z ]+\*\*" skills/design/references/gof.md` ≥ **8**。
2. 原 23 模式行不丢：`grep -c "^\| \*\*[A-Z]" skills/design/references/gof.md` ≥ **23**。
3. 反查入口：`grep -c "反查\|症状 → 模式\|症状→模式" skills/design/references/gof.md` ≥ **1**。
4. LoD：`grep -cE "LoD|迪米特|最少知识" skills/design/references/gof.md` ≥ **1**。
5. 共同重用全称：`grep -c "共同重用原则" skills/design/references/gof.md` ≥ **1**；`grep -c "包原则.*CRP\|CRP.*包原则" skills/design/references/gof.md` = **0**。
6. 反向链接：`grep -c "SKILL.md" skills/design/references/gof.md` ≥ **1**。
7. `./scripts/lint-skills.sh` → OK。

**验证命令**
- RED: `grep -cE "^\| [^|]+ \| \*\*[A-Z][A-Za-z ]+\*\*" skills/design/references/gof.md` → 0
- GREEN: 7 条成立

**不做什么**：不改模式结构描述；不与 solid-packages 合并；不改 `solid-packages.md`；不删原 23 模式表。

**批次**：B2

---

#### S13 [enabler] grasp：Booch 附录补链接/对象语义（≤100 行）

**AC**
1. 真实缺口：`grep -c "链接" skills/design/references/grasp.md` ≥ **1**；`grep -c "Booch" skills/design/references/grasp.md` ≥ **1**。
2. 落点：`grep -n "链接" skills/design/references/grasp.md` 的行号 > `grep -n "## 附：为什么" skills/design/references/grasp.md` 的行号。
3. 行数：`wc -l < skills/design/references/grasp.md` ≤ **100**（当前 97）。
4. 增量：`git diff <BASE>..<HEAD> -- skills/design/references/grasp.md | grep -c "^+"` ≤ **5**。
5. 反向链接：`grep -c "SKILL.md" skills/design/references/grasp.md` ≥ **1**。
6. `./scripts/lint-skills.sh` → OK（无 `NO-TOC`）。

**验证命令**
- RED: `grep -c "链接" skills/design/references/grasp.md` → 0
- GREEN: 6 条成立

**不做什么**：不重写 9 个 GRASP 模式；不扩成章节；不超 100 行；不重复已有「聚合」定义。

**批次**：B2

---

#### S14 [enabler] contracts：重构触及公开签名后的契约复检

**AC**
1. `grep -c "复检" skills/design/references/contracts.md` ≥ **1**。
2. `前置` / `后置` / `不变式` 在 `skills/design/references/contracts.md` 各 ≥1 次。
3. `grep -c "公开签名\|公开接口" skills/design/references/contracts.md` ≥ **1**。
4. `grep -c "SKILL.md" skills/design/references/contracts.md` ≥ **1**。
5. `./scripts/lint-skills.sh` → OK。

**验证命令**
- RED: `grep -c "复检" skills/design/references/contracts.md` → 0
- GREEN: 5 条成立

**不做什么**：不改继承合法性判据；不写语言示例；不新增 skill。

**批次**：B2

---

### B3 坏味道总表与重构主线（机械批，与 B2/B4 可并行，7 故事 / 11 文件）

文件集：`skills/refactoring/SKILL.md`、`skills/refactoring/references/smells-catalog.md`(新)、`smells-classic.md`(删)、`smells-agent.md`(删)、`techniques.md`、`workflow.md`、`skills/refactoring-to-patterns/SKILL.md`、`skills/refactoring-to-patterns/references/evolution.md`、`skills/legacy-code/SKILL.md`、`skills/legacy-code/references/seams.md`、`skills/legacy-code/references/dependency-breaking.md`

**执行顺序（批内串行，故事编号不代表执行顺序）**：`S16 → S15 → S19 → S17 → S18 → S20 → S21`

**顺序理由（`scripts/lint-skills.sh` 实测语义）**：
- 规则 1：`SKILL.md` 引用的 `references/*.md` 不存在 → `MISSING`。
- 规则 2：`references/` 下文件未被**本 skill 的 `SKILL.md`** 引用 → `ORPHAN`（跨文件引用如 `evolution.md:146` 不计入）。
- 因此「先建 catalog」「先改索引」「先删旧文件」三者无法各自单独 lint 全绿：S16 时 catalog 未入索引（ORPHAN），S15/S19 时 classic/agent 已出索引但文件仍在（ORPHAN）。
- 故 **S16 / S15 / S19 的 lint AC 只校验「无 `MISSING`」**；**完整 `lint-skills: OK` 在 S17（catalog 已索引 + classic/agent 已删 + evolution 指针已改）钉死**，S18/S20/S21 及 B3 批末各再校验一次。

---

#### S15 [enabler] refactoring/SKILL + workflow：索引改指 catalog

**Files**：`skills/refactoring/SKILL.md`、`skills/refactoring/references/workflow.md`

**AC**
1. planner 清零：`grep -c "refactor-planner" skills/refactoring/SKILL.md` = **0**。
2. 索引指向 catalog：`grep -c "smells-catalog.md" skills/refactoring/SKILL.md` ≥ **2**；旧索引清零：`grep -c "smells-classic.md\|smells-agent.md" skills/refactoring/SKILL.md` = **0**。
3. 定位与童子军：`grep -c "重构是设计工具\|重构即设计" skills/refactoring/SKILL.md` ≥ **1**；`grep -c "童子军" skills/refactoring/SKILL.md` ≥ **1**；四限各 ≥1 次（`同一函数` / `有测试` / `独立 commit` / `10 行`）。
4. 何时读 / 不读：`grep -c "何时读" skills/refactoring/SKILL.md` = **1**；`grep -c "何时不读" skills/refactoring/SKILL.md` = **1**。
5. 边界节唯一：`grep -c "^## 与其他 skill 的边界" skills/refactoring/SKILL.md` = **1**。
6. 阈值仍唯一：`grep -c "> 40 行" skills/refactoring/SKILL.md` = **1**；`grep -c "smells-classic\|smells-agent\|refactor-planner" skills/refactoring/references/workflow.md` = **0**；`grep -c "smells-catalog" skills/refactoring/references/workflow.md` ≥ **1**。
7. lint（本时点只校验无 `MISSING`；S17 删除旧文件前必然有 `ORPHAN`）：`./scripts/lint-skills.sh | grep -c "MISSING"` = **0**；`./scripts/lint-skills.sh | grep -c "ORPHAN.*smells-classic\|ORPHAN.*smells-agent"` = **2**（预期，S17 后归零）。

**验证命令**
- RED: `grep -c "refactor-planner" skills/refactoring/SKILL.md` → 1；`grep -c "smells-catalog.md" skills/refactoring/SKILL.md` → 0
- GREEN: 7 条成立（第 7 条的 `ORPHAN` = 2 为时点预期值，非失败）

**不做什么**：不改阈值数值；不改台账 11 项；不改 4 条执行流程；不把 catalog 内容复制进来。

**批次**：B3

---

#### S16 [enabler] 新建 smells-catalog.md（唯一坏味道事实源）

**AC**
1. `test -f skills/refactoring/references/smells-catalog.md` → 0。
2. 行数 150–200 且带目录：`test $(wc -l < skills/refactoring/references/smells-catalog.md) -ge 150 -a $(wc -l < skills/refactoring/references/smells-catalog.md) -le 200` → 0；`grep -c "目录" skills/refactoring/references/smells-catalog.md` ≥ **1**。
3. 表头字段：`grep -c "怎么认" skills/refactoring/references/smells-catalog.md` ≥ **1**；`grep -c "首选手法" skills/refactoring/references/smells-catalog.md` ≥ **1**；`grep -c "不该用" skills/refactoring/references/smells-catalog.md` ≥ **1**。
4. 8 个分区：`grep -cE "^## [0-9]" skills/refactoring/references/smells-catalog.md` ≥ **8**。
5. 来源覆盖：`Fowler` / `A1` / `可测性` / `模式误用` 各 ≥1 次。
6. 唯一事实源：`grep -c "过度泛化\|Speculative Generality" skills/refactoring/references/smells-catalog.md` ≥ **1**；`grep -c "techniques.md" skills/refactoring/references/smells-catalog.md` ≥ **1**；`grep -c "dependency-breaking.md" skills/refactoring/references/smells-catalog.md` ≥ **1**；`grep -c "gof.md" skills/refactoring/references/smells-catalog.md` ≥ **1**。
7. 反向链接：`grep -c "SKILL.md" skills/refactoring/references/smells-catalog.md` ≥ **1**（索引命中由 S15 负责，本故事不校验）。
8. 行格式（每行 6 列：ID / 名称 / 怎么认 / 来源 / 首选手法 / 不该用它的情况）：表头 `grep -c "不该用它的情况" skills/refactoring/references/smells-catalog.md` = **1**；ID 行总数 `grep -cE "^\| *([0-9]+|A[1-7]) *\|" skills/refactoring/references/smells-catalog.md` ≥ **31**；6 列行数 `grep -cE "^\| *([0-9]+|A[1-7]) *\|([^|]+\|){5}" skills/refactoring/references/smells-catalog.md` ≥ **31**；无 5 列漏行：`test $(grep -cE "^\| *([0-9]+|A[1-7]) *\|" skills/refactoring/references/smells-catalog.md) -eq $(grep -cE "^\| *([0-9]+|A[1-7]) *\|([^|]+\|){5}" skills/refactoring/references/smells-catalog.md)` → 退出码 0。
9. lint（本时点 catalog 尚未入索引，预期 1 条 `ORPHAN`，只校验无 `MISSING`）：`./scripts/lint-skills.sh | grep -c "MISSING"` = **0**；`./scripts/lint-skills.sh | grep -c "ORPHAN.*smells-catalog"` = **1**（预期，S15 索引后归零）。

**验证命令**
- RED: `test -f skills/refactoring/references/smells-catalog.md` → 非 0
- GREEN: 9 条成立（第 9 条的 `ORPHAN` = 1 为时点预期值，非失败）

**不做什么**：不写手法步骤（只写名称）；不重复阈值数字（引用 SKILL 阈值表）；不复制 evolution 的完整演化链；不新增 skill；不给形容词式特征（必须可判定）；不改 `skills/refactoring/SKILL.md` 的索引行（由 S15 负责，两者在批内串行）。

**批次**：B3

---

#### S17 [enabler] 删除 smells-classic.md / smells-agent.md

**AC**
1. `test ! -f skills/refactoring/references/smells-classic.md` → 0；`test ! -f skills/refactoring/references/smells-agent.md` → 0。
2. 全 `skills/` 无悬空引用（执行位置在 S19 之后，`evolution.md:146` 指针已改）：`grep -rn "smells-classic\|smells-agent" skills/ | wc -l` = **0**。
3. 合并内容未丢：`grep -c "A1" skills/refactoring/references/smells-catalog.md` ≥ **1**；`grep -c "检测优先级\|复用优先" skills/refactoring/references/smells-catalog.md` ≥ **1**。
4. 完整 lint 首次全绿（本批第一个全绿检查点）：`./scripts/lint-skills.sh | grep -c "MISSING\|ORPHAN\|NO-BACK\|NO-TOC"` = **0**；`./scripts/lint-skills.sh` → `lint-skills: OK`。

**验证命令**
- RED: `test -f skills/refactoring/references/smells-classic.md && test -f skills/refactoring/references/smells-agent.md` → 退出码 0（两文件仍存在；此时 `grep -rn ... skills/` 已因 S15/S19 为 0，不作为 RED 依据）
- GREEN: 4 条成立；`./scripts/lint-skills.sh` → `lint-skills: OK`

**不做什么**：不删除 catalog；不把内容散落到其它 reference；不改 thresholds；不保留空索引行。

**批次**：B3

---

#### S18 [enabler] techniques：3 手法步骤 + Optional/Assertion 边界

**AC**
1. 三手法带操作步骤（同一行含 `→`）：`grep -cE "^\| \*\*(Extract Interface|Extract Superclass|Replace Type Code with State)\*\*.*→" skills/refactoring/references/techniques.md` = **3**。
2. Extract Interface 至少 2 次（原表已有 1 次）：`grep -c "Extract Interface" skills/refactoring/references/techniques.md` ≥ **2**。
3. Optional / Assertion：`grep -c "Use Optional" skills/refactoring/references/techniques.md` ≥ **1**；`grep -c "Introduce Assertion" skills/refactoring/references/techniques.md` ≥ **1**；`grep -c "边界\|何时用" skills/refactoring/references/techniques.md` ≥ **1**。
4. 坏味道名称归一：`grep -c "过度泛化\|Speculative Generality" skills/refactoring/references/techniques.md` = **0**。
5. 反向链接与 catalog 指针：`grep -c "SKILL.md" skills/refactoring/references/techniques.md` ≥ **1**；`grep -c "smells-catalog.md" skills/refactoring/references/techniques.md` ≥ **1**。
6. `./scripts/lint-skills.sh` → OK。

**验证命令**
- RED: `grep -cE "^\| \*\*(Extract Interface|Extract Superclass|Replace Type Code with State)\*\*.*→" skills/refactoring/references/techniques.md` → 0
- GREEN: 6 条成立

**不做什么**：不给 24 类坏味道全部补步骤；不删整张手法速查表（只移除与 catalog 重复的坏味道名称行）；不新增 reference；不重排表格。

**批次**：B3

---

#### S19 [enabler] refactoring-to-patterns：停止判据 + 接口数红线 + 去重

**Files**：`skills/refactoring-to-patterns/SKILL.md`、`skills/refactoring-to-patterns/references/evolution.md`

**AC**
1. planner 清零：`grep -c "refactor-planner" skills/refactoring-to-patterns/SKILL.md` = **0**。
2. 停止判据 3 条：`grep -c "停止判据" skills/refactoring-to-patterns/SKILL.md` ≥ **1**；`grep -cE "^ *[123]\. " skills/refactoring-to-patterns/SKILL.md` ≥ **3**。
3. 接口数红线：`grep -c "接口数" skills/refactoring-to-patterns/SKILL.md` ≥ **1**；`grep -c "红线" skills/refactoring-to-patterns/SKILL.md` ≥ **1**；`grep -c "AWAY" skills/refactoring-to-patterns/SKILL.md` ≥ **2**。
4. 去重：`grep -c "smells-catalog.md" skills/refactoring-to-patterns/SKILL.md` ≥ **1**；`grep -c "27 个" skills/refactoring-to-patterns/SKILL.md` = **0**；`grep -cE "^\| *坏味道" skills/refactoring-to-patterns/SKILL.md` = **0**。
5. evolution 去重与指针：`grep -cE "^\| *坏味道" skills/refactoring-to-patterns/references/evolution.md` = **0**；`grep -c "smells-classic" skills/refactoring-to-patterns/references/evolution.md` = **0**；`grep -c "smells-catalog" skills/refactoring-to-patterns/references/evolution.md` ≥ **1**。
6. 何时读 / 不读：`grep -c "何时读" skills/refactoring-to-patterns/SKILL.md` = **1**；`grep -c "何时不读" skills/refactoring-to-patterns/SKILL.md` = **1**。
7. 反向链接与索引：`grep -c "SKILL.md" skills/refactoring-to-patterns/references/evolution.md` ≥ **1**；`grep -c "references/evolution.md" skills/refactoring-to-patterns/SKILL.md` = **1**。
8. lint（S17 未执行，classic/agent 仍在但已出索引）：`./scripts/lint-skills.sh | grep -c "MISSING"` = **0**；`./scripts/lint-skills.sh | grep -c "ORPHAN.*smells-classic\|ORPHAN.*smells-agent"` = **2**（预期，S17 后归零）。

**验证命令**
- RED: `grep -c "停止判据" skills/refactoring-to-patterns/SKILL.md` → 0；`grep -cE "^\| *坏味道" skills/refactoring-to-patterns/references/evolution.md` → 1
- GREEN: 8 条成立（第 8 条的 `ORPHAN` = 2 为时点预期值，非失败）

**不做什么**：不改 YAGNI 三问阈值；不删 TO / TOWARDS / AWAY 三方向；不把 catalog 的模式误用清单复制回来；不删 evolution 的演化链正文（只删重复的坏味道→模式表并把指针改为 catalog）。

**批次**：B3

---

#### S20 [enabler] legacy-code/SKILL：四大策略入口 + 可测性引用 catalog

**AC**
1. 四策略入口：`grep -c "四大策略\|策略入口" skills/legacy-code/SKILL.md` ≥ **1**；`Sprout` / `Wrap` / `Direct Edit` / `解依赖` 各 ≥1 次。
2. 选择判据：`grep -c "判据\|先选\|顺序" skills/legacy-code/SKILL.md` ≥ **1**。
3. 可测性坏味道指向 catalog：`grep -c "smells-catalog.md" skills/legacy-code/SKILL.md` ≥ **1**。
4. 何时读 / 不读：`grep -c "何时读" skills/legacy-code/SKILL.md` = **1**；`grep -c "何时不读" skills/legacy-code/SKILL.md` = **1**。
5. 节奏不动：`grep -c "L0–L4 节奏" skills/legacy-code/SKILL.md` = **1**；`grep -c "节奏参数" skills/legacy-code/SKILL.md` = **1**。
6. 边界节唯一：`grep -c "^## 与其他 skill 的边界" skills/legacy-code/SKILL.md` = **1**。
7. `./scripts/lint-skills.sh` → OK。

**验证命令**
- RED: `grep -c "四大策略" skills/legacy-code/SKILL.md` → 0
- GREEN: 7 条成立

**不做什么**：不改三条红线；不改 L0–L4 步骤；不新增 reference；不把策略入口写成第二个节奏表。

**批次**：B3

---

#### S21 [enabler] seams 判据 + dependency-breaking 前 8 步

**Files**：`skills/legacy-code/references/seams.md`、`skills/legacy-code/references/dependency-breaking.md`

**AC**
1. seams 判据：`grep -c "真实依赖" skills/legacy-code/references/seams.md` ≥ **1**；`grep -c "替身" skills/legacy-code/references/seams.md` ≥ **1**；`grep -c "接缝" skills/legacy-code/references/seams.md` ≥ **3**。
2. dependency 1–8 每行有 `→`：`grep -cE "^\| [1-8] \|.*→" skills/legacy-code/references/dependency-breaking.md` = **8**。
3. dependency 9–24 不扩写：`grep -cE "^\| (9|1[0-9]|2[0-4]) \|.*→" skills/legacy-code/references/dependency-breaking.md` = **0**。
4. 24 行不丢：`grep -cE "^\| *[0-9]+ *\|" skills/legacy-code/references/dependency-breaking.md` ≥ **24**。
5. 反向链接：`grep -c "SKILL.md" skills/legacy-code/references/seams.md` ≥ **1**；`grep -c "SKILL.md" skills/legacy-code/references/dependency-breaking.md` ≥ **1**。
6. 行数：`wc -l < skills/legacy-code/references/dependency-breaking.md` ≤ **100** 或 `grep -c "目录" skills/legacy-code/references/dependency-breaking.md` ≥ **1**。
7. `./scripts/lint-skills.sh` → OK。
8. B3 批末检查点（全批去重收口）：`./scripts/lint-skills.sh | grep -c "MISSING\|ORPHAN\|NO-BACK\|NO-TOC"` = **0**；`grep -rn "smells-classic\|smells-agent" skills/ | wc -l` = **0**；`grep -rn "过度泛化\|Speculative Generality" skills/*/references/*.md | grep -v smells-catalog | wc -l` = **0**；`grep -rn "^| *坏味道" skills/refactoring-to-patterns/ | wc -l` = **0**。

**验证命令**
- RED: `grep -c "真实依赖" skills/legacy-code/references/seams.md` → 0；`grep -cE "^\| [1-8] \|.*→" skills/legacy-code/references/dependency-breaking.md` → 0
- GREEN: 8 条成立；`./scripts/lint-skills.sh` → `lint-skills: OK`

**不做什么**：不给 9–24 补步骤；不改现有 `## 分组` 标题（不引入 `###`）；不重排编号；不新增技术。

**批次**：B3

---

### B4 测试与 functional（机械批，收尾检查点，2 故事 / 2 文件）

文件集：`skills/testing-techniques/SKILL.md`、`skills/functional/SKILL.md`

> 批次说明：按 plan 固定为 2 文件的小批，作收尾检查点；不并入 B3 以保留「测试主线」验收边界。

---

#### S22 [enabler] testing-techniques：测试即设计工具 + 何时读/不读

**AC**
1. `grep -c "测试即设计工具\|测试即设计" skills/testing-techniques/SKILL.md` ≥ **1**。
2. `grep -c "设计接口" skills/testing-techniques/SKILL.md` ≥ **1**。
3. 何时读 / 不读：`grep -c "何时读" skills/testing-techniques/SKILL.md` = **1**；`grep -c "何时不读" skills/testing-techniques/SKILL.md` = **1**。
4. 既有判级不动：`grep -c "测试代码质量四属性" skills/testing-techniques/SKILL.md` = **1**；`grep -c "假测试闸门" skills/testing-techniques/SKILL.md` = **1**。
5. `./scripts/lint-skills.sh` → OK。

**验证命令**
- RED: `grep -c "测试即设计" skills/testing-techniques/SKILL.md` → 0
- GREEN: 5 条成立

**不做什么**：不改假测试判级；不改 FIRST 与坏味道判级表；不把「测试即设计」写成「先设计后写测试」。

**批次**：B4

---

#### S23 [enabler] functional：何时读 / 何时不读

**AC**
1. `grep -c "何时读" skills/functional/SKILL.md` = **1**；`grep -c "何时不读" skills/functional/SKILL.md` = **1**。
2. 位置在边界表之后：`grep -n "何时读" skills/functional/SKILL.md` 的行号 > `grep -n "与其他 skill 的边界" skills/functional/SKILL.md` 的行号。
3. 边界表不删：`grep -c "^## 与其他 skill 的边界" skills/functional/SKILL.md` = **1**。
4. `./scripts/lint-skills.sh` → OK。

**验证命令**
- RED: `grep -c "何时读" skills/functional/SKILL.md` → 0
- GREEN: 4 条成立

**不做什么**：不改范式选型表、五构建块、16 项评审清单、FP 微规则；不使用同义变体替代字面量（G4 依赖精确计数）。

**批次**：B4

---

## 七、批次汇总

| 批次 | 类型 | 故事 | 文件触达 | 唯一文件 | 依赖 |
|------|------|------|----------|----------|------|
| B1 | docs-only + 2 删除 + 1 重写（契约批，串行） | S1–S8（8）+ S24（1，修正） | 21 | 15 | 无；全 Epic 契约源 |
| B2 | 结构调整（新增 1 reference，机械批） | S9–S14（6） | 6 | 6 | 依赖 B1 的 D1/D3 口径 |
| B3 | 结构调整（新建 1 + 删除 2，机械批） | S15–S21（7） | 11 | 11 | 依赖 B1 的 D5/D8/D9 口径 |
| B4 | docs-only（机械批，检查点） | S22–S23（2） | 2 | 2 | 无文件相交；B1 后并行 |

- **B1 修正批 S24 必须在 B1 原批（8a3424f）之后、B2 之前执行**（它改的是 B1 已落地的错误语义，B2–B4 依赖修正后的口径）。

- **B3 批内按 `S16 → S15 → S19 → S17 → S18 → S20 → S21` 顺序串行执行，故事编号不代表执行顺序**（理由见 B3 头部：lint 的 `MISSING` / `ORPHAN` 语义决定建文件、改索引、删旧文件必须交错）。
- 合计：**24 故事 / 40 次文件触达 / 34 个唯一文件**。
- B2 / B3 / B4 文件集两两不相交，B1 完成后可并行 dispatch（各自单 commit）。
- 全量检查点：B3 在 S17（首个 lint 全绿）与 S21（批末）各校验一次；B4 完成后跑一次 `./scripts/lint-skills.sh`。

## 八、Epic 验收（只读命令）

1. `./scripts/lint-skills.sh` → `lint-skills: OK`
2. `grep -rn "refactor-planner" agents/ skills/ AGENTS.md README.md | wc -l` → **0**
3. `test ! -f agents/Legacy.md && test ! -f agents/refactor-planner.md && test ! -f skills/refactoring/references/smells-classic.md && test ! -f skills/refactoring/references/smells-agent.md` → 退出码 0
4. `grep -rn "切 Legacy\|切 \*\*Legacy\*\*\|Legacy 场景\|Legacy 主 agent" agents/ | wc -l` → **0**
5. `grep -l "何时读" skills/{design,functional,refactoring,refactoring-to-patterns,legacy-code,testing-techniques}/SKILL.md | wc -l` → **6**；`grep -l "何时不读" skills/{design,functional,refactoring,refactoring-to-patterns,legacy-code,testing-techniques}/SKILL.md | wc -l` → **6**
6. 坏味道去重：`grep -rn "过度泛化\|Speculative Generality" skills/*/references/*.md | grep -v smells-catalog | wc -l` → **0**
7. 模式表去重：`grep -rn "^| *坏味道" skills/refactoring-to-patterns/ | wc -l` → **0**
8. 阈值唯一：`grep -rn "> 40 行" skills/ | wc -l` → **1**
9. `grep -c "refactoring-as-design.md" skills/design/SKILL.md` → **1**
10. `grep -c "references/smells-catalog.md" skills/refactoring/SKILL.md` ≥ **2**
11. `ls -d skills/*/ | wc -l` → 与改动前相同（不新增 skill）
12. `grep -c "档位" agents/Refactor.md` → **0**；`grep -c "momus" agents/Refactor.md` → **0**
13. 无测试不转交：`grep -rn "BLOCKED(需 Refactor" agents/ | wc -l` → **0**
14. 自补安全网与三分类：`grep -l "自己补安全网" agents/{Feature,Fix,story-executor}.md | wc -l` → **3**；`grep -lE "能直接.*测试|直接补测试|容易.*测试" agents/{Feature,story-executor}.md | wc -l` → **2**；`grep -lE "难测|无法构造|依赖硬编码|全局.*状态" agents/{Feature,story-executor}.md | wc -l` → **2**
15. Refactor 先评估覆盖：`grep -cE "先评估|评估.*覆盖" agents/Refactor.md` ≥ **1**；`grep -cE "已覆盖.*直接|有覆盖.*直接" agents/Refactor.md` ≥ **1**

## 九、风险与待裁决

| # | 风险 | 处置 |
|---|------|------|
| R1 | B1 原批（8a3424f）已落地「无测试 → 停下转交 Refactor」的错误语义 | 由 S24 纠正：Feature/Fix/story-executor 自己补安全网并继续 TDD；Refactor 仅在整段存量重构时进入且先评估覆盖。S24 必须排在 B2 之前 |
| R2 | `code-reviewer` 被 S8 改动，与「不改分级口径」易被误读 | G6 限定只改 profile=refactor 的核对对象；S8 AC4 用 `git diff` 证明 Critical/Important 行零变动；profile 枚举不重命名（`refactor-safety` 改名不在本轮要求内） |
| R3 | S3 / S7 / S24 共享 `agents/Fix.md`，S24 又复触达 S1/S3/S5 的文件 | 同批单 commit、AC 分区：S3 只 Legacy 清零，S7 只童子军/4B/profile，S24 只安全网归属与三分类；S24 的断言不复用 S1/S3/S5 的断言 |
| R4 | `grasp.md` 当前 97 行，+4 行触发 NO-TOC | S13 硬限 `wc -l ≤100` 且增量 ≤5 行；超限必须补「目录」行 |
| R5 | `dependency-breaking.md` 无 `###` 分节 | S21 用表格行锚点（行 1–8 含 `→`，9–24 不含），不要求 `###` |
| R6 | catalog 合并两文件可能丢内容 | S16/S17 同时校验分区数 ≥8、来源关键词（Fowler/A1/可测性/模式误用）、A1 与复用优先仍在 |
| R7 | `techniques.md` 顶部「坏味道→技术」速查表与 catalog 仍有名称重复 | 本轮只删触发验收的「过度泛化」行；若要彻底去重，单开后续 Patch（不扩大本 Epic） |
| R8 | `evolution.md` 删表时误删 TO/TOWARDS/AWAY 正文 | S19 只要求 `^| 坏味道` =0 与指针改 catalog；三方向正文的保留在「不做什么」中明确 |
| R9 | `Refactor.md` / `story-executor.md` 复述七步导致双实现 | G9 + S2 AC3 / S5 AC6 用 `记账`、`轮次上限`、`扫描 → 选择` 做负向钉 |
| R10 | legacy-code 被写成常驻加载，导致白纸代码也走重技术 | S24 AC3/AC6/AC7 钉死条件加载 + 三分类（新增代码 / 能直接补测试 / 难测），Epic 验收 #14 复核 |
