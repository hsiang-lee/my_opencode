# 遗留代码 — 24 种解依赖技术

回到索引: [../SKILL.md](../SKILL.md)

## 1. 方法 / 函数级（8）

| # | 技术 | 用途 |
|---|------|------|
| 1 | Adapt Parameter | 参数改为更通用的抽象类型，便于传替身 |
| 2 | Break Out Method Object | 长方法提取成类，局部变量转字段，可单测 |
| 3 | Define Method | 测试子类新增方法覆盖基类私有调用 |
| 4 | Encapsulate Global References | 全局访问封装成方法，测试覆写 |
| 5 | Expose Static Method | 实例逻辑提为静态方法独立测试 |
| 6 | Extract and Override Call | 依赖调用提取为虚方法，子类覆写 |
| 7 | Extract and Override Factory Method | new 处提取为工厂方法，子类返回替身 |
| 8 | Extract Interface | 从类提取接口，客户端依赖接口 |

## 2. 类 / 模块级（8）

| # | 技术 | 用途 |
|---|------|------|
| 9 | Introduce Instance Delegator | 静态调用改为实例委托，便于替换 |
| 10 | Link Seam | 替换链接库改变行为（测试环境） |
| 11 | Parameterize Constructor | 依赖作构造参数传入，不在内部 new |
| 12 | Parameterize Method | 依赖作方法参数传入 |
| 13 | Primitivize Parameter | 复杂参数简化为基本类型，降低准备成本 |
| 14 | Pull Up Feature | 待测特性上提到父类/接口 |
| 15 | Push Down Dependency | 依赖下推到子类，父类只留抽象 |
| 16 | Replace Global Reference with Getter | 全局访问改为 getter，测试覆写 |

## 3. 测试设施级（8）

| # | 技术 | 用途 |
|---|------|------|
| 17 | Subclass and Override Method | 测试子类覆写虚方法隔离依赖 |
| 18 | Subclass to Test | 测试专用子类暴露 protected / 加辅助方法 |
| 19 | Template Method | 骨架固定，变化步骤留给子类 |
| 20 | Test-Specific Subclass | 测试文件内定义子类，覆写少量方法 |
| 21 | Use Dependency Injection | 构造 / setter / 参数注入依赖 |
| 22 | Wrap Class | 第三方类包一层，依赖隔离在包装器 |
| 23 | Wrap Method | 难测方法外包一层处理依赖 |
| 24 | Introduce Null Object | 用空实现替换真实依赖，消除 null 判断 |

## 4. 场景 → 技术对照

| 场景 | 首选技术 |
|------|----------|
| 方法内部 new 对象 | Extract and Override Factory Method / Parameterize Constructor |
| 静态方法调用 | Introduce Instance Delegator / Wrap Method |
| 全局变量 / 单例 | Encapsulate Global References / Replace Global Reference with Getter |
| 长方法（数百行） | Break Out Method Object / Extract Method |
| 硬编码 DB / 文件路径 | Adapt Parameter / Parameterize Method |
| 继承体系混乱 | Extract Interface / Subclass to Test |
| 只有具体类没有接口 | Extract Interface / Wrap Class |
| 私有方法需要测试 | Expose Static Method / Subclass to Test |
| 条件逻辑复杂 | 逐分支特征测试 + Extract Method |
| 第三方 SDK 散落 | Wrap Class（防腐层）+ 之后 Protect Variations |

## 5. 私有方法的判定

先问一句：**这个行为是否该属于公共契约？**

- 属于 → 移到公共接口（顺便修 A5 职责错位）
- 不属于 → 不直接测，测调用它的公共方法

用 `Subclass to Test` 暴露私有方法只是权宜，不是目标。

## 6. 与重构 / 设计的关系

| 阶段 | 用什么 | 产出 |
|------|--------|------|
| 第一步：安全网 | 本文件 | 特征测试 + 解依赖 |
| 第二步：小步重构 | `refactoring/references/workflow.md` + `refactoring/references/techniques.md` | 消除坏味道 |
| 第三步：结构改善 | design skill | 引入必要抽象（过 YAGNI 闸门） |

**解依赖本身也是重构**：行为不变，只改结构。所以它受同一套红线约束（一次一种、测试保持绿、失败回滚）。
