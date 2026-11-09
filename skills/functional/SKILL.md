---
name: functional
description: Use when designing data transformations, choosing between OO and functional style, or reviewing code for mutability and side effects. SKILL.md holds the paradigm-selection table, five building blocks, error containers, FP micro-rules, the anti-over-application gate and the 16-item review checklist; C++/Rust examples, FP↔OO collaboration, error handling and performance live in references/ and are read on demand.
---

# Functional — 函数式思维

不换语言，换表达方式。**表达式 > 语句，不可变 > 可变，组合 > 继承。**

> **默认倾向**：能用表达式/管道表达的，不写手写循环；能返回 optional/Result 的，不用 out-param 或异常控制流程。**例外**：C 语言、热点路径中的 `std::function`/`Box<dyn Fn>`、状态机与生命周期管理仍用 OO/命令式。

OO 与 FP 正交，不互斥：领域模型用 OO，内部计算用纯函数。

**本文件常驻 = 判定层。** references 只在对应问题出现时读，不要通读。

**目录**：索引 · 1 范式选型 · 2 五个构建块 · 3 错误容器 · 4 微规则 · 5 反 FP 闸门 · 6 语言适配 · 7 评审清单 · 与其他 skill 的边界

---

## 索引 — 要做什么 → 读哪个文件

| 要做的事 | 文件 |
|----------|------|
| 写高阶函数/闭包/柯里化/惰性求值/模式匹配的 C++ 与 Rust 代码、避坑 | `references/building-blocks.md` |
| 判断该用 OO 还是 FP、两者如何协作、策略/命令模式能否用 lambda 简化 | `references/fp-oo.md` |
| 用 Optional/expected/Option/Result 表达可预期失败、链式组合、错误传播 | `references/error-handling.md` |
| 评估 FP 写法的性能成本、热点路径怎么避开类型擦除 | `references/performance.md` |

---

## 1. 范式选型

| 问题特征 | 选 |
|----------|----|
| 复杂状态变迁 / 生命周期管理 | OO（实体、状态机） |
| 数据变换 / 过滤 / 聚合 | FP（管道） |
| 多态扩展（≥2 个实现、需运行期替换） | OO（接口 + 多态，且过 design 三问：职责 / 变化 / 依赖方向）；单实现直接传函数，见 §7 第 7 项 |
| 并发安全的数据处理 | FP（不可变数据） |
| 模拟现实实体关系 | OO（组合） |
| 需要数学式推理的纯逻辑 | FP（纯函数） |

---

## 2. 五个构建块（定义；示例见 `building-blocks.md`）

| 构建块 | 一句话定义 | 替代的 OO 结构 |
|--------|-----------|----------------|
| 高阶函数 | 接受函数作参数或返回函数作结果 | 策略类、命令类 |
| 闭包 | 捕获定义处作用域变量的函数值 | 只为一个方法存在的内部类 |
| 柯里化 | 把多参函数拆成单参序列，复用前缀参数 | 参数对象 + 工厂 |
| 惰性求值 | 元素在真正需要时才计算，可表达无限序列 | 手写迭代器 |
| 模式匹配 | 按数据结构分支并解构，编译器检查穷尽 | 有限类型的多态 |

## 3. 错误容器

| 容器 | 表达 | 不该用它做的事 |
|------|------|----------------|
| Optional / Option | 可能没有值 | 包装「业务失败的原因」 |
| Either / Result | 失败 + 原因 | 替代全部领域异常的层级设计 |
| Try | 包装可能抛异常的边界 | 层层嵌套、把内部逻辑也塞进去 |

**红线**：不可预期的编程错误仍用异常。不要把错误处理全部改造成容器。

## 4. 微规则（6 条）

**裁决句：领域对象的行为留在对象上；表达式化只用于数据变换与无状态逻辑。**

1. **表达式优先** — 有返回值的写法优于就地修改
2. **管道替代循环** — `map/filter/fold` 表达意图，避免索引错误
3. **默认不可变** — `const` / `final` / `readonly`，新增而非修改
4. **副作用推边界** — IO / DB / 网络独立成层，核心逻辑纯
5. **纯函数优先** — 同输入同输出，无隐藏状态
6. **小函数组合** — 一个函数只做一次变换

## 5. 反 FP 闸门（过度应用即负分）

- 一个表达式内管道超过 **6 段** → 提取具名中间函数
- 嵌套 `fold/reduce` 层级超过 **2 层** → 改写为显式循环或具名函数
- 为单个 lambda 造一个类 → 直接在调用处传函数
- 语言缺乏 FP 设施（如 C）→ 不模拟，用直白写法
- 纯函数化导致需要传 4 个以上上下文参数 → 说明抽象选错了
- 为炫技写无点风格（point-free）、无收益的柯里化 → 回退到直白写法

## 6. 语言适配

| 语言 | 可用设施 |
|------|----------|
| TS / JS | Array 高阶方法、可选链、Promise |
| Java | Stream、Optional、lambda |
| Python | 推导式、生成器、itertools |
| C++ | `std::ranges`/`std::views`、lambda、`std::optional`、`std::expected`（C++23） |
| Rust | 迭代器链、闭包、`Option`/`Result`、`enum` + `match` |
| C | 不适用，不硬套 |

## 7. 评审清单（16 项）

第 1–8 项见 §1 范式选型、§2 构建块、§3 错误容器、§4 微规则对应条目，逐条核对不复述。余下 8 项：

- [ ] 9. 无可变共享状态；确有并发共享时不可变或明确同步
- [ ] 10. 并发处理优先利用不可变数据，避免锁
- [ ] 11. C++ 闭包捕获无悬空（局部变量按值捕获）
- [ ] 12. Rust 闭包注意 move 与所有权，借用冲突用 Cell/Rc
- [ ] 13. 惰性序列没有被多次遍历（需要时先 collect/缓存）
- [ ] 14. 模式匹配分支穷尽（Rust 未用 `_` 掩盖未处理类型）
- [ ] 15. 热点路径没有 `std::function` / `Box<dyn Fn>` 类型擦除
- [ ] 16. C++ 合理使用 `std::views` 与 `std::ranges`，未手写等价循环

## 与其他 skill 的边界

| 问题 | 用哪个 |
|------|--------|
| 职责归属、契约、模式选型 | design |
| 怎么写出干净代码 | refactoring（Clean Code 微规则）+ 本 skill |
| FP 与 OO 如何协作、模式能否用 lambda 简化 | 本 skill → `references/fp-oo.md` |
| 怎么验证行为 | story-executor 的 RED-GREEN-REFACTOR + testing-techniques |

| 场景 | 判据 |
|------|------|
| 何时读 | 设计数据变换、在 OO 与 FP 间选型、或评审可变共享状态与副作用时读本 skill |
| 何时不读 | 纯结构重构（行为不变，回 refactoring）、既有代码缺测试（先补安全网）、或语言缺乏 FP 设施时不读 |
