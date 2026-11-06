# GoF 23 模式 — 选型、结构与代价

回到索引: [../SKILL.md](../SKILL.md)

> 模式是原则的具体落地，不是目的。先闻坏味道、先过 YAGNI 闸门，再看本表。

## 一、创建型（5）— 把「怎么创建」和「怎么使用」解耦

| 模式 | 意图 | 结构要点 | 何时用 | 代价 |
|------|------|----------|--------|------|
| **Singleton** | 保证唯一实例 + 全局访问点 | 私有构造 + 静态实例 + 静态获取 | 配置中心、连接池 | 变成全局变量，隐藏依赖，难测 |
| **Factory Method** | 定义创建接口，子类决定实例化谁 | Creator 抽象 + 工厂方法 + 具体产品 | 框架扩展点、按配置选实现 | 多一层继承 |
| **Abstract Factory** | 创建**一系列**相关对象 | 抽象工厂 + 多个 CreateX + 产品族 | 跨平台 UI、主题系统 | 新增产品种类困难 |
| **Builder** | 构建与表示分离，分步构建 | Builder 接口 + Director + Product | 参数多、可选配置多 | 类数量增加 |
| **Prototype** | 克隆原型创建新对象 | clone 接口 + 具体原型 | 初始化昂贵、大量相似对象 | 深/浅拷贝陷阱 |

## 二、结构型（7）— 用组合组织更大的结构

| 模式 | 意图 | 结构要点 | 何时用 | 代价 |
|------|------|----------|--------|------|
| **Adapter** | 转换接口以适配客户期望 | Target + Adapter + Adaptee | 老系统对接、第三方封装 | 多一层间接 |
| **Bridge** | 抽象与实现各自独立变化 | Abstraction 持有 Implementor | 两个维度都会变（形状 × 渲染） | 前期设计成本 |
| **Composite** | 整体与部分统一对待（树） | Component + Leaf + Composite | 文件系统、菜单树、表达式树 | 透明性 vs 安全性取舍 |
| **Decorator** | 动态叠加职责 | Component + 装饰器持有同类型 | 日志、缓存、压缩、权限 | 调试链变长、对象多 |
| **Facade** | 子系统统一高层入口 | Facade + 子系统 | SDK 封装、聚合层 | 可能变成上帝类 |
| **Flyweight** | 共享细粒度对象省内存 | 内部状态 + 外部状态 + 池 | 大量重复的小对象 | 状态必须可拆内外 |
| **Proxy** | 控制对对象的访问 | Subject + RealSubject + Proxy | 懒加载、远程、权限、AOP | 多一层、时序陷阱 |

## 三、行为型（11）— 职责分配与通信

| 模式 | 意图 | 结构要点 | 何时用 | 代价 |
|------|------|----------|--------|------|
| **Chain of Responsibility** | 请求沿链传递，直到被处理 | Handler 持有 next | 审批流、过滤器、中间件 | 链过长、可能无人处理 |
| **Command** | 把请求封装成对象 | Command + Invoker + Receiver | 撤销/重做、队列、宏 | 类数量膨胀 |
| **Interpreter** | 定义文法并解释 | 终结符/非终结符表达式 | DSL、规则引擎、表达式求值 | 复杂文法类爆炸 |
| **Iterator** | 统一遍历，不暴露内部结构 | Iterator + Aggregate | 自定义容器、树/图遍历 | 现代语言多已内置 |
| **Mediator** | 集中封装对象间交互 | Mediator + Colleague | 聊天室、控件联动 | 中介者自身变复杂 |
| **Memento** | 捕获并恢复内部状态 | Originator + Memento + Caretaker | 撤销、快照、存档 | 存储成本、封装泄漏风险 |
| **Observer** | 一对多依赖，状态变化通知 | Subject + Observer 列表 | 事件总线、发布订阅 | 通知顺序、级联更新、内存泄漏 |
| **State** | 状态改变时行为随之改变 | State 接口 + Context 持有当前状态 | 订单状态机、播放器、工作流 | 状态类增多、状态转移散落 |
| **Strategy** | 算法族可互相替换 | Strategy 接口 + Context | 支付、排序、折扣、路由 | 调用方需知道选哪个 |
| **Template Method** | 父类定骨架，子类填步骤 | 抽象类 + 抽象步骤 | 数据处理流水线、报表 | 子类受限于父类骨架 |
| **Visitor** | 不改变元素类而增加操作 | Visitor + Element.accept | AST 分析、报表导出 | 新增元素类型要改所有 Visitor |

## 四、易混淆对比（选错的最常见来源）

| 对比组 | 关键区别 |
|--------|----------|
| Factory Method vs Abstract Factory | 造**单个**产品 vs 造**产品族** |
| Decorator vs Proxy | 增强功能 vs 控制访问 |
| Decorator vs Composite | 链式叠加职责 vs 树形整体-部分 |
| Strategy vs State | 算法可替换（外部选） vs 状态驱动行为（内部迁） |
| Adapter vs Bridge | 兼容已有接口 vs 抽象实现预先分离 |
| Observer vs Mediator | 广播通知 vs 集中调度 |
| Command vs Strategy | 封装「动作 + 上下文 + 时机」 vs 封装「算法」 |
| Template Method vs Strategy | 继承固定流程 vs 组合注入行为 |

## 五、原则 → 模式映射（先问违反哪条原则，再看模式）

| 违反 | 候选模式 |
|------|----------|
| OCP + LSP（类型分支扩散） | Strategy、State、Factory Method、Template Method |
| DIP（高层依赖具体） | Observer、Bridge、Proxy、Abstract Factory |
| ISP（大接口） | Adapter、Facade、Interface Segregation |
| SRP（职责混杂） | Command、Chain of Responsibility、Facade |
| 创建逻辑散落 | Creation Methods、Factory、Builder |

## 六、组合使用（常见搭配）

- 工厂 + 原型：高效创建复杂对象
- 观察者 + 命令：事件驱动 + 可撤销
- 策略 + 工厂：运行时选算法
- 组合 + 访问者：树结构 + 可扩展操作
- 装饰器 + 策略：叠加横切能力 + 可替换核心算法

## 七、使用前提

1. 有**已经发生**的变化点（≥2 个真实实现或已排期需求）
2. 不用模式时分支/重复会失控（同一概念散落 ≥3 处）
3. 加这层抽象后代码**更短或更清晰**；否则退回直白写法
4. 小范围试点 + 测试验证行为不变
