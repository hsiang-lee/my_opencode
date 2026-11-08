---
name: refactoring
description: Use during the REFACTOR phase after tests are green, when detecting and eliminating code smells on code that already has tests, or when reviewing code for smell and Clean Code violations. SKILL.md holds the judging thresholds, the ledger's required items and the hard constraints; smell catalogs, refactoring techniques, workflow and Clean Code rules are in references/ and read on demand. Legacy code without a safety net belongs to the legacy-code skill; evolving smells into a pattern belongs to refactoring-to-patterns.
---

# Refactoring — 代码重构

**核心原则：测试失败时禁止重构。重构只改变结构，不改变行为。**

**使用者**：story-executor（检测 → 重构 → 记台账）、refactor-executor（按计划分批执行）、code-reviewer（Phase 2.5 质量审计）。**本文件常驻 = 判定层**（阈值、台账必填项、红线），索引里的文件只在需要时读。

---

## 索引 — 要做什么 → 读哪个文件

| 要做的事 | 文件 |
|----------|------|
| 判断某种经典坏味道存不存在（24 类检测条件） | `references/smells-classic.md` |
| 判断 A1-A7（AI 生成代码特有病灶）+ 代码放置第一问 + 检测优先级 + 复用优先 | `references/smells-agent.md` |
| 查某种坏味道该用哪个重构手法、手法怎么做 | `references/techniques.md` |
| 走完整执行流程（两顶帽子 / 步骤 / 失败处理） | `references/workflow.md` |
| 写台账（完整格式与示例） | `references/ledger.md` |
| Clean Code 10 条（评审用判据） | `references/clean-code.md` |

规则：**只读当前任务需要的那一个**。核对台账 ≠ 通读全部；先按下面阈值定位嫌疑项，再按嫌疑项查对应文件。

---

## 与其他 skill 的边界

| 问题 | 用哪个 |
|------|--------|
| 已有测试的代码怎么小步改结构 | 本 skill |
| 目标代码**没有测试**（遗留代码） | legacy-code skill |
| 坏味道已存在、要演化成设计模式 | refactoring-to-patterns skill |
| 测试怎么写、怎么判假测试 | testing-techniques skill |

---

## 判定阈值（常驻，唯一来源）

所有阈值以本表为准；references 与 agent 正文出现不同数值一律以本表覆盖。检测优先级：A1/A2 → A3 → A4 → 经典结构类；纯人工逐类核对，不使用静态分析工具。

| 项 | 触发阈值 |
|----|----------|
| 过长函数 | > 40 行（经典参考线 20 行仅作提示） |
| 嵌套层次过深 | ≥ 3 层 |
| 参数过多 | > 4 个 |
| 过大类 | > 10 个方法 |
| 重复代码 | 同一结构出现在 ≥ 2 处方法/类/文件 |
| A1 共享常量重复 | 同一常量/字面量在 ≥ 2 个文件重复定义 |
| A2 绕过现有封装 | 已有封装（apiClient / push_task_to_redis 等）外裸写等价调用 |
| A3 测试 setup 复制 | 相同 setup 样板在 ≥ 2 个测试文件逐字重复 |
| A4 命名漂移 | 同一概念 ≥ 2 种命名 |
| A5 贫血 / 职责错位 | 操作所需数据在类 X，操作却落在类外（判据是数据与操作的关系，不是有无成员方法） |
| A6 伪多态 | 分派同一概念行为的 cast/instanceof/类型 switch 散落多处（新增子类要改 N 处） |
| A7 out-param 束 | 签名含 ≥ 2 个非 const 引用 out-param（刻意 in-out 钳制不算） |
| 数据泥团 | ≥ 3 个字段/参数总是同时出现 |
| 消息链 | 调用链长度 > 2 |
| 中间人 | > 60% 的方法只是委托 |
| 依恋情结 | > 50% 的访问指向另一个对象 |
| 重复的 switch | 同一类型分支出现在 ≥ 2 处 |
| 霰弹式修改 | 一个变更要改 ≥ 2 个类的多处 |

---

## 台账必填项（常驻）

REFACTOR 是唯一输出 = `REFACTOR_LEDGER`。以下 11 项**每项**必须给出「命中 + 处置与证据」或「未命中 + 理由一句」，不许留空、不许省略：

```
A1 A2 A3 A4 A5 A6 A7 / 过长函数(>40行) / 深嵌套(≥3层) /
批级质量遍(本批整体 diff，含跨任务累积) / 其他经典类
```

格式模板见 `references/ledger.md`。谎报台账（声称未命中但 diff 中明显命中）= 假测试级违规。

---

## 执行流程（4 条，细节见 `references/workflow.md`）

1. **测试必须全绿**才能开始；红着不进入重构。
2. **一次一种坏味道**：逐类核对 → 命中即用一种手法重构 → 跑测试 → 绿了再下一项。
3. **不改行为**：不加功能、不改公共 API、不新增公开接口。期望值变了 = 在加功能，停下先写测试。
4. **回滚红色**：某步重构导致测试失败 → 回滚该步 → 台账标注「已回滚」→ 停止继续重构。

---

## 红线

- 测试失败时禁止重构
- 一次只处理一种坏味道
- 重构不改变行为
- 重构步骤导致测试失败 → 立即回滚该步
- 实现任何 helper/常量前先 grep 已有同类：找到就复用，找不到才创建（详见 `references/smells-agent.md` 复用优先规则）
