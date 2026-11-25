---
name: testing-techniques
description: Use when writing unit tests, choosing test doubles or fixtures, or judging whether a test is real. Single file holds the fake-test gate, AAA/naming/boundary rules, test doubles and fixtures; smell and refactoring lists live in the scouts and the refactoring skill.
---

# Testing Techniques — 写测试、判测试

`story-executor` 写测试时定结构、选替身、选夹具；`code-reviewer` 判假测试（本表是唯一判级依据），坏味道按 `test-smell-scout` 清单。

**本文件即全部内容**，无 references，一次读完。纯文档 / 格式改动可不读；**任何逻辑变更都必须测**。测试坏味道 14 项见 `test-smell-scout` 清单，测试重构手法见 `refactoring/SKILL.md` 第三张表——本文件不重复，避免判据漂移。

---

## 测试与设计的分工

契约先定（design）：前置 / 后置 / 不变式 / 错误语义在写测试前锁定。测试是接口的第一个调用者，只定「怎么被调用」与边界，不预设内部结构；结构在 REFACTOR 里随坏味道长出来（同一坏味道第三次重复才抽象，Rule of Three）。

测试暴露的信号：arrange 要构造一堆无关状态 → 依赖过多，收窄参数或引入参数对象；断言要穿透内部结构 → 接口没暴露意图，返回结果值 / 查询与命令分离；测试名说不清「一个行为」→ 职责混杂，拆函数；不得不 mock 才能调用 → 依赖硬编码，抽接缝（legacy-code）。

---

## 测试代码质量四属性（取舍要显式说明）

| 属性 | 含义 | 破坏信号 |
|------|------|----------|
| 可信度 | 失败即代表产品有缺陷 | 随机 / 时间依赖导致偶发红 |
| 可维护性 | 重构产品代码时测试改动少 | 断言私有方法、内部结构 |
| 可读性 | 一眼看出意图与预期 | 魔法数字、超长 setup |
| 性能 | 单测 <100ms，集成 <2s | 每个测试连真实 DB |

四者互相制衡，冲突时写下放弃了哪个。FIRST 大部分已并入本表，未覆盖的只有 **Timely**：测试先于产品代码。

---

## 假测试判级（唯一判级表）

判级口径：**可能产生假绿**（缺陷存在但测试仍绿）= Critical；**只增加维护成本或只造成假红** = Important/Minor。

| 模式 | 示例 / 症状 | 判级 |
|------|-------------|------|
| Null / 已定义 / 永真检查 | `not.toBeNull()` / `toBeDefined()` / `EXPECT_TRUE(true)` | Critical |
| 无异常检查 | `EXPECT_NO_THROW(fn())` 作为唯一断言 | Critical |
| 空测试 / Mock 调用断言 | `TEST(X, works) {}`；`verify(mock).called()` 无其它断言 | Critical |
| 断言缺失 / 过弱 | 跑完不断言，或只断言非空 / 非零 | Critical |
| 仅快乐路径 | 无任何边界 / 错误输入 | Critical |
| 不可重复 | 同代码多次跑结果不同 | Important |
| 脆弱 | 产品代码小改 → 大量测试红 | Important |
| 断言内部状态 / 实现细节 | 私有字段、调用顺序 | Important |
| Mock 过度 | 一个测试 Mock 超过 2 个 | Important |
| 共享夹具污染 / 依赖链 / 条件逻辑 | 测试互相影响，或必须按顺序执行 | Important |
| 命名不表意 / 测试代码重复 / 类过大 / 慢测试 | — | Minor |

**每个测试必须含**：一个具体行为 + 有意义的断言（具体值）+ 真实输入 + 公共接口。

---

## 结构、命名、测什么

**AAA**：Arrange 准备 → Act 只调一次被测行为 → Assert 只断言结果。两次 Act → 拆两个测试；Arrange >10 行 → 提取工厂。

**命名**（全项目统一一种）：`method_scenario_expected`（`withdraw_insufficientBalance_throws`）/ `should<预期>_when<场景>` / `behavior_under_condition`（`rejects_empty_email`）。判据：陌生人不读测试体也能知道「什么被破坏了」。含 `test1` / `works` / `ok` / `and` → 不合格。

**必须测**：公共接口行为、边界、错误路径、状态迁移、契约（前置拒绝 / 后置成立）。
**不测**：第三方库行为、简单 getter/setter、私有方法与内部状态（走公共入口）、实现细节（调用顺序 / 内部结构）、为此在生产代码加 `#ifdef TEST`。

**边界矩阵**：先写 1 条 golden path；每个校验分支 1 个拒绝 + 1 个接受；数值 0 / 负 / 上界 / 上界+1；集合 空 / 单 / 多；字符串 空 / 空白 / 超长 / 特殊字符。

**参数化**：同一行为只有输入不同 → 表驱动，不复制 N 个测试体。表里出现 if/else → 不是参数化，是条件逻辑，拆开。

**断言**：默认 State Verification；只有「必须发出某个外部交互」才用 Behavior Verification。复杂断言封装成 Custom Assertion（失败消息仍要带上下文）；断言变化量用 Delta Assertion。

一个测试 = 一个行为契约。一个行为的多条断言、同一不变式的多处检查不算违反；两个输入场景挤在一起、正常与错误路径挤在一起、测试体里 if/for 决定断言 → 违反。

---

## 测试替身

选择顺序：**真实对象 → Fake → Stub → Spy → Mock**。能用真实对象就不用替身，每退一步给理由。

| 类型 | 作用 | 断言什么 | 例 |
|------|------|----------|-----|
| Dummy | 只为填参数，永不被调用 | 无 | nullptr 替代 |
| Stub | 预设返回值 | 无（只控制输入） | 硬编码返回 |
| Spy | Stub + 记录调用 | 调用次数 / 参数 | 手写记录器 |
| Mock | 预设期望，不符即失败 | 交互是否发生 | 框架生成 |
| Fake | 可工作的简化实现 | 状态（由调用方断言） | 内存 DB / 队列 |

红线：Mock 只验证对外交互；`verify(mock).called()` 无行为断言 = 假测试；Mock 期望来自需求，不从实现倒推；一个测试 Mock >2 个 → 先怀疑设计；不 mock 值对象 / 数据结构 / 标准库容器；Fake 与真实实现共用同一组契约测试。

---

## 夹具

默认 **Fresh Fixture**（每个测试新建）。Shared / Lazy / Suite 只在构造极贵且**只读**时使用；没有测量证据的「昂贵」不算昂贵。测试单独绿、全量红，或换个顺序就红 = 状态污染，代价远高于多构造几次对象。

工厂函数：默认值要构造出合法对象，测试只覆盖关心的字段；一工厂一概念，参数 >3 → Builder；放测试支持目录，不放生产代码；关键输入不要被工厂藏起来。

组织：`tests/support/factories`、`tests/support/fakes`、`tests/unit`（无 IO）、`tests/integration`（真实依赖）。快慢分离是为了让常跑的那层够快，不是删掉慢测试。
