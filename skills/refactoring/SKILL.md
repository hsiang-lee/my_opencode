---
name: refactoring
description: Automatically detect and eliminate code smells during the REFACTOR phase of the TDD cycle. Provides bad-smell classification, technique cheat sheet, and test-gated execution flow. One smell at a time, no behavior change.
---

# Refactoring — 代码重构

在 TDD 的 REFACTOR 阶段自动检测并消除代码坏味道。每次只处理一种坏味道，每个步骤由测试验证。

**核心原则：测试失败时禁止重构。重构只改变结构，不改变行为。**

违反这条规则的文字就是违反规则的精神。

---

## 坏味道分类 (Bad-Smell Classification)

以下表格列出常见的代码坏味道及其检测条件。由执行者（plan-executor）人工判断检测，不使用自动化静态分析工具。

| # | 坏味道 | 描述 | 检测条件 |
|---|--------|------|----------|
| 1 | **重复代码 (Duplicated Code)** | 相同或相似的代码出现在多个位置 | 同一结构出现在 ≥2 个方法/类/文件中 |
| 2 | **过长方法 (Long Method)** | 一个方法承担了过多职责 | 方法长度 > 20 行，或包含多个明显可提取的段落 |
| 3 | **过大类 (Large Class)** | 一个类承担了过多职责 | 类有 > 10 个方法，或包含多个不相关的功能组 |
| 4 | **过长参数列表 (Long Parameter List)** | 方法参数过多 | 参数个数 > 4 |
| 5 | **依恋情结 (Feature Envy)** | 方法更多使用另一个类的特性而非自身 | 方法中超过 50% 的调用是对另一个类/对象的操作 |
| 6 | **基本类型偏执 (Primitive Obsession)** | 使用基本类型表示领域概念，没有封装 | 存在重复出现的字符串/数值参数，应封装为值对象 |
| 7 | **switch 语句 (Switch Statements)** | 根据类型代码做分支判断 | switch/case 或 if/else-if 链可根据对象类型替换 |
| 8 | **冗赘类 (Lazy Class)** | 类承担的职责太少 | 类只有 1-2 个简单方法，可以内联到使用处 |
| 9 | **过度泛化 (Speculative Generality)** | 为不存在的未来需求设计的抽象 | 抽象类只有一个实现，或参数有从不使用的标志位 |
| 10 | **消息链 (Message Chains)** | 长链的方法调用 | 形如 `a.getB().getC().doSomething()` 的调用链长度 > 2 |
| 11 | **中间人 (Middle Man)** | 类的大部分方法只是委托给其他类 | 类中 > 60% 的方法只是委托调用 |
| 12 | **过度亲密 (Inappropriate Intimacy)** | 类之间过多访问彼此的私有成员 | 类 A 在方法中多次调用类 B 的 getter/setter |
| 13 | **异曲同工的类 (Alternative Classes)** | 类似功能的类有不同的接口 | 两个类做相似的事情但方法名/签名不一致 |
| 14 | **注释 (Comments)** | 代码不易读，用注释解释行为 | 注释在解释"做了什么"而不是"为什么这么做" |

---

## 坏味道 → 重构技术对照表 (Smell-to-Technique Cheat Sheet)

| 坏味道 | 推荐重构技术 |
|--------|-------------|
| 重复代码 | Extract Method / Pull Up Method / Form Template Method |
| 过长方法 | Extract Method / Replace Temp with Query / Introduce Parameter Object |
| 过大类 | Extract Class / Extract Subclass / Extract Interface |
| 过长参数列表 | Introduce Parameter Object / Preserve Whole Object |
| 依恋情结 | Move Method / Extract Method |
| 基本类型偏执 | Replace Primitive with Object / Replace Type Code with Subclasses |
| switch 语句 | Replace Type Code with Strategy/State / Replace Conditional with Polymorphism |
| 冗赘类 | Inline Class / Collapse Hierarchy |
| 过度泛化 | Collapse Hierarchy / Inline Class / Remove Parameter |
| 消息链 | Hide Delegate / Extract Method |
| 中间人 | Remove Middle Man / Inline Method |
| 过度亲密 | Move Method / Change Bidirectional Association to Unidirectional |
| 异曲同工的类 | Rename Method / Move Method |
| 注释 | Extract Method / Rename Method / Introduce Assertion |

---

## 重构技术速查 (Technique Quick Reference)

| 技术 | 描述 | 操作指引 |
|------|------|----------|
| **Extract Method** | 将一段代码提取为独立方法 | 选中代码段 → 创建新方法 → 传入需要的参数 → 替换原位置为方法调用 |
| **Move Method** | 将方法移动到更合适的类 | 确认方法应属于目标类 → 复制方法到目标类 → 在原类中委托调用 |
| **Rename Method** | 改进方法名使其意图清晰 | 改为"做什么"的描述（动词+名词），不是"怎么做" |
| **Extract Class** | 将类的一部分职责分离到新类 | 识别内聚的功能组 → 创建新类 → 移动相关字段和方法 |
| **Inline Class** | 将职责少的类合并到使用它的类 | 把类的字段和方法移入调用方 → 删除原类 |
| **Introduce Parameter Object** | 将多个参数封装为一个对象 | 创建参数对象类 → 替换方法签名 → 更新调用方 |
| **Preserve Whole Object** | 传递整个对象而不是从中提取值 | 修改方法签名接收对象 → 方法内直接使用对象字段 |
| **Replace Primitive with Object** | 将基本类型替换为值对象 | 创建值对象类 → 封装行为和验证 → 替换所有使用处 |
| **Replace Conditional with Polymorphism** | 用多态替换条件分支 | 提取各分支为子类方法 → 父类声明虚方法 → 调用处改用多态分发 |
| **Pull Up Method** | 将相同的方法提升到父类 | 确认子类中有相同方法 → 复制到父类 → 删除子类版本 |
| **Form Template Method** | 用模板方法模式统一算法骨架 | 提取算法步骤为方法 → 父类定义模板方法 → 子类实现步骤差异 |
| **Hide Delegate** | 隐藏委托关系 | 在委托类中添加方法 → 调用方改为直接调用委托类的方法 |
| **Remove Middle Man** | 移除中间委托层 | 调用方直接调用实际执行者 → 删除中间方法 |
| **Introduce Assertion** | 将隐式假设转为显式断言 | 识别前置条件 → 添加 `assert` 或条件检查 |

---

## 执行流程 (Execution Flow)

在 TDD 绿色阶段通过后（所有测试通过），plan-executor 使用本流程执行重构：

```
1. 确认所有测试通过 (GREEN confirmed)
   │
2. 所有测试通过？──否──► 停止。修复代码。不进入重构。
   │是
3. 扫描代码：检测一种坏味道（从坏味道分类表中逐一比对）
   │
   4. 发现坏味道？──否──► 报告 "REFACTOR_SKIPPED: 未检测到坏味道"。返回外层。
   5. 选择对应的重构技术（从对照表中选择）
   │
   6. 应用重构：仅做结构性变更，不改变行为
   │
   7. 运行所有测试
   │
   8. 测试通过？──否──► 回滚本次重构改动。报告 "REFACTOR_FAILED: [坏味道] → [技术] 导致测试失败"。停止重构，返回外层。
   │是
   9. 还有更多坏味道？──是──► 回到步骤 3（一次只处理一种）
   │否
   10. 报告 "REFACTOR_DONE: 已消除 N 种坏味道"。返回外层。
```

### 执行规则

- **一次一种坏味道。** 每次只应用一种重构技术，验证通过后才处理下一个。
- **不变更行为。** 重构只改变结构：不添加新功能、不修改公共 API、不添加新的公开接口。
- **测试通过后才继续。** 任何一步测试失败 -> 回滚该步 -> 报告 -> 停止。

### 输出状态

执行完成后向 plan-executor 报告以下状态之一：

| 状态 | 含义 | 下一步 |
|------|------|--------|
| `REFACTOR_SKIPPED` | 未检测到坏味道 | 返回外层 |
| `REFACTOR_DONE` | 成功消除 N 种坏味道 | 返回外层，附变更内容 |
| `REFACTOR_FAILED` | 某步重构导致测试失败（已回滚） | 返回外层，附失败详情 |

---

## 错误处理

| 场景 | 处理方式 |
|------|----------|
| GREEN 后测试失败 | 不进入重构。先修复生产代码。 |
| 重构步骤导致测试失败 | 回滚该单步重构改动。报告 "REFACTOR_FAILED: [坏味道] → [技术] broke test"。停止重构，返回外层。 |
| 检测到多种坏味道 | 一次处理一种。每一步独立验证。 |
| 未检测到坏味道 | 报告 "REFACTOR_SKIPPED: 未检测到代码坏味道"。返回外层。 |

---

## 红线 (Hard Constraints)

- **测试失败时禁止重构。** 只有测试全部通过后才能开始重构。
- **一次一种坏味道。** 应用一种重构技术，验证，重复。
- **不变更行为。** 重构只改变结构——不添加功能、不修改 API、不新增公开接口。
- **回滚红色。** 重构步骤导致测试失败，立即回滚该步。

---

## 假设 (Assumptions)

- 坏味道检测依赖执行者的人工判断（不引入自动化静态分析工具）。
- 本技能不替换或修改现有 TDD 技能——它补充 REFACTOR 阶段。
- Plan-executor 已通过 `Required` 指令加载本技能。
