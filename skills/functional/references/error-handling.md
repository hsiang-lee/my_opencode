# 错误处理 — 用容器表达可预期失败

回到索引: [../SKILL.md](../SKILL.md)

`try-catch` / `panic` 用于**不可预期**的编程错误；可预期失败（解析失败、找不到、除零、校验不过）用返回容器显式表达，调用方无法忽略。

## 容器选择

| 容器 | 何时用 | 携带信息 |
|------|--------|----------|
| `std::optional` / `Option<T>` | 只是「可能没有」，不需要原因 | 有 / 无 |
| `std::expected<T,E>` / `Result<T,E>` | 失败需要原因，调用方要分支处理 | 值 或 错误 |
| `Either`（语言无原生时自建） | 等价于 expected/Result 的二元和类型 | 左值 或 右值 |
| `Try` / 异常包装 | 只在系统边界接住第三方异常 | 异常对象 |

## C++ — optional

```cpp
#include <optional>

std::optional<double> safe_divide(double a, double b) {
    if (b == 0.0) return std::nullopt;
    return a / b;
}

// C++23 单子操作：and_then 串联可能失败的计算，transform 映射成功值
auto result = safe_divide(10.0, 2.0)
                  .and_then([](double x) { return safe_divide(x, 5.0); })
                  .transform([](double x) { return x * 100.0; })
                  .value_or(0.0); // 100.0
```

## C++ — expected
```cpp
#include <expected>
#include <string>

std::expected<int, std::string> parse_int(const std::string& s) {
    try {
        return std::stoi(s);                       // 边界内允许异常
    } catch (const std::exception&) {
        return std::unexpected("not a number: " + s);
    }
}

auto doubled = parse_int("42").transform([](int x) { return x * 2; });
if (!doubled) std::puts(doubled.error().c_str());
```

## Rust — Option

```rust
fn safe_divide(a: f64, b: f64) -> Option<f64> {
    if b == 0.0 { None } else { Some(a / b) }
}

let r = safe_divide(10.0, 2.0)
    .and_then(|x| safe_divide(x, 5.0))
    .map(|x| x * 100.0)
    .unwrap_or(0.0); // 100.0
```

## Rust — Result 与 `?`
```rust
fn parse_int(s: &str) -> Result<i32, std::num::ParseIntError> {
    s.parse::<i32>()
}

struct Address { city: String }
struct User { address: Option<Address> }

// ? 自动向上传播，避免层层 match
fn get_user_city(user: &User) -> Option<&str> {
    let address = user.address.as_ref()?;
    Some(&address.city)
}
```

```rust
fn get_user_city_by_id(id: u64) -> Result<String, String> {
    let user = load_user(id)?;                       // Result 传播
    let address = user.address.ok_or("no address")?; // Option → Result
    Ok(address.city)
}
```

## C++ optional vs Rust Option
| 操作 | C++ `std::optional` | Rust `Option` |
|------|---------------------|---------------|
| 链式组合 | `and_then` / `transform` / `or_else`（C++23） | `and_then` / `map` / `or_else` |
| 模式匹配 | `if (opt)` / `*opt` / `value_or` | `match` / `if let` |
| 组合性 | 依赖 C++23 单子接口；C++17 需手写 if | 原生方法齐全，`?` 直接传播 |
| 引用语义 | 值语义，注意拷贝 | 借用 / move，零拷贝 |

## 边界（误用即负分）

- `Optional`/`Option` 只表达「无」，**不包装业务失败原因**；需要原因换 `expected`/`Result`。
- `Either`/`Result` **不替代整个领域异常层级**；不可预期错误仍让异常/panic 处理。
- `Try` **只包边界**：把第三方异常转成 Result；不要用它包住内部每一步。
- 容器嵌套超过两层（`Option<Result<...>>`）→ 先归一或提前返回，别让调用方拆包。
