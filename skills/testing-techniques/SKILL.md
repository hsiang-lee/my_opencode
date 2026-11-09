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

| 何时读 | 写测试、选替身/夹具、判测试好坏时读本 SKILL 与对应 reference |
| 何时不读 | 纯机械改动或已有测试覆盖的行为不变重构时不读（现有测试就是范式示范） |

---

## 测试即设计工具（写测试 = 设计接口）

测试是接口的第一个调用者：先写测试，就把「怎么用」定下来，产品代码再按它实现。**这是设计活动，不是设计之后的补充。**

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

## 假测试闸门（任一命中 = Critical）

| 模式 | 示例 | 为什么无价值 |
|------|------|--------------|
| Null 检查 | `not.toBeNull()` / `ASSERT_NE(nullptr, p)` | 任何非空都过 |
| 无异常检查 | `EXPECT_NO_THROW(fn())` 作为唯一断言 | 只证明不崩溃 |
| 已定义检查 | `toBeDefined()` / `toBeTruthy()` | 任何非空都过 |
| Mock 调用 | `verify(mock).called()` 且无其它断言 | 测替身而非逻辑 |
| 空测试 | `TEST(X, works) {}` | 什么都不过 |
| 永真断言 | `EXPECT_TRUE(true)` | 骗覆盖率 |
| 仅快乐路径 | 无任何边界/错误输入 | 一遇异常就崩 |
| 内部状态 | 断言私有字段 | 重构即碎 |

**每个测试必须含**：一个具体行为 + 有意义的断言（具体值）+ 真实输入 + 公共接口。

---

## 测试坏味道判级（明细见 `references/test-smells.md`）

| 命中 | 判级 |
|------|------|
| 脆弱 / 不可重复 / 断言缺失 / 断言过弱 / 断言内部状态 | Major |
| 共享夹具污染 / 测试依赖链 / 条件测试逻辑 | Major |
| Mock 过度 / 断言实现细节（调用顺序等） | Major |
| 命名不表意 / 测试代码重复 / 测试类过大 / 慢测试 | Minor |
| 仅快乐路径、零边界 | Major |

判级口径：**会导致误判通过或产生假绿** = Critical/Major；**只影响维护成本** = Minor。

---

## FIRST（写测试时自检）

Fast 毫秒级 / Independent 可乱序 / Repeatable 环境无关 / Self-checking 自动判 / Timely 先于产品代码。
