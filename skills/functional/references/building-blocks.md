# 五个构建块 — C++ 与 Rust 实战

回到索引: [../SKILL.md](../SKILL.md)

**目录**：1 高阶函数 · 2 闭包 · 3 柯里化 · 4 惰性求值 · 5 模式匹配
## 1. 高阶函数 — 定义：函数可作参数传入，也可作结果返回

**C++**
```cpp
std::vector<int> xs{1, 2, 3, 4}, ys(xs.size());
std::transform(xs.begin(), xs.end(), ys.begin(), [](int x) { return x * x; });
template <class C, class Fn>                    // zero-cost custom HOF
auto my_map(const C& in, Fn fn) {
    using R = std::invoke_result_t<Fn, typename C::value_type>;
    std::vector<R> out;
    for (const auto& x : in) out.push_back(fn(x));
    return out;
}
auto make_adder = [](int n) { return [n](int x) { return x + n; }; };
```

**Rust**
```rust
let xs = vec![1, 2, 3, 4];
let ys: Vec<i32> = xs.iter().map(|x| x * x).collect();
fn my_map<T, U, F: Fn(&T) -> U>(v: &[T], f: F) -> Vec<U> { v.iter().map(f).collect() }
fn make_adder(n: i32) -> impl Fn(i32) -> i32 { move |x| x + n }
let boxed: Box<dyn Fn(i32) -> i32> = Box::new(|x| x + 1);
```
**陷阱**

> 以下为经验量级（Ford《Functional Thinking》与常见编译器实测），不是保证值；性能决策以本机基准为准。

| 陷阱 | 现象 | 对策 |
|------|------|------|
| C++ 按引用捕获局部变量 | 返回后调用 → 悬空 UB | 按值捕获 `[x]` |
| `std::function` 用于热路径 | 堆分配 + 虚调用，慢 10-30% | 模板参数 / `auto` lambda |
| Rust 闭包默认不可变捕获 | 想改捕获变量编译失败 | `Cell`/`RefCell`，或 `move` + `mut` |

**建议**：先用内置 `std::ranges` / `Iterator`；策略、回调、比较器用 lambda 替代函数指针或单方法接口类；热路径 C++ 避免 `std::function`，Rust 优先 `impl Fn`。
## 2. 闭包 — 定义：捕获定义处作用域变量的函数值，携带私有状态而不建类

**C++**
```cpp
auto make_counter = [] { return [n = 0]() mutable { return ++n; }; };
template <class Fn>                             // memoization, shared cache
auto memoize(Fn fn) {
    using R = std::invoke_result_t<Fn, int>;
    auto cache = std::make_shared<std::map<int, R>>();
    return [cache, fn](int n) -> R {
        auto it = cache->find(n);
        if (it != cache->end()) return it->second;
        (*cache)[n] = fn(n);
        return (*cache)[n];
    };
}
```

**Rust**
```rust
use std::cell::{Cell, RefCell};
use std::rc::Rc;

fn make_counter() -> impl Fn() -> i32 {
    let n = Cell::new(0);
    move || { n.set(n.get() + 1); n.get() }
}
fn memoize<F: Fn(u32) -> u64>(f: F) -> impl Fn(u32) -> u64 {
    let cache = Rc::new(RefCell::new(std::collections::HashMap::new()));
    move |n| *cache.borrow_mut().entry(n).or_insert_with(|| f(n))
}
```
**陷阱**

| 陷阱 | 现象 | 对策 |
|------|------|------|
| C++ 按引用捕获 | 闭包比被捕获对象活得久 → 悬空 | 按值捕获或 `shared_ptr` |
| C++ 捕获后不可修改 | 编译错误 | 闭包加 `mutable` |
| Rust 借用冲突 | 同时需要 `&` 与 `&mut` | `Rc<RefCell<T>>` 或拆分状态 |

**建议**：计数器、序列生成器、一次性回调优先闭包，比类轻量；记忆化是闭包经典用法，缓存用 `shared_ptr`/`Rc` 保证跨调用存活；状态需跨线程共享时回到显式类型 + 同步。
## 3. 柯里化 — 定义：把 `f(a, b, c)` 变成 `f(a)(b)(c)`，每次只接受一个参数

**C++**
```cpp
auto add3 = [](int a) { return [a](int b) { return [a, b](int c) { return a + b + c; }; }; };
auto discount = [](double rate) { return [rate](double price) { return price * (1.0 - rate); }; };
auto ten_off = discount(0.10);
double p = ten_off(100.0); // 90
```

**Rust**
```rust
let add3 = |a: i32| move |b: i32| move |c: i32| a + b + c;
fn discount(rate: f64) -> impl Fn(f64) -> f64 { move |price| price * (1.0 - rate) }
let p = discount(0.10)(100.0); // 90
```

**与偏函数应用的区别**

| 概念 | 含义 | C++ | Rust |
|------|------|-----|------|
| 柯里化 | 全部参数逐个传入 | 嵌套 lambda | 嵌套 `move` 闭包 |
| 偏函数应用 | 固定前几个参数，返回接收剩余参数的函数 | `std::bind` / lambda | 手工闭包固定首参 |

**陷阱**

| 陷阱 | 现象 | 对策 |
|------|------|------|
| 参数少于 3 个 | 收益不大，可读性下降 | 直接多参函数 |
| C++ 嵌套 lambda 冗长 | 类型签名爆炸 | 具名 lambda 或直接捕获 |

**建议**：用于预设参数（折扣率、税率、日志前缀、比较键）；只固定首个参数时优先偏函数应用；参数 ≥3 且需顺序复用才值得，否则具名参数结构体更清楚。
## 4. 惰性求值 — 定义：元素在真正需要时才计算，可表达无限序列并按需截断

**C++**
```cpp
// iota + filter + transform + take → 4 16 36 64 100
auto squares = std::views::iota(1) | std::views::filter([](int n) { return n % 2 == 0; })
             | std::views::transform([](int n) { return n * n; }) | std::views::take(5);

std::generator<long long> fibonacci() {       // C++23 coroutine generator
    long long a = 0, b = 1;
    while (true) { co_yield a; auto next = a + b; a = b; b = next; }
}
```

**Rust**
```rust
let squares: Vec<i32> = (1..).filter(|n| n % 2 == 0).map(|n| n * n).take(5).collect();

struct Fibonacci { a: u64, b: u64 }
impl Iterator for Fibonacci {
    type Item = u64;
    fn next(&mut self) -> Option<u64> {
        let v = self.a;
        self.a = self.b;
        self.b = v + self.b;
        Some(v)
    }
}
let fibs: Vec<u64> = (Fibonacci { a: 0, b: 1 }).take(10).collect();
```
**陷阱**

| 陷阱 | 现象 | 对策 |
|------|------|------|
| 惰性序列被多次遍历 | 每次从头算，复杂度翻倍 | 先 `collect`/拷贝缓存 |
| C++ view 引用临时数据 | view 存活时数据已销毁 → 悬空 | 容器生命周期覆盖 view |
| Rust 迭代器单次消费 | 消费后无法再用 | 需要多次用就 `collect` |

**建议**：大数据集用惰性链减少中间集合，小数据直接 `collect`；无限序列一律用生成器；release 下 `std::views` 与 Rust 迭代器通常零成本。
## 5. 模式匹配 — 定义：按数据结构的形状分支并解构，编译器检查分支是否穷尽

**Rust**
```rust
enum Shape { Circle { r: f64 }, Rect { w: f64, h: f64 }, Triangle { b: f64, h: f64 } }

fn area(s: &Shape) -> f64 {
    match s {
        Shape::Circle { r } => std::f64::consts::PI * r * r,
        Shape::Rect { w, h } => w * h,
        Shape::Triangle { b, h } => 0.5 * b * h,
    }
}
```

**C++**
```cpp
struct Circle { double r; }; struct Rect { double w, h; }; struct Triangle { double b, h; };
using Shape = std::variant<Circle, Rect, Triangle>;

double area(const Shape& s) {                   // style 1: if constexpr
    return std::visit([](auto&& x) -> double {
        using T = std::decay_t<decltype(x)>;
        if constexpr (std::is_same_v<T, Circle>) return 3.141592653589793 * x.r * x.r;
        else if constexpr (std::is_same_v<T, Rect>) return x.w * x.h;
        else return 0.5 * x.b * x.h;
    }, s);
}

template <class... Ts>                          // style 2: overload helper
struct overload : Ts... { using Ts::operator()...; };
template <class... Ts> overload(Ts...) -> overload<Ts...>;

double area2(const Shape& s) {
    return std::visit(overload{
        [](const Circle& c)   { return 3.141592653589793 * c.r * c.r; },
        [](const Rect& r)     { return r.w * r.h; },
        [](const Triangle& t) { return 0.5 * t.b * t.h; },
    }, s);
}
```
**陷阱**

| 陷阱 | 现象 | 对策 |
|------|------|------|
| `std::visit` 未覆盖所有类型 | 编译错误（这是好事） | 补全分支或用 `overload` |
| variant 取最大成员大小 | 含大对象时内存膨胀 | 存 `unique_ptr` / 索引 |
| Rust match 用 `_` 兜底 | 新增变体时漏处理不报警 | 尽量穷举，不用通配符 |

**建议**：Rust 优先 `enum` + `match` 替代复杂类型分支与 `dynamic_cast`；C++ 用 `variant` + `visit` 替代 `dynamic_cast` 链；类型集合有限且稳定时才用匹配，持续扩展的多态更适合虚函数。
