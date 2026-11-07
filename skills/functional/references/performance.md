# 性能 — FP 抽象的真实成本

回到索引: [../SKILL.md](../SKILL.md)

FP 在 release 下通常零成本，但四类写法会把抽象变成开销。先判断是否在热路径，再决定是否换写法。

## 成本表

| 写法 | C++ | Rust | 何时付代价 | 对策 |
|------|-----|------|-----------|------|
| 不可变数据 | 每次修改新建容器，深拷贝 | 所有权转移零成本，`clone` 才拷贝 | 大对象频繁「修改」 | `std::shared_ptr` / `Rc` / `Arc`；持久化结构（immer） |
| 闭包捕获 | 捕获对象按值存入闭包 | 同上，`move` 转移 | 捕获大对象 / 多次复制 | 捕获 `shared_ptr`/`Rc`，或只捕获最小字段 |
| 类型擦除 | `std::function` 有堆分配 + 虚调用 | `Box<dyn Fn>` 有虚调用 | 每秒百万次调用 | 模板参数 / `auto` lambda / `impl Fn` |
| 惰性迭代器 | `std::views` 零成本 | 迭代器链零成本 | 跨越多次遍历 | 需要复用就 `collect` 成集合 |
| 递归 | 无尾递归保证 | 无尾递归保证 | 深递归爆栈 | 改 `fold` / 显式循环 |
| 模式匹配 | `std::visit` 编译为跳转表 | `match` 编译为跳转表 | 分支极多时指令缓存 | 通常无需优化 |

## 基准参考（量级，随编译器与平台浮动）

> 以下为经验量级（Ford《Functional Thinking》与常见编译器实测），不是保证值；性能决策以本机基准为准。

- C++ `std::ranges` 管道 vs 手写循环：差距 **<5%**。
- Rust 迭代器 vs 手写 `for`：**相同甚至更快**（消除边界检查）。
- `std::function` vs 模板 lambda：**慢 10-30%**（堆分配 + 间接调用）。
- `Box<dyn Fn>` vs `impl Fn`：有虚调用开销，单次差异小、百万次显著。
- 惰性链被多次遍历：复杂度从 O(n) 退化到 O(k·n)，比任何擦除开销都大。

## 规则

1. **热点路径避免类型擦除**：C++ 用模板参数或 `auto`，Rust 用 `impl Fn` / 泛型。
2. **性能敏感处做基准**，不凭感觉否定 FP；先 profile 再换写法。
3. **release 下抽象几乎零成本**：优化必须开 `-O2`/`-O3`，debug 数据不作数。
4. **先消重复遍历**：惰性链需要多次用时先 `collect`，收益通常大于微调闭包。
5. **持久化不可变结构**只在「大对象频繁小改」时才引入，别为小数据上 immer。

## 热路径改法（C++ / Rust）

```cpp
// 热路径：模板参数，静态分派，可内联
template <class F>
void apply_all(std::vector<int>& v, F f) {
    for (auto& x : v) x = f(x);
}

// 冷路径 / 需要异构存放：std::function 可接受
std::function<int(int)> fn = [](int x) { return x * 2; };
```

```rust
fn apply_all<F: Fn(i32) -> i32>(v: &mut [i32], f: F) {
    for x in v {
        *x = f(*x);
    }
}

// 异构集合才需要 Box<dyn Fn>
let handlers: Vec<Box<dyn Fn(i32) -> i32>> = vec![Box::new(|x| x * 2)];
```

## 判据

```text
这段代码每秒调用 > 10^5 次？
├── 是 → 检查 std::function / Box<dyn Fn> / 大对象 clone；用基准验证
└── 否 → 保持 FP 写法，可读性优先
```
