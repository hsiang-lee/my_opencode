# 经典坏味道 — 24 类检测条件

回到索引: [../SKILL.md](../SKILL.md)

> Fowler《重构》第 2 版全集。阈值数值以 SKILL.md「判定阈值」表为准；本表只定义**怎么认**。

## 一、命名与重复

| # | 坏味道 | 检测条件 | 手法 |
|---|--------|----------|------|
| 1 | 神秘命名 Mysterious Name | 名字不能表达用途/意图，需要注释解释 | Rename Method/Variable/Class/Field |
| 2 | 重复代码 Duplicated Code | 同一结构出现在 ≥2 处方法/类/文件 | Extract Method / Pull Up Method / Form Template Method / Substitute Algorithm |
| 3 | 数据泥团 Data Clumps | 3+ 个字段/参数总是同时出现 | Extract Class / Introduce Parameter Object |

## 二、函数级

| # | 坏味道 | 检测条件 | 手法 |
|---|--------|----------|------|
| 4 | 过长函数 Long Function | 超过 SKILL.md 阈值，或含多个可提取段落 | Extract Method / Replace Temp with Query / Decompose Conditional |
| 5 | 过长参数列表 Long Parameter List | 参数个数超过阈值 | Introduce Parameter Object / Preserve Whole Object / Remove Flag Argument |
| 6 | 标志参数 Flag Argument | 布尔参数切换两种行为 | Remove Flag Argument（拆成两个函数） |
| 7 | 临时字段 Temporary Field | 字段只在某些调用路径有值，其余为 null/空 | Extract Class / Introduce Null Object |
| 8 | 循环 Loops | 手写索引循环做 filter/map/reduce 能表达的事 | Replace Loop with Pipeline |

## 三、变化与职责

| # | 坏味道 | 检测条件 | 手法 |
|---|--------|----------|------|
| 9 | 发散式变化 Divergent Change | 一个类因**多种不同原因**被修改 | Extract Class / Move Function |
| 10 | 霰弹式修改 Shotgun Surgery | 一个变化要改**多个类**的多个地方 | Move Function / Inline Class |
| 11 | 依恋情结 Feature Envy | 方法访问别的对象的数据多于自身 | Move Function |
| 12 | 基本类型偏执 Primitive Obsession | 用基本类型表示领域概念，校验散落各处 | Replace Primitive with Object / Replace Type Code with Subclasses |
| 13 | 重复的 switch Repeated Switches | 同一个类型分支在 ≥2 处出现 | Replace Conditional with Polymorphism |
| 14 | 过大类 Large Class | 方法数超过阈值，或含多个不相关功能组 | Extract Class / Extract Subclass / Extract Interface |
| 15 | 纯数据类 Data Class | 只有字段与 getter/setter，行为在别处（= A5 的形态之一） | Move Function / Encapsulate Record |
| 16 | 拒绝遗赠 Refused Bequest | 子类不用父类大部分成员，或覆写成空 | Push Down Method/Field / Replace Inheritance with Delegation |

## 四、耦合与结构

| # | 坏味道 | 检测条件 | 手法 |
|---|--------|----------|------|
| 17 | 消息链 Message Chains | `a.getB().getC().do()` 链长 > 2 | Hide Delegate / Extract Method |
| 18 | 中间人 Middle Man | 类中 > 60% 的方法只是委托 | Remove Middle Man / Inline Method |
| 19 | 过度亲密 Insider Trading | 类之间大量访问彼此内部/私有数据 | Move Function / Extract Class / 改单向关联 |
| 20 | 异曲同工的类 Alternative Classes with Different Interfaces | 两个类做相似的事但接口不一致 | Rename Method / Move Function / Extract Superclass |
| 21 | 惰性元素 Lazy Element | 类/函数只做一件微不足道的事 | Inline Class / Inline Function / Collapse Hierarchy |
| 22 | 过度泛化 Speculative Generality | 抽象只有一个实现，或有从不使用的参数/钩子 | Collapse Hierarchy / Inline Class / Remove Parameter |
| 23 | 全局数据 Global Data | 可变全局/单例被多处读写 | Encapsulate Variable / 依赖注入 |
| 24 | 可变数据 Mutable Data | 同一数据被多处修改，改一处不知道影响谁 | Encapsulate Variable / 拆分读写 / 不可变化 |

## 五、注释

| # | 坏味道 | 检测条件 | 手法 |
|---|--------|----------|------|
| 25 | 注释 Comments | 注释解释「做了什么」而非「为什么」 | Extract Method / Rename / Introduce Assertion |

> 注：Fowler 第 2 版把「注释」列在坏味道清单末尾，但它的处置通常是前四类手法的结果而非独立手法 —— 先消坏味道，注释自然可删。

## 六、检测顺序建议

1. 重复与命名（1-3）：改了立刻见效，风险低
2. 函数级（4-8）：Extract Method 是最安全的起点
3. 变化与职责（9-16）：需要先确认变化是否已发生
4. 耦合与结构（17-24）：改动面大，放到有测试覆盖之后
