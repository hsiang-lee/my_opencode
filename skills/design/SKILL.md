---
name: design
description: Use when assigning responsibilities, judging dependency direction, writing interface contracts, or reviewing a design for SOLID/GRASP violations. SKILL.md holds the decision order, the YAGNI gate and the review checklist; GRASP details, SOLID plus package principles, Design by Contract semantics and the GoF 23-pattern catalog live in references/ and are read on demand.
---

# Design — 职责分配与结构决策

**核心原则：先分配职责，再选模式。顺序颠倒 = 为模式找问题。**

| 顺序 | 问题 | 工具 |
|------|------|------|
| 1 | 这个职责该落在哪个类？ | GRASP → `references/grasp.md` |
| 2 | 类与包的依赖方向对吗？ | SOLID + 包原则 → `references/solid-packages.md` |
| 3 | 这个接口承诺了什么？ | DbC → `references/contracts.md` |
| 4 | 需要引入模式吗？ | GoF → `references/gof.md`（先过下面闸门） |

**本文件常驻 = 判定层。** references 只在对应问题出现时读，不要通读。

---

## 索引 — 要做什么 → 读哪个文件

| 要做的事 | 文件 |
|----------|------|
| 判断职责该归谁、常见分配错误怎么修（附 Booch 复杂系统五属性） | `references/grasp.md` |
| 判断 SRP/OCP/LSP/ISP/DIP 违反、包依赖是否有环/是否稳定 | `references/solid-packages.md` |
| 写前置/后置/不变式、判断继承是否合法、CQS/UAP | `references/contracts.md` |
| 选模式、查模式结构、区分易混模式 | `references/gof.md` |
| 分析阶段建模：用例模型、领域模型（Entity/值对象/聚合）、顺序图 vs 通信图、分析到设计的过渡判据 | `references/analysis-uml.md` |
| 设计该做多少、什么时候交给重构、稳定中间形式与留白清单 | `references/refactoring-as-design.md` |

---

## 常驻判定

### 职责分配（三问，按序执行）

1. **信息专家提名**：谁拥有完成这件事所需的**数据**？→ 给它（Information Expert，行为跟数据走）
2. **SRP 复核**：这个类是否只有一个**变化原因**？→ 否，拆（SRP / CCP）
3. **DIP 定依赖方向**：依赖箭头是否指向**更抽象、更稳定**的一方？→ 否，倒置（DIP / SDP）

**一票否决信号**：Entity 只有 getter/setter（贫血）、Service 上千行、Controller 里有业务规则、类型分支散落 ≥3 处、业务代码直接调第三方 SDK。

### 契约（写不出即未想清楚）

公开方法必须有：前置（调用方保证什么）、后置（返回时什么为真）、不变式（有状态时）。任一写不出 → 接口没想清楚，回去重分职责。
**空话不算契约**：「参数要合法」「返回正确结果」「处理错误」。

**继承合法性**：前置只能弱化、后置只能加强、不变式只能保持或加强；精确规则见 `references/contracts.md`。

### 模式闸门（YAGNI 三问，唯一判据；三项 AND，全过才允许引入）

1. **同一坏味道是否已第三次重复**？（Rule of Three；实现数 ≤1 或没有任何调用方 → AWAY）
2. **不用模式会失控吗**？（同一概念/分支已散落 ≥3 处）
3. **最直白写法是否已够用**？（更短、更清晰；够用 → 不加抽象）

三项必须同时成立；任一为否 → 用最直白写法。**「以后可能会变」「已排期需求」都不算变化已发生。**

### 设计三档（先定档，再设计）

| 档 | 判据 | 产出 |
|----|------|------|
| 最小设计 | 改动平凡、无新概念、契约能直接写出 | 不写设计文档，直接 TDD（目标 + 契约口述即可） |
| 标准设计 | 有新职责或新接口 | 目标/非目标 + 契约 + 留白清单 |
| 交给重构 | 结构已变形、坏味道跨模块 | 只锁行为与契约，结构交给重构循环 |

### 何时不设计

平凡改动、实现数 ≤1、契约能直接写出 → 归入「最小设计」档直接 TDD，不另写文档。留白清单只记录「本可以引入抽象」的位置，不预选模式。

**何时读**：分析建模（跨模块/新领域）→ `references/analysis-uml.md`；判断本次做多少设计 / 是否需要留白 →「设计三档 / 留白」；职责放哪、契约怎么写、要不要模式 → 本 skill。
**何时不读**：纯机械改动与契约已明确的 bug 修复不读，直接进 TDD。

---

## 设计自检（评审用）

- [ ] 每个公开方法都能回答「职责属于谁」
- [ ] 没有按类型分派同一概念行为的 if/switch/cast
- [ ] 依赖指向抽象，包依赖无环
- [ ] 每个公开接口有前置/后置/不变式承诺
- [ ] 命令与查询分离（CQS）
- [ ] 加一种实现不需要改已有代码（OCP）
- [ ] 引入的模式过了 YAGNI 三问，且代码确实更简单
- [ ] 没有为「以后可能要」预留的抽象
- [ ] 未满足项已显式豁免并记录理由

---

## 与其他 skill 的边界

| 问题 | 用哪个 |
|------|--------|
| 职责放哪、契约怎么写、要不要模式 | 本 skill |
| 代码怎么写干净、坏味道怎么消除（已有测试） | refactoring |
| 测试怎么写、怎么判假测试 | testing-techniques |
| 怎么验证行为（RED-GREEN-REFACTOR） | story-executor |
| 没有测试的老代码怎么改 | legacy-code |
| 坏味道已存在、要演化成设计模式 | refactoring-to-patterns |
