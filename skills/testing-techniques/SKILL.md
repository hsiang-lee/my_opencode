---
name: testing-techniques
description: Use when writing unit tests, choosing test doubles or fixtures, or reviewing tests for fake assertions and test smells. SKILL.md holds the quality attributes, the fake-test gate and the review thresholds; AAA, naming, boundary matrix, test doubles, fixtures, test smells and test refactorings live in references/ and are read on demand.
---

# Testing Techniques — 测试代码怎么写、怎么判

| 谁用 | 用来做什么 |
|------|------------|
| story-executor | 写测试时选结构、替身、夹具 |
| code-reviewer | 判假测试与测试坏味道（本文件的清单是唯一判级依据） |

**本文件常驻 = 判定层。** 写具体测试时才读 references，不要通读。

| 时机 | 说明 |
|------|------|
| 何时读 | 写测试、选替身/夹具、判测试好坏时读本 SKILL 与对应 reference |
| 何时不读 | 只读、零逻辑变更的改动可不新增测试（现有测试即范式示范）；**任何逻辑变更都必须测**，此时读本 skill |

---

## 测试与设计的分工（契约先定，测试定调用形态）

契约先定（design skill）：前置 / 后置 / 不变式与错误语义在写测试前锁定。测试是接口的第一个调用者，负责定「怎么被调用」与边界，**不预设内部结构**；结构在 REFACTOR 中随坏味道长出来（同一坏味道第三次重复才抽象，Rule of Three）。

| 测试暴露的信号 | 反馈到接口设计 |
|----------------|----------------|
| arrange 要构造一堆无关状态 | 依赖过多 → 收窄构造参数，或引入参数对象 |
| 断言要穿透内部结构 | 接口没暴露意图 → 返回结果值，查询与命令分离 |
| 测试名说不清「一个行为」 | 职责混杂 → 拆函数，一个函数只做一次变换 |
| 不得不 mock 才能调用 | 依赖硬编码 → 抽接缝（见 legacy-code） |

**边界**：先写测试 ≠ 先设计完整结构。测试只定「这个行为怎么被调用」；内部结构等坏味道出现再重构（refactoring）。

---

## 索引 — 要做什么 → 读哪个文件

| 要做的事 | 文件 |
|----------|------|
| 写测试体（AAA / 命名 / 该测什么 / 边界矩阵 / 参数化 / 断言手法） | `references/test-structure.md` |
| 选替身（Dummy/Stub/Spy/Mock/Fake）、判 Mock 是否滥用 | `references/test-doubles.md` |
| 选夹具策略（Fresh/Shared/Lazy/Suite）、消除状态污染 | `references/fixtures.md` |
| 判测试坏味道、重构测试代码、假测试的完整模式 | `references/test-smells.md` |

**不在本文件**：RED-GREEN-REFACTOR 循环（story-executor 正文）、接缝与解依赖（legacy-code skill）。

---

## 测试代码质量四属性（取舍要显式说明）

| 属性 | 含义 | 破坏信号 |
|------|------|----------|
| 可信度 | 失败即代表产品有缺陷 | 随机/时间依赖导致偶发红 |
| 可维护性 | 重构产品代码时测试改动少 | 断言私有方法、内部结构 |
| 可读性 | 一眼看出意图与预期 | 魔法数字、超长 setup |
| 性能 | 单测 <100ms，集成 <2s | 每个测试连真实 DB |

四者互相制衡：过分追求性能会牺牲可读性，过分追求可信度会牺牲可维护性。冲突时写下放弃了哪个。

---

## 测试判级（本 skill 唯一判级表）

判级口径：**可能产生假绿（缺陷存在但测试仍绿）** = Critical；**只增加维护成本或只造成假红** = Important/Minor。`references/test-smells.md` 只列症状与识别方法，不判级。

| 模式 | 示例 / 症状 | 判级 |
|------|-------------|------|
| Null / 已定义 / 永真检查 | `not.toBeNull()` / `toBeDefined()` / `EXPECT_TRUE(true)` | Critical |
| 无异常检查 | `EXPECT_NO_THROW(fn())` 作为唯一断言 | Critical |
| 空测试 / Mock 调用断言 | `TEST(X, works) {}`；`verify(mock).called()` 无其它断言 | Critical |
| 断言缺失 / 断言过弱 | 跑完不断言，或只断言非空 / 非零 | Critical |
| 仅快乐路径 | 无任何边界 / 错误输入 | Critical |
| 不可重复 | 同代码多次跑结果不同 | Important |
| 脆弱 | 产品代码小改 → 大量测试红 | Important |
| 断言内部状态 / 实现细节 | 断言私有字段、调用顺序 | Important |
| Mock 过度 | 一个测试 Mock 超过 2 个 | Important |
| 共享夹具污染 / 测试依赖链 / 条件测试逻辑 | 测试间互相影响，或必须按顺序执行 | Important |
| 命名不表意 / 测试代码重复 / 测试类过大 / 慢测试 | — | Minor |

**每个测试必须含**：一个具体行为 + 有意义的断言（具体值）+ 真实输入 + 公共接口。

**A3（测试 setup 复制）**：识别判据见本 skill `references/test-smells.md` §二「测试代码重复」；计数阈值以 `refactoring/SKILL.md` 判定阈值表为准。

---

## FIRST（只保留四属性未覆盖的部分）

Fast / Independent / Repeatable / Self-Validating（自动判定通过或失败）已并入上表四属性（性能 / 可信度）。FIRST 未被覆盖的只有 **Timely**：测试必须先于产品代码。
