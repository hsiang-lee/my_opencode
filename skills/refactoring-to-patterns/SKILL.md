---
name: refactoring-to-patterns
description: Use after a code smell already exists and the next structural step is a known design pattern, or when deciding whether to complete a pattern, stop at part of it, or inline it away. SKILL.md holds the trigger, the YAGNI gate and the three directions; the smell-to-pattern catalog, evolution chains and the review table are in references/evolution.md and read on demand.
---

# Refactoring to Patterns — 从坏味道到模式

> **模式是目的地，重构是道路。** 不要在绿地上先画模式，让模式从坏味道里长出来。

| 谁用 | 用来做什么 |
|------|------------|
| refactor-planner | 判断本次是否涉及模式引入，给出目标形态与方向 |
| refactor-executor | 按 TO/TOWARDS/AWAY 方向逐步演化，每步保持测试绿 |
| code-reviewer | 审查模式是长出来的还是预置的，是否该 inline |

## 何时用

同时满足才进本 skill：

1. **坏味道已经存在**（重复类型分支 ≥2 处、状态切换散布、通知硬编码等），不是「以后可能要扩展」；
2. 常规手法（Extract / Move / 多态替换）已不足以消除该坏味道；
3. 下一步结构**指向某个已知模式**（Strategy / State / Observer / Command / Composite / Null Object …）。

只满足「想用模式」而不满足 1 → 停，回 refactoring 或直接写最直白代码。
目标代码**没有测试** → 停，先走 legacy-code 上安全网。

## YAGNI 三问（全过才允许引入）

| # | 问题 | 判否信号 |
|---|------|----------|
| 1 | 变化**已经发生**了吗？ | 只有 1 个实现且无排期需求；「以后可能会变」不算 |
| 2 | 不用模式会失控吗？ | 分支只散落 1–2 处，手改成本可接受 |
| 3 | 加这层抽象后代码更短或更清晰吗？ | 多出接口 + 工厂 + 注册表，读代码要跳三处 |

任一为否 → 用最直白写法，并记入台账「已评估，不引入」。

## 三种方向（最容易漏掉后两种）

| 方向 | 含义 | 何时用 |
|------|------|--------|
| **TO a Pattern** | 完整落地一个模式 | 坏味道明确、收益清晰、真实变体 ≥2 |
| **TOWARDS a Pattern** | 只走到模式的一部分，够用就停 | 不确定要不要全套结构，先留简单多态 |
| **AWAY from a Pattern** | 拆掉多余的模式、inline 掉 | 复杂度不抵收益，使用者 ≤1 且无排期 |

判据：**抽象的真实使用者 ≤1 且无排期中的第二个 → 反向重构（AWAY）。**

## 禁止事项

- **禁止为模式找问题**：先有坏味道再谈模式；先画类图再找证据 = 过度设计。
- **跳过小步演化**：一次落地全套接口/工厂/注册表，等价于大爆炸重写。
- **在结构重构里混入行为变更**：结构 commit 与语义 commit 分离。
- **模式掩盖坏味道**：把分支搬进 `execute()` 里继续 if，只是搬家，不算消除。
- **留下孤立的单实现抽象**：使用者 ≤1 且无排期 → inline（AWAY），不留空壳 Factory/Decorator。

## 索引 — 要做什么 → 读哪个文件

| 要做的事 | 文件 |
|----------|------|
| 坏味道→目标模式对照、27 个模式导向重构、演化链示例、误区与评审表 | `references/evolution.md` |

规则：**只读当前任务需要的那一节**。只判方向查「三种方向」，只查目标形态查「坏味道 → 目标模式」。

## 与其他 skill 的边界

| 问题 | 用哪个 |
|------|--------|
| 坏味道怎么识别、原子手法怎么用 | refactoring skill |
| 模式结构长什么样、易混模式怎么区分 | design skill（GoF 索引） |
| 从坏味道走到模式的路径与评审 | 本 skill |
| 目标代码没有测试 | legacy-code skill |