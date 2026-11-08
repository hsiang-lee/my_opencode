---
name: legacy-code
description: Use when the code to change has no reliable tests, when adding a safety net before editing old code, when choosing between Sprout/Wrap/Direct Edit, or when breaking dependencies so code becomes testable. SKILL.md holds the L0-L4 rhythm, the seven pace parameters and the three red lines; seams, change points, dependency-breaking techniques and sprouting variants are in references/ and read on demand.
---

# Legacy Code — 遗留代码改动

> **定义：没有测试的代码就是遗留代码** —— 无论它多新、多漂亮。
> **核心：没有安全网就不改。先解依赖，再重构，最后才改行为。**

| 谁用 | 用来做什么 |
|------|------------|
| legacy-analyst | L0 侦察 + L1 改法建议（只读） |
| legacy-executor | L1–L4 执行（上安全网 → 主循环 → 出清） |
| code-reviewer | 审查安全网是否成立、特征测试是否被当成规格 |

**本文件常驻 = 节奏层。** 下面索引的文件只在对应阶段读，不要一次全读。

---

## L0–L4 节奏（唯一权威）

```
L0 侦察（禁改代码）：change points + effect sketch + 现有测试盘点
L1 选改法（风险递增）：Sprout > Wrap > Direct Edit
   Sprout/Wrap 不碰老代码 → 直接走 TDD，跳过 L2
L2 上安全网（一次性）：只覆盖"将被改路径 + 直接调用者"，对象接缝优先
   一次一种解依赖，每次解完全量测试 → 全绿并记录基线（含 flaky 标注）
L3 主循环（两顶帽子不混）
   3a 只改结构 → 一次一坏味道，绿→改→绿，红即回滚
   3b 改行为   → 先红后绿，特征测试保留到新测试覆盖
L4 出清：删临时测试接缝、更新 debt ledger、结构与语义分 commit
```

---

## 节奏参数（7 条，与本文件同权威）

| # | 参数 | 约束 |
|---|------|------|
| 1 | 一次一 change point | 不并行认领两个修改点 |
| 2 | 一次一种解依赖 | 解完跑全量测试再解下一个 |
| 3 | 一次一种坏味道 | 3a 阶段逐类处理，不合并动手 |
| 4 | 结构与语义分离 | 结构 commit 与语义 commit 必须分开提交 |
| 5 | 一步一见绿 | 每个「编辑-编译-测试」周期必须见绿，红即回滚该步 |
| 6 | 覆盖门槛 | 只覆盖改动函数 + 直接调用者；其余记 debt ledger |
| 7 | 退出条件 | 行为已改 + 该路径有测试 + 无临时接缝 + ledger 已更新 |

**特征测试需新测试覆盖后才可删**（见参数 7 与红线 1）。

---

## 三条红线

1. **特征测试 ≠ 规格**：它只锁 bug 现状；发现疑似错误另开 bug，不改断言迁就。
2. **解依赖 ≠ 重构完成**：解依赖只是上安全网的结构动作，不替代随后的坏味道处理与行为修改。
3. **Sprout 不得绕过必须修改的腐败点**：新代码挂在腐败逻辑旁边而不修根因，只是把问题留原地。

---

## 索引 — 要做什么 → 读哪个文件

| 要做的事 | 文件 |
|----------|------|
| 找接缝、定义 change point / test point / effect sketch、写特征测试 | `references/seams.md` |
| 解依赖：24 种技术、场景→技术对照、私有方法判定 | `references/dependency-breaking.md` |
| Sprout / Wrap / Direct Edit 的判定与实现细节 | `references/sprouting.md` |

规则：**只读当前阶段需要的那一个**。L0/L1 查 `seams.md` 与 `sprouting.md`，L2 查 `dependency-breaking.md`。

---

## 与其他 skill 的边界

| 问题 | 用哪个 |
|------|--------|
| 目标代码没有测试、要先上安全网 | 本 skill |
| 已有测试的代码怎么小步改结构 | refactoring skill |
| 坏味道已存在、要演化成设计模式 | refactoring-to-patterns skill |
| 怎么验证行为（RED-GREEN-REFACTOR） | story-executor / legacy-executor 正文 |