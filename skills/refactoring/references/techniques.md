# 重构技术 — 对照表与速查

回到索引: [../SKILL.md](../SKILL.md)

> 坏味道的名称、识别特征与首选手法统一见 `smells-catalog.md`；本文件只给手法与步骤。

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
| 消息链 | Hide Delegate / Extract Method |
| 中间人 | Remove Middle Man / Inline Method |
| 过度亲密 | Move Method / Change Bidirectional Association to Unidirectional |
| 异曲同工的类 | Rename Method / Move Method |
| 注释 | Extract Method / Rename Method / Introduce Assertion |
| 嵌套层次过深 | Replace Nested Conditional with Guard Clauses / Extract Method |

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
| **Replace Nested Conditional with Guard Clauses** | 用卫语句替换深层嵌套的条件分支 | 识别可提前返回的条件 → 提取为 `if (!condition) return;` 形式的卫语句 → 消除嵌套层 → 若残留嵌套仍 ≥ 3 层，重复步骤或将剩余部分 Extract Method |
| **Replace Loop with Pipeline** | 用 map/filter/reduce 或 ranges 替换手写索引循环 | 提取循环体为单个元素变换 → 依次串成 filter/map → 聚合步骤用 reduce/accumulate → 管道 > 6 段时提取具名中间函数 |
| **Replace Strategy Class with Function** | 只有一个方法的策略类改为函数参数 | 确认该接口仅一个方法且无状态 → 调用方直接接收函数 → 删除接口与实现类 |

---

## 补充手法（Fowler 第 2 版新增/常用）

| 技术 | 描述 | 操作指引 |
|------|------|----------|
| **Replace Temp with Query** | 用查询方法替代临时变量 | 抽出计算为方法 → 用调用替换变量 → 减少方法内状态 |
| **Remove Flag Argument** | 拆分布尔标志参数 | 每个标志值拆成一个语义化函数 → 更新调用方 |
| **Decompose Conditional** | 拆解复杂条件 | 条件、then 分支、else 分支各提取为命名方法 |
| **Consolidate Conditional Expression** | 合并结果相同的条件 | 多个条件用 `||` 合并 → 提取为命名布尔方法 |
| **Replace Nested Conditional with Guard Clauses** | 卫语句消除嵌套 | 异常分支提前 return → 主干逻辑不再缩进 |
| **Introduce Null Object** | 用空对象替代 null | 建空实现类 → 返回空对象 → 删除调用方 null 判断 |
| **Replace Inheritance with Delegation** | 继承改委托 | 持有父类实例为字段 → 转发需要的方法 → 删除继承 |
| **Push Down Method / Field** | 成员下移到真正使用它的子类 | 确认只有部分子类使用 → 移到子类 → 父类删除 |
| **Collapse Hierarchy** | 合并无差别的父子类 | 成员上移到父类（或下移）→ 删除空层 |
| **Extract Subclass** | 提取只用于部分场景的特性 | 建子类 → 下移相关字段/方法 → 父类保持通用 |
| **Encapsulate Record** | 记录（map/struct）封装为对象 | 私有化字段 → 提供访问方法 → 逐步加行为 |
| **Encapsulate Collection** | 集合只暴露只读视图 | 去掉 setter → 提供 add/remove → 返回不可变视图 |
| **Substitute Algorithm** | 替换为更清晰的算法 | 用测试锁住行为 → 整体替换 → 跑测试 |
| **Change Bidirectional Association to Unidirectional** | 双向关联改单向 | 确认一方不再需要反向引用 → 删除该引用 → 修正查询路径 |
| **Separate Query from Modifier** | 拆开「又改又返回」的方法 | 查询方法只读 → 命令方法只改 → 更新调用方 |
| **Split Phase** | 拆成两个阶段（如解析 / 计算） | 定义中间数据结构 → 阶段一产出 → 阶段二消费 |
| **Remove Dead Code** | 删除死代码 | 确认无引用 → 删除 → 测试保持绿 |
| **Rename Variable / Field** | 变量/字段改名表达意图 | 机械重命名 → 跑测试 |

| **Extract Interface** | 从类提取接口，客户端依赖抽象 | 锁定客户端所需的方法（≥2 个）→ 新建接口声明这些方法 → 原类实现接口 → 客户端类型改为接口 |
| **Extract Superclass** | 将 ≥2 个子类的共同成员上提 | 确认共同成员在 ≥2 处重复 → 新建父类 → 上移字段与方法 → 子类继承父类 |
| **Replace Type Code with State** | 类型码驱动状态切换时改为状态对象 | 确认类型码在 ≥2 处影响行为 → 建状态接口 → 每个状态一个实现 → 上下文委托给当前状态 |
| **Use Optional** | 用 Optional 表达可能缺失的返回值 | 确认返回 null 表示「无值」而非错误 → 返回 Optional → 调用方显式处理空值 |

**Optional / Assertion 边界**：Optional 只用于「返回值可能缺失」；用 Optional 替代错误分支或控制流属误用。Introduce Assertion 只用于锁定不可恢复的内部不变量；用户输入校验与可恢复错误用正式错误处理。两者都不是坏味道的独立手法，只在消坏味道后顺手补齐。

### 选择顺序（低风险优先）

```
Rename → Extract Method → Replace Temp with Query → Move Method
→ Introduce Parameter Object → 多态化（Replace Conditional with Polymorphism）
→ 上模式（`refactoring-to-patterns/references/evolution.md`）
```

每一步都必须「测试绿 → 改 → 测试绿」，失败回滚该步（见 `workflow.md`）。
