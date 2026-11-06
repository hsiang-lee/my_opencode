# 测试结构 — AAA / 命名 / 测什么 / 参数化

回到索引: [../SKILL.md](../SKILL.md)

**目录**：1 AAA · 2 命名 · 3 该测什么 · 4 边界矩阵 · 5 参数化 · 6 断言进阶 · 7 一件事的边界

## 1. AAA 结构

```
Arrange  —— 准备输入与依赖（夹具、替身）
Act      —— 只调用一次被测行为
Assert   —— 只断言结果
```

- 一个测试一个 Act。出现两次 Act → 拆成两个测试。
- Assert 部分只放与「本测试意图」相关的断言；无关断言 → 另一个测试。
- Arrange 超过 10 行 → 提取工厂函数或 Builder（见 `fixtures.md`）。

## 2. 命名

三种主流风格，选一种全项目统一：

| 风格 | 示例 |
|------|------|
| `Method_Scenario_Expected` | `withdraw_insufficientBalance_throws` |
| `should_<预期>_when_<场景>` | `shouldThrow_whenBalanceInsufficient` |
| `behavior_under_condition` | `rejects_empty_email` |

**判定标准**：名字能否让陌生人在不读测试体的前提下知道「什么被破坏了」。名字含 `test1`、`works`、`ok`、`and`（两件事）→ 不合格。

## 3. 该测什么 / 不该测什么

**必须测**

| 类别 | 例 |
|------|-----|
| 公共接口行为 | 正常路径的输入 → 输出 |
| 边界 | 空、零、负、最大、超长、单项、刚好越界 |
| 错误路径 | 非法输入、异常、超时、依赖失败 |
| 状态迁移 | 操作序列后的不变式 |
| 契约 | 前置拒绝、后置成立（见 design/contracts） |

**不该测**

- 第三方库自身的行为
- 简单 getter/setter（除非含校验/计算）
- 私有方法与内部状态（通过公共入口间接测）
- 实现细节（调用顺序、内部数据结构）
- 为测试在生产代码里加 `#ifdef TEST` 或测试专用接口

## 4. Golden Path + 边界矩阵

```
1 条 golden path（最重要，先写）
每个校验分支：1 个拒绝样例 + 1 个接受样例
每个数值参数：0 / 负数 / 上界 / 上界+1
每个集合参数：空 / 单元素 / 多元素
每个字符串：空 / 空白 / 超长 / 特殊字符
```

示例：

```
accepts_valid_order
rejects_empty_order_id
rejects_whitespace_order_id
rejects_negative_amount
rejects_zero_amount
accepts_maximum_amount
```

## 5. 参数化测试（Test Enumeration）

同一行为、只有输入不同 → 一张表驱动，不要复制 N 个测试体。

```cpp
struct Case { int input; int expected; };
TEST(RetryPolicy, computes_delay_by_attempt) {
  Case cases[] = {{1, 100}, {2, 200}, {3, 400}};
  for (auto c : cases) EXPECT_EQ(delay(c.input), c.expected);
}
```

**红线**：表里出现 if/else 分支 → 不是参数化，是条件测试逻辑，拆开。

## 6. 断言进阶

| 手法 | 用途 | 注意 |
|------|------|------|
| **Custom Assertion** | 复杂断言封装成语义化函数，失败消息可读 | 封装后仍要在失败时给出上下文 |
| **Delta Assertion** | 断言变化量而非绝对值（余额 +50） | 避免受初始状态影响 |
| **State Verification** | 断言操作后的状态 | 默认首选 |
| **Behavior Verification** | 断言对依赖的调用（Mock/Spy） | 仅用于「对外交互」本身就是需求时 |

**顺序**：先 State，只有「必须发出某个外部请求」才是 Behavior。

## 7. 一个测试验证一件事的边界

「一件事」= 一个行为契约。以下不算违反：

- 一个行为的多条断言（返回码 + 返回体 + 副作用）
- 同一不变式的多处检查

以下算违反：

- 两个不同输入场景挤在一起
- 正常路径 + 错误路径挤在一起
- 测试体里有 if/for/try-catch 决定断言
