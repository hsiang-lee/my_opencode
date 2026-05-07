---
name: tdd
description: Use when implementing any feature or bugfix, before writing implementation code, or when writing unit tests. Covers RED-GREEN-REFACTOR cycle, link-time seams, runtime seams, Arrange-Act-Assert pattern, FIRST principles, and fake test detection.
---

# 测试驱动开发 & 单元测试

## 核心原则

**先写测试。观察它因正确原因失败。写最少代码让它通过。重构保持通过。**

**如果你没看到测试因为功能缺失而失败，你就不知道它是否测试了正确的东西。**

违反了这条规则的字面意思就是违反了规则的精神。

---

## 铁律

```
没有先失败的测试就不要写生产代码。
```

先写代码再写测试？删除代码。重新开始。

没有例外：
- 不要作为"参考"保留
- 测试时不要"适配"已有代码
- 删除就是删除

---

## RED-GREEN-REFACTOR 循环

### RED — 写失败测试

写一个展示**应该发生什么**的最小测试。

**要求：**
- 一个行为（名称中有 "and" 就拆开）
- 清晰的名称：`test('rejects empty email')` 不是 `test('test1')`
- 测试真实代码（除非无法避免，不用 mock）
- 测试公共接口，不是内部实现

```typescript
// ✅ 好: 清晰名称，测试真实行为，一个东西
test('retries failed operations 3 times before failing', async () => {
  let attempts = 0;
  const operation = () => {
    attempts++;
    if (attempts < 3) throw new Error('fail');
    return 'success';
  };
  const result = await retryOperation(operation);
  expect(result).toBe('success');
  expect(attempts).toBe(3);
});
```

### 验证 RED — 观察它失败

**强制。从不跳过。**

```bash
# 运行测试
npm test path/to/test.test.ts
```

确认：
- [ ] 测试**失败**（不是错误）
- [ ] 失败消息是**预期的**
- [ ] 因为**功能缺失**而失败（不是拼写错误/语法错误）

| 现象 | 问题 | 处理 |
|------|------|------|
| 测试**通过** | 在测试已有功能 | 修复测试直到因正确原因失败 |
| 测试**错误** | 测试本身有 bug | 修复测试代码 |
| 失败原因**不对** | 断言写错了 | 修正断言 |

**测试通过？你在测试现有行为。修复测试。**

### GREEN — 最少代码

写最简单的代码让测试通过。刚好足够。不要添加功能、重构其他代码、或超出测试"改进"。

`return "hardcoded value"` 是合法的第一步。YAGNI。

### 验证 GREEN — 观察它通过

**强制。**

```bash
npm test path/to/test.test.ts
```

确认：
- [ ] 这个测试通过
- [ ] 其他测试仍然通过
- [ ] 输出干净

**测试失败？** 修复代码，不是测试。
**其他测试失败？** 立即修复。

### REFACTOR — 清理

仅在 green 之后：
- 删除重复
- 改进命名
- 提取辅助函数

保持测试 green。**不要添加行为。**

---

## 🔴 Fake Test 禁止清单

以下模式的测试**毫无价值**，写了等于没写：

| 假测试模式 | 示例 | 问题 |
|-----------|------|------|
| **Null 检查** | `expect(result).not.toBeNull()` | 任何非 null 输出都通过 |
| **无异常检查** | `expect(fn).not.toThrow()` | 只检查不崩溃，不验证结果 |
| **已定义检查** | `expect(result).toBeDefined()` | 任何非 undefined 输出都通过 |
| **Mock 调用** | `expect(mock).toHaveBeenCalled()` | 测试 mock 行为，不是真实代码 |
| **空测试** | `test('works', () => {})` | 总是通过，什么都不验证 |
| **永真断言** | `expect(true).toBe(true)` | 永远是 true，欺骗覆盖率 |
| **仅快乐路径** | 一个测试只有正常输入 | 一有边界/异常输入就坏 |
| **内部状态** | `expect(obj._private).toBe(x)` | 测试实现细节，重构就坏 |

### 每个测试必须包含

1. **一个具体行为的验证** — 名称描述行为
2. **有意义的断言** — 具体值/状态/输出，不是 null/undefined
3. **真实输入** — 具体值，不是随机生成
4. **公共接口验证** — 通过公共 API，不触碰内部

---

## 单元测试技术

### 接缝 (Seam) 技术

#### Link-Time Seams (编译期替换)

**用于:** 外部库、硬件依赖、文件系统、日期时间、随机函数

```
1. 识别依赖 (e.g., Database::getConnection())
2. 在 tests/mocks/ 创建同签名 mock
3. 链接 mock 在真实实现之前
```

```cpp
// src/network/http_client.cpp
#include "database.h"
HttpClient::HttpClient(Database& db) : db_(db) {}
Result HttpClient::fetch(const std::string& url) {
    auto conn = db_.getConnection();
    // ...
}

// tests/mocks/database.cpp ← 同头文件，mock 实现
#include "database.h"
Connection Database::getConnection() {
    return Connection{/* mock data */};
}
```

#### Runtime Seams (接口注入)

**用于:** 内部模块边界、复杂依赖的业务逻辑

```
1. 从具体类提取接口
2. 消费者接受接口指针/引用
3. 测试时注入 mock
```

```cpp
class IPaymentGateway {
public:
    virtual ~IPaymentGateway() = default;
    virtual Result charge(Money amount) = 0;
};

class OrderProcessor {
    std::unique_ptr<IPaymentGateway> gateway_;
public:
    OrderProcessor(std::unique_ptr<IPaymentGateway> g)
        : gateway_(std::move(g)) {}
};
```

---

### Arrange-Act-Assert (AAA)

```cpp
TEST(ClassName, behavior_under_condition) {
    // Arrange: 设置输入和依赖
    auto mock = create_mock();
    auto input = make_valid_input();

    // Act: 执行行为
    Result result = objectUnderTest.process(input);

    // Assert: 验证结果
    EXPECT_TRUE(result.is_ok());
    EXPECT_EQ(result.value(), expected_value);
}
```

---

### FIRST 原则

- **Fast**: 测试在毫秒级完成
- **Independent**: 测试之间不依赖
- **Repeatable**: 每次相同结果
- **Self-checking**: 自动判断通过/失败
- **Timely**: 紧挨生产代码编写

---

### 工厂函数 (Factory Functions)

用默认参数创建测试数据，减少重复设置：

```cpp
Order make_order(Money amount = Money{100},
                CustomerTier tier = CustomerTier::REGULAR) {
    return Order{
        .id = "ORD-001",
        .amount = amount,
        .customer_tier = tier,
        .discount_percent = tier == CustomerTier::PREMIUM ? 15 : 0
    };
}

TEST(OrderProcessor, applies_discount_for_premium) {
    auto order = make_order(Money{100}, CustomerTier::PREMIUM);
    // 干净: 1 行 setup，意图清晰
}
```

---

### 测试命名

格式: `Unit_BehaviorUnderCondition`

```cpp
TEST(OrderProcessor, calculates_discount_for_premium_customer)
TEST(StringUtil, splits_on_newline)
TEST(PaymentGateway, returns_error_for_declined_card)
```

---

### 测什么 / 不测什么

**必须测:**
- ✓ 公共接口和行为
- ✓ 边界条件（空/null/零、单项、最大/溢出、负值、超长输入）
- ✓ 错误处理（异常、无效输入、超时）
- ✓ Golden path + edge cases

**禁止测:**
- ❌ 第三方库
- ❌ 简单 getter/setter
- ❌ 实现细节
- ❌ 私有方法
- ❌ 内部状态（不在公共契约中）
- ❌ 不要在代码中添加 `#ifdef TEST` 或仅用于测试的接口

---

### Golden Path + Edge Cases 矩阵

```cpp
// 1. Golden path (最重要)
TEST(OrderValidator, accepts_valid_order) { ... }

// 2. 每个类别边界
TEST(OrderValidator, rejects_empty_order_id)    { ... }
TEST(OrderValidator, rejects_whitespace_order_id) { ... }
TEST(OrderValidator, rejects_negative_amount)   { ... }
TEST(OrderValidator, rejects_zero_amount)       { ... }
TEST(OrderValidator, accepts_maximum_amount)    { ... }
```

---

## 为什么测试必须先写

**"之后写测试验证它工作"**
之后写的测试立即通过。立即通过什么都证明不了：
- 可能测试了错误的东西
- 可能测试实现而不是行为
- 可能遗漏边缘情况
- 从未见过它 catch 到 bug

**"已经手动测试了"**
手动测试是临时的：
- 没有记录测了什么
- 代码更改时无法重新运行
- 压力下容易忘情况

**"删除 X 小时工作太浪费"**
沉没成本谬误。保留无法信任的代码 = 技术债务。

**"之后测试达到同样目的"**
不。之后测试 = "这是做什么？" 测试优先 = "这应该做什么？"

---

## 常见错误

| 错误 | 修复 |
|------|------|
| 测试私有方法 | 通过公共接口测试 |
| 断言内部状态 | 只断言公共结果 |
| 一个测试测所有 | 一个概念一个测试 |
| 共享 setup 有 mutation | 用工厂函数 |
| 用真实 DB/文件做单元测试 | 用 link-time seam |
| 硬编码魔法数字 | 用命名常量 |
| toBeNull / not.toThrow | 写有意义的具体断言 |

---

## 反合理化

| 借口 | 现实 |
|------|------|
| "太简单不需要测试" | 简单代码也会坏。测试只需 30 秒。 |
| "之后加测试" | 之后测试立即通过，什么都证明不了。 |
| "已经手动测了" | 临时的 ≠ 系统的。无记录，不可重跑。 |
| "删除 X 小时太浪费" | 沉没成本。保留未验证代码 = 技术债务。 |
| "作为参考保留，先写测试" | 会适配已有代码。那是之后测试。删除就是删除。 |
| "需要先探索" | 可以。丢弃探索，从 TDD 开始。 |
| "测试难 = 设计差" | 听测试的。难测试 = 难使用。 |
| "TDD 让我变慢" | TDD 比调试快。务实 = 测试优先。 |

---

## 红旗 — 停止并重来

- 生产代码在测试之前 → 删除代码，从 RED 开始
- 测试在实现之后 → 删除，重新开始
- 测试立即通过（没有因功能缺失而失败）→ 修复测试
- 写了 `toBeNull()` / `not.toThrow()` / `toBeDefined()` 作为唯一断言
- "之后加测试" → 现在加
- "我已经手动测试了" → 手动 ≠ 自动
- "是精神而不是仪式" → 违反字面 = 违反精神

**所有这些意味着：删除代码。从 RED 重新开始。**
