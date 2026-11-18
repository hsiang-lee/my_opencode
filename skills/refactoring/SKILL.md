---
name: refactoring
description: Use when a smell has been found and you need to pick the refactoring for it. Maps Fowler, pattern-related and test smells to their refactorings, each with a one-line key point; does not include step-by-step procedures.
---

# Refactoring — 坏味道 → 手法

`smell-scout` / `pattern-scout` / `test-smell-scout` 负责判定；本文件只回答「命中之后用哪个手法」。

一次只用一种手法；改完测试保持绿，红即回滚。

---

## 一、Fowler 24 项

| # | 坏味道 | 重构手法（要点） |
|---|--------|------------------|
| 1 | 神秘命名 | Rename Function / Variable / Class、Rename Field（按使用点意图命名；作用域小且上下文唯一时短名可接受） |
| 2 | 重复代码 | Extract Method（相同代码段，抽一处）；Pull Up Method（子类重复，提到父类）；Form Template Method（步骤同序异实现）；Substitute Algorithm（算法可整体替换） |
| 3 | 过长函数 | Extract Method（每段可独立命名的逻辑块）；Replace Temp with Query（临时变量改查询）；Introduce Parameter Object（参数成组）；Preserve Whole Object（传整个对象）；Replace Loop with Pipeline（循环改管道） |
| 4 | 过长参数列表 | Introduce Parameter Object（常一起出现的参数封成对象）；Preserve Whole Object（已有对象就直接传）；Remove Flag Argument（布尔参数拆成两个语义函数） |
| 5 | 全局数据 | Encapsulate Variable（getter/setter 包住，限制写入口）；Introduce Parameter Object（逐步改显式传参） |
| 6 | 可变数据 | Separate Query from Modifier（查询不修改）；Remove Setting Method（去掉不必要的 setter）；Replace Derived Variable with Query（缓存改实时计算）；Combine Functions into Class / Transform（把读写收进一处） |
| 7 | 发散式变化 | Extract Class（按变化原因拆）；Move Function、Move Field（把职责搬到变化发生的类） |
| 8 | 霰弹式修改 | Move Function、Move Field（把分散改动集中到一处）；Inline Class（中间类过小就合并） |
| 9 | 依恋情结 | Move Function（整个方法搬到它依赖的类）；Extract Function（只搬依赖对方的那段） |
| 10 | 数据泥团 | Extract Class（字段组变值对象）；Introduce Parameter Object（参数组变对象）；Preserve Whole Object（直接传整个对象） |
| 11 | 基本类型偏执 | Replace Primitive with Object（金额/电话/区间变值对象）；Replace Type Code with Subclasses / State / Strategy（类型码影响行为时）；Extract Class（一组基本类型成组） |
| 12 | 重复的 switch | Replace Conditional with Polymorphism（每个分支一个实现，调用方按多态分派） |
| 13 | 循环语句 | Replace Loop with Pipeline（filter / map / reduce 表达意图；循环含 break 或多集合并行时保留） |
| 14 | 冗赘的元素 | Inline Function（只转发就内联）；Inline Class（无独立职责就合并）；Collapse Hierarchy（空层合并） |
| 15 | 夸夸其谈通用性 | Collapse Hierarchy、Inline Function、Inline Class（撤掉未使用的抽象）；Change Function Declaration（删掉从未使用的参数/钩子） |
| 16 | 临时字段 | Extract Class（只在某状态有意义的字段+行为单独成类）；Introduce Special Case / Null Object（缺失情况显式化） |
| 17 | 过长的消息链 | Hide Delegate（在中间对象加转发方法）；Extract Function（把整条链的意图收成一个函数）；Move Function（把行为搬到数据所在处） |
| 18 | 中间人 | Remove Middle Man（调用方直接找实际对象）；Inline Function、Inline Class（中间层没有附加价值就撤掉） |
| 19 | 内幕交易 | Move Function、Move Field（把交流改成单向）；Hide Delegate（藏起内部结构）；Remove Setting Method；Replace Subclass with Delegate（继承换委托） |
| 20 | 过大类 | Extract Class（按职责组拆）；Extract Subclass（只部分场景用的成员下移）；Extract Interface（客户端只需要一部分能力时） |
| 21 | 异曲同工的类 | Rename Function（先统一命名）；Move Function（统一归属）；Extract Superclass（抽出共同父类） |
| 22 | 纯数据类 | Encapsulate Record / Collection（字段私有化）；Remove Setting Method（去掉任意修改）；Move Function（把操作数据的行为搬进来）；Hide Delegate |
| 23 | 拒绝遗赠 | Push Down Method / Field（子类不用的下移到真正用它的子类）；Replace Inheritance with Delegation（继承关系不成立就改委托） |
| 24 | 注释 | Extract Method（把注释描述的「做什么」变成函数名）；Rename Function / Variable（命名代替解释）；Introduce Assertion（把假设变成断言）；只保留解释「为什么」的注释 |

---

## 二、模式相关 12 项

| # | 坏味道 | 重构手法（要点） | 落点模式 |
|---|--------|------------------|----------|
| 1 | 不当暴露 | Encapsulate Classes with Factory（构造降为非 public，只暴露接口与创建方法） | Factory |
| 2 | 解决方案蔓延 | Move Creation Knowledge to Factory（创建知识集中）；Introduce Polymorphic Creation with Factory Method（把 new 谁下放到子类） | Factory / Factory Method |
| 3 | 条件逻辑太复杂 | Compose Method 打底，再 Replace Conditional Logic with Strategy（每个变体一个实现） | Strategy；分支改状态 → State；修饰可叠加 → Decorator |
| 4 | 方法过长 | Compose Method（切成同一抽象层小方法）；Move Accumulation to Collecting Parameter（累加搬出） | 先不引入模式；确认变体增长后再走向 Strategy / Command |
| 5 | 类过大 | Replace Conditional Dispatcher with Command（调度拆出去）；Replace State-Altering Conditionals with State；Replace Implicit Language with Interpreter | Command / State / Interpreter |
| 6 | 分支语句 | Replace Conditional Dispatcher with Command（按动作建命令并注册表）；Replace State-Altering Conditionals with State；Move Accumulation to Visitor | Command / State / Visitor |
| 7 | 重复代码 | Form Template Method（步骤同序异实现）；Extract Composite（重复的部分-整体代码）；Encapsulate Composite with Builder（重复拼树） | Template Method / Composite / Builder |
| 8 | 替代类却接口不同 | Unify Interfaces with Adapter（先统一接口）；Extract Adapter（多版本再拆） | Adapter |
| 9 | 组合爆炸 | Replace Implicit Language with Interpreter（把嵌套条件变成表达式树） | Interpreter |
| 10 | 怪异解决方案 | Unify Interfaces with Adapter（先统一两套写法的接口，再消重） | Adapter |
| 11 | 基本类型迷恋 | Replace Type Code with Class（类型码变值对象）；Replace State-Altering Conditionals with State；Replace Conditional Logic with Strategy；Replace Implicit Tree with Composite；Replace Implicit Language with Interpreter | 值对象 / State / Strategy / Composite / Interpreter |
| 12 | 冗赘类 | Inline Singleton（把滥用或无状态的 Singleton 抹平）；Collapse Hierarchy（空子类合并） | 拆除 Singleton / 合并层次 |

**上模式前必须说明**：目标模式是什么、为什么是它、以及为什么更轻的写法不够（YAGNI 三问）。说不清就不上。

---

## 三、测试 13 项

| # | 坏味道 | 测试重构手法（要点） |
|---|--------|----------------------|
| 1 | 脆弱的测试 | 断言行为而非实现细节（去掉对私有方法、内部调用顺序、日志文本的断言）；Extract Method 隔离易变构造；必要时 Replace Test Double with Real Object |
| 2 | 不可重复 | 消除时间/随机/环境依赖（注入固定 Clock / Random / 配置）；Fresh Fixture 隔离共享状态；不依赖执行顺序 |
| 3 | 缓慢的测试 | Replace Real Object with Test Double（DB/网络/文件替换）；快慢测试分离；Lazy Setup 只在需要时建夹具 |
| 4 | 过于具体的测试 | 收窄断言到关键行为；用 Custom Assertion 表达意图，避免逐字段对比 |
| 5 | 测试侵蚀 | 删除永远通过/长期失效的测试；Extract Method / Extract Testcase Superclass 让测试可维护 |
| 6 | 断言缺失 | 补明确断言（状态或行为）；用 Custom Assertion 提高可读性；断言具体值，不用 assertNotNull 兜底 |
| 7 | 条件测试逻辑 | Parameterize Test（把 if/for 变成多组输入）；拆成多个独立测试，每个一个行为 |
| 8 | 测试代码重复 | Extract Method（setup / 断言样板）；Extract Testcase Superclass（跨测试类共享夹具）；Parameterize Test（只差输入） |
| 9 | 大型测试 | 按 act / assert 段落拆成多个测试；Extract Method 提公共准备 |
| 10 | 神秘客人 | Replace Real Object with Test Double；把外部资源改成测试内显式构造的 Fixture |
| 11 | 共享夹具污染 | Fresh Fixture（每个测试新建）；必要的共享夹具加 teardown 重置；避免 BeforeAll 里的可变状态 |
| 12 | 测试依赖链 | 独立 Fixture；把副作用搬进测试自己的 setup；删除顺序依赖与编号命名 |
| 13 | 测试类过大 | Move Test to Correct Class（放回对应被测类）；按主题拆类；Extract Testcase Superclass 共享夹具 |

---

## 边界

- 只给手法名与要点，不写步骤。
- 没有对应手法，或手法不适用 → 停止并说明，禁止即兴发挥。
- 手法执行后必须测试保持绿；红即回滚该步。
