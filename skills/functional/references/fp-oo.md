# FP 与 OO — 差异、协作与互相简化

回到索引: [../SKILL.md](../SKILL.md)

两者正交，不是替代关系。选型看「这层代码在做什么」，不看个人偏好。

## 核心差异（6 维）

| 维度 | OO | FP |
|------|----|----|
| 核心抽象 | 对象 = 状态 + 行为 | 函数 = 输入到输出的变换 |
| 状态管理 | 对象持有并封装可变状态 | 数据不可变，新值代替修改 |
| 组合方式 | 组合 / 继承 / 委托 | 函数组合、管道 |
| 副作用 | 方法调用常带副作用 | 副作用推到边界，核心纯 |
| 代码组织 | 按名词（领域实体） | 按动词（变换步骤） |
| 多态实现 | 子类型多态（虚函数 / trait object） | 参数多态（泛型）+ 特设多态（trait bound） |

## 协作矩阵 — 同一系统里各管一段

| 场景 | 用 OO 的部分 | 用 FP 的部分 |
|------|-------------|-------------|
| 领域模型 | 实体、值对象、聚合封装状态与不变量 | 领域服务内部的计算用纯函数 |
| 业务流程 | 编排用命令 / 责任链，明确步骤与顺序 | 单步数据处理用 map/filter/fold |
| 并发 | Actor / 线程封装可变状态 | 不可变数据并行转换 |
| 配置与策略 | 需要运行期替换多种实现 | 一个函数够用时直接传 lambda / 闭包 |

范式选型见 [SKILL.md §1](../SKILL.md#1-范式选型)，本文件只讲协作边界。

## 策略模式的 FP 简化

实现数量少、不需要运行期反射时，接口 + 实现类往往只剩一个方法，可直接传函数。

**C++**
```cpp
// OO：多实现、需要按类型存放时仍合理
struct Discount { virtual double apply(double) const = 0; virtual ~Discount() = default; };
struct TenPercent : Discount { double apply(double p) const override { return p * 0.9; } };
double checkout_oo(double total, const Discount& d) { return d.apply(total); }

// FP：单个策略直接传 lambda
template <class F> double checkout(double total, F f) { return f(total); }
double total = checkout(100.0, [](double p) { return p * 0.9; });
```

**Rust**
```rust
trait Discount { fn apply(&self, price: f64) -> f64; }
struct TenPercent;
impl Discount for TenPercent { fn apply(&self, p: f64) -> f64 { p * 0.9 } }
fn checkout_oo(total: f64, d: &dyn Discount) -> f64 { d.apply(total) }

fn checkout<F: Fn(f64) -> f64>(total: f64, f: F) -> f64 { f(total) }
let total = checkout(100.0, |p| p * 0.9);
```

## 命令模式的 FP 简化

命令只需「无参可调用」时，用 `map<名字, 函数>` 替代一个命令类层次 + 工厂。

**C++**
```cpp
std::map<std::string, std::function<void()>> commands;
commands["save"] = [] { /* save */ };
commands.at("save")();
```

**Rust**
```rust
use std::collections::HashMap;
let mut commands: HashMap<&str, Box<dyn Fn()>> = HashMap::new();
commands.insert("save", Box::new(|| { /* save */ }));
(commands["save"])();
```

**边界**：命令需要撤销/重做、序列化、审计等额外状态时，回到显式命令对象；`std::function`/`Box<dyn Fn>` 在热路径有类型擦除开销，见 `performance.md`。
