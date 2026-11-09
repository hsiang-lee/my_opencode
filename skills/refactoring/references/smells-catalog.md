# 坏味道目录（唯一事实源）

回到索引: [../SKILL.md](../SKILL.md)

> 本文件是坏味道**名称 / 识别特征 / 来源 / 首选手法**的唯一事实源。
> 决策阈值一律以 SKILL.md 判定阈值表为准；「怎么认」中的计数仅作识别提示，不构成第二阈值源。
> 手法步骤 → `techniques.md`；解依赖技术 → `../legacy-code/references/dependency-breaking.md`；模式结构 → `../design/references/gof.md`。

## 目录

1. [① 命名与重复](#1-命名与重复)
2. [② 函数级](#2-函数级)
3. [③ 变化与职责](#3-变化与职责)
4. [④ 耦合与结构](#4-耦合与结构)
5. [⑤ AI 生成代码 A1–A7](#5-ai-生成代码-a1a7)
6. [⑥ 可测性坏味道（Feathers）](#6-可测性坏味道feathers)
7. [⑦ 模式误用（Kerievsky）](#7-模式误用kerievsky)
8. [⑧ 设计层判断](#8-设计层判断)
9. [附：检测顺序、来源与分工](#附检测顺序来源与分工)

## 列定义（所有分区共用）

| ID | 名称 | 怎么认 | 来源 | 首选手法 | 不该用它的情况 |
|----|------|--------|------|----------|----------------|

> 各分区只列数据行，表头见上；每行 6 列：ID / 名称 / 怎么认 / 来源 / 首选手法 / 误用条件。

## 1. 命名与重复

| 1 | 神秘命名 Mysterious Name | 名称不能自解释；改名需求见 A4 命名漂移 | Fowler | Rename Method / Rename Variable / Rename Class | 名称是框架或序列化协议规定的对外标识时，先做兼容层再改 |
| 2 | 重复代码 Duplicated Code | 同一结构出现在多处方法 / 类 / 文件（阈值见 SKILL 表） | Fowler | Extract Method / Pull Up Method / Form Template Method | 两段只是文本相似但变化方向不同，强合并会制造发散式变化 |
| 3 | 数据泥团 Data Clumps | 多个字段 / 参数总是同时出现（阈值见 SKILL 表） | Fowler | Extract Class / Introduce Parameter Object | 这组值已由既有领域对象承载时，不再造平行类型 |
| 25 | 注释 Comments | 注释解释「做了什么」而非「为什么」；或注释与代码不一致 | Fowler | Extract Method / Rename / Introduce Assertion | 注释记录的是约束、边界与历史原因时必须保留 |

判据：改名与去重风险最低，先做；注释类先判断它是否在补偿命名或结构缺陷。

## 2. 函数级

| 4 | 过长函数 Long Function | 超过 SKILL 阈值表的长函数线（见 refactoring/SKILL.md），或含 ≥2 个可独立命名的段落 | Fowler | Extract Method / Replace Temp with Query / Decompose Conditional | 平铺直叙的状态机或协议解析拆开后更难读时，不硬拆 |
| 5 | 过长参数列表 Long Parameter List | 参数个数超过 SKILL 阈值表（见 refactoring/SKILL.md） | Fowler | Introduce Parameter Object / Preserve Whole Object / Remove Flag Argument | 参数来自不同生命周期且不构成概念整体时，不强行打包 |
| 7 | 临时字段 Temporary Field | 字段只在部分调用路径有值，其余为 null / 空 | Fowler | Extract Class / Introduce Null Object | 字段确实描述对象的可选状态且所有路径都显式检查时保留 |
| 8 | 循环 Loops | 手写索引循环只做 filter / map / reduce 能表达的事 | Fowler | Replace Loop with Pipeline | 循环含提前 break、多集合同步或副作用较多时，管道反而更难读 |

判据：函数级手法最安全，Extract Method 通常是任何重构的第一步。

## 3. 变化与职责

| 9 | 发散式变化 Divergent Change | 同一个类因 ≥2 类不同原因被修改 | Fowler | Extract Class / Move Function | 修改原因尚未真实发生、只是设想的扩展点，先不拆 |
| 10 | 霰弹式修改 Shotgun Surgery | 一个变化要改多个类的多处（阈值见 SKILL 表） | Fowler | Move Function / Inline Class | 分散点是稳定协议或插件注册表时，集中反而增加耦合 |
| 11 | 依恋情结 Feature Envy | 方法对另一对象的访问占比超过 SKILL 阈值表 | Fowler | Move Function | 目标是策略对象或 visitor，跨对象访问是设计意图时保留 |
| 12 | 基本类型偏执 Primitive Obsession | 用基本类型表达领域概念，校验散落在 ≥2 处 | Fowler | Replace Primitive with Object / Replace Type Code with Subclasses | 值没有行为且只在本函数内使用时，不造值对象 |
| 13 | 重复的 switch Repeated Switches | 同一类型分支出现在多处（阈值见 SKILL 表） | Fowler | Replace Conditional with Polymorphism | 分支只有 2 个且不会再扩时，简单多态即可，不建完整模式 |
| 14 | 过大类 Large Class | 方法数超过 SKILL 阈值表，或含 ≥2 个不相关功能组 | Fowler | Extract Class / Extract Subclass | 类是由框架基类规定的集中入口时，只拆可独立的部分 |
| 15 | 纯数据类 Data Class | 只有字段与 getter / setter，行为全在类外（A5 的形态之一） | Fowler | Move Function / Encapsulate Record | 它是 DTO 或序列化契约时，保持数据形状，不塞业务行为 |
| 16 | 拒绝遗赠 Refused Bequest | 子类不用父类大半成员，或覆写为空实现 | Fowler | Push Down Method / Field / Replace Inheritance with Delegation | 父类是稳定框架契约且子类只需少数钩子时保留继承 |

判据：先确认「变化已经发生」再动手；未发生的第二变化只登记，不抽象。

## 4. 耦合与结构

| 17 | 消息链 Message Chains | `a.b().c().d()` 调用链长度超过 SKILL 阈值表 | Fowler | Hide Delegate / Extract Method | 链是公开 DSL 或流式 API 时，隐藏委托会破坏可读性 |
| 18 | 中间人 Middle Man | 转发委托的方法占比超过 SKILL 阈值表 | Fowler | Remove Middle Man / Inline Method | 中间层承担权限、缓存或协议转换时保留 |
| 19 | 过度亲密 Insider Trading | 两个类互相访问对方内部 / 私有数据 ≥2 处 | Fowler | Move Function / Extract Class / 改单向关联 | 两者是同一模块内的值对象与容器时，访问是合理内聚 |
| 20 | 异曲同工的类 Alternative Classes with Different Interfaces | ≥2 个类做同一件事但方法名 / 签名不一致 | Fowler | Rename Method / Move Function / Extract Interface | 两者语义只是表面相似、变化原因不同时，不强行统一 |
| 21 | 惰性元素 Lazy Element | 类 / 函数只做一件事且唯一调用者只有 1 处 | Fowler | Inline Class / Inline Function / Collapse Hierarchy | 元素是测试接缝或框架要求的扩展点时保留 |
| 22 | 过度泛化 Speculative Generality | 抽象只有 1 个实现，或存在从不使用的参数 / 钩子 | Fowler | Collapse Hierarchy / Inline Class / Remove Parameter | 已有排期中的第二个变体时，可先保留并记录依据 |
| 23 | 全局数据 Global Data | 可变全局 / 单例被 ≥2 个模块读写 | Fowler | Encapsulate Variable / 依赖注入 | 进程级不可变配置或日志句柄，封装后可直接使用 |
| 24 | 可变数据 Mutable Data | 同一数据被 ≥2 处修改，改一处无法判断影响范围 | Fowler | Encapsulate Variable / 拆分读写 / 不可变化 | 性能热点上的就地更新且有清晰边界时，记录理由后保留 |

判据：改动面大，放到有测试覆盖之后；一次只处理一类。

## 5. AI 生成代码 A1–A7

| A1 | 共享常量重复定义 | 同一常量 / 字面量在多个文件重复定义（阈值见 SKILL 表） | AI 生成实证 | 提取共享模块，引用单一事实源 | 常量只属于单个模块且不会跨文件复用时，就地定义即可 |
| A2 | 绕过现有封装 | 已有封装（apiClient / push_task_to_redis 等）外出现等价裸调用 | AI 生成实证 | 复用封装；封装不足则扩展封装 | 封装本身已废弃或有明确缺陷时，先修封装再用 |
| A3 | 测试 setup 复制 | 相同 mock 工厂 / seed / 样板在多个测试文件逐字重复（阈值见 SKILL 表） | AI 生成实证 | 提取共享 testHelper | 两个测试的 setup 只是字面相似但语义不同时，不合并 |
| A4 | 命名漂移 | 同一概念在代码中使用多种命名（阈值见 SKILL 表） | AI 生成实证 | 统一命名并引用同一来源 | 对外兼容的旧名需要保留时，加别名并标注迁移方向 |
| A5 | 贫血模型 / 职责错位 | 操作所需数据在类 X，操作却落在类外自由函数或别的类；判据是数据与操作的关系，不是有无成员方法 | AI 生成实证 | Move Function 收编（操作归数据专家） | 操作是跨对象的编排逻辑时，留在编排者而非数据类 |
| A6 | 伪多态（#13 重复 switch 的程序化形态，不单独计入总数） | 分派同一概念行为的 cast / instanceof / match / 类型 switch 散落多处（新增子类要改 N 处） | AI 生成实证 | Replace Conditional with Polymorphism | 不同概念的独立 cast、跨函数配对不算，不强行多态化 |
| A7 | out-param 束 | 签名含多个非 const 引用 out-param（阈值见 SKILL 表；刻意 in-out 钳制不算） | AI 生成实证 | Introduce Parameter Object / 收编为成员 | 构造 / 解析类多返回值是接口语义时，保留签名 |

判据：A1 / A2 优先于全部经典类；实现任何 helper 或常量前先按「复用优先」grep 已有同类。

## 6. 可测性坏味道（Feathers）

| T1 | 隐藏依赖 Hidden Dependency | 构造或方法内部直接 new、静态调用外部资源，测试无法注入 | Feathers《修改代码的艺术》 | Parameterize Constructor / Extract and Override Factory Method | 依赖是纯值对象或无副作用工具时，注入只增加噪声 |
| T2 | 全局状态 Global State | 单例 / 全局变量参与被测路径，测试顺序影响结果 | Feathers | Encapsulate Global References / Replace Global Reference with Getter | 进程级只读常量不构成状态污染，不处理 |
| T3 | 不可观测输出 Untestable Side Effect | 行为只写文件 / 网络 / 日志，无返回值或可查状态 | Feathers | Extract Interface / Wrap Method / 暴露查询点 | 副作用本身就是被测契约时，用替身观察而非改结构 |
| T4 | 巨型构造 Monster Constructor | 构造函数参数超过 SKILL 阈值表或构造过程中执行 IO | Feathers | Parameterize Constructor / Break Out Method Object | 参数是框架强制注入时，只拆构造内的 IO |
| T5 | 私有逻辑不可达 Private Logic | 关键分支只在 private 方法内，公共入口无法触发 | Feathers | Expose Static Method / Subclass to Test；先判是否属于公共契约 | 逻辑本就不该是公共契约时，测调用它的公共方法 |
| T6 | 时间 / 随机耦合 Nondeterminism | 直接读系统时钟 / 随机数 / 环境变量 | Feathers | Adapt Parameter / Parameterize Method | 时间只是日志时间戳且不参与断言时，不注入 |

判据：先找接缝再上替身；技术选择见 `../legacy-code/references/dependency-breaking.md`。

## 7. 模式误用（Kerievsky）

| P1 | 预置模式 Premature Pattern | 先有模式结构后找坏味道；抽象使用者 ≤1 | Kerievsky《重构与模式》 | AWAY：inline 回最直白写法 | 变体已真实存在且 ≥2 时，不拆模式 |
| P2 | 模式掩盖坏味道 Pattern Masking | 分支被搬进模式实现里继续 if / switch | Kerievsky | 继续 Replace Conditional with Polymorphism | 分支确实是模式内的合法配置差异时保留 |
| P3 | 孤立抽象 Orphan Abstraction | 接口只有 1 个实现且无排期中的第二个 | Kerievsky | AWAY：合并回原方法 | 接口是外部契约或测试接缝时保留 |
| P4 | 大爆炸重构 Big-Bang Refactor | 一次提交引入 ≥2 个模式或整套工厂 / 注册表 | Kerievsky | 拆成 TOWARDS 小步，每步测试绿 | 机械改名等单步低风险变更不受此限 |
| P5 | 模式堆叠 Pattern Stacking | 同一职责叠 ≥2 层模式（Factory + Builder + Singleton） | Kerievsky | 保留最简一层，其余 AWAY | 每层有独立且已发生的职责时，逐层评估后保留 |

判据：模式是目的地不是起点；只走到够用就停，多余就撤。结构见 `../design/references/gof.md`。

## 8. 设计层判断

| D1 | 抽象过早 Premature Abstraction | 同一概念只出现 1 次变化就建接口 / 基类 | 设计层 | 稳定中间形式；同一坏味道第三次重复才抽象（Rule of Three：第 1 次最直白，第 2 次记账，第 3 次抽象） | 同一坏味道已第三次重复且形态稳定时，应当抽象 |
| D2 | 抽象超出变体数 | 实现数 ≤1，或没有任何调用方 | 设计层 | AWAY 到最简形态 | 接口用于隔离外部依赖时，实现数不是唯一判据 |
| D3 | 依赖方向倒置 | 稳定策略依赖易变细节（业务层直接 import 框架层） | 设计层 | 依赖倒置 / 移动接缝 | 框架强制入口层依赖时，用适配器隔离而非硬改方向 |
| D4 | 概念重复 Concept Duplication | 同一领域概念在 ≥2 层各有模型与转换 | 设计层 | 统一模型，删中间映射 | 两层模型分属不同限界上下文时，保留并显式转换 |
| D5 | 无主职责 Orphan Responsibility | 同一操作在 ≥2 处各自实现，无单一归属 | 设计层 | 按 Information Expert 收编 | 两处实现服务于不同变化原因时，先区分概念 |

判据：设计层判断只在同一坏味道第三次重复后使用；AWAY 判据（实现数 ≤1，或没有任何调用方）同时约束 refactoring-to-patterns 的 TO / TOWARDS / AWAY。

## 附：检测顺序、来源与分工

**检测优先级**（先高后低）：

1. A1 / A2：重复与复用，agent 头号病，最先消除
2. A3：测试 setup 复制
3. A4：命名漂移
4. 经典结构类：函数级 → 变化与职责 → 耦合与结构
5. 可测性坏味道：动结构前先确认有安全网
6. 模式误用与设计层判断：抽象已存在时才评估

**复用优先**：实现任何 helper、常量、基础设施调用前，先 grep 代码库已有同类；找到就复用，找不到才创建并放在可被发现的位置。

**来源**：

- Fowler《重构》第 2 版：经典坏味道 24 类（ID 1–25，6 号保留空位）
- AI 生成代码实证：A1–A7（同一仓库三种病灶取证）
- Feathers《修改代码的艺术》：T1–T6 可测性坏味道
- Kerievsky《重构与模式》：P1–P5 模式误用
- 设计层判断：D1–D5，与 design / refactoring-to-patterns 共用判据

**与其他文件的分工**：

| 内容 | 唯一位置 |
|------|----------|
| 坏味道名称 / 特征 / 来源 / 首选手法 | 本文件 |
| 手法操作步骤 | `techniques.md` |
| 解依赖技术步骤 | `../legacy-code/references/dependency-breaking.md` |
| 模式结构与易混 | `../design/references/gof.md` |
| 演化路径与 TO / TOWARDS / AWAY | `../refactoring-to-patterns/references/evolution.md` |
| 阈值数值 | SKILL.md「判定阈值」表 |

**使用方式**：先按 SKILL.md 阈值定位嫌疑项，再在本文件中查该嫌疑项的名称与手法，最后按手法名打开 `techniques.md`。

**边界**：本文件只做索引与判定，不写操作步骤、不复制阈值数字、不承担演化链正文；为通过检查而搬运本文件内容到其它 reference 属违规。
