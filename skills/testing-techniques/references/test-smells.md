# 测试坏味道全集 + 测试重构手法

回到索引: [../SKILL.md](../SKILL.md)

## 一、行为类（可信度受损）

| 坏味道 | 症状 | 修正 |
|--------|------|------|
| **脆弱 Fragile** | 产品代码小改 → 大量测试红 | 断言公共行为，不断言内部结构与调用顺序 |
| **不可重复 Non-Deterministic** | 同代码多次跑结果不同 | 注入时钟/随机源，隔离共享状态、网络、文件 |
| **缓慢 Slow** | 单测 >100ms，套件数分钟 | 用替身隔离 IO，快慢分离 |
| **过度指定 Over-Specified** | 断言与本行为无关的细节 | 只断言关键结果 |
| **测试侵蚀 Test Erosion** | 测试逐渐变差但没人清理 | 童子军规则：改到哪清到哪 |

## 二、结构类（可维护性受损）

| 坏味道 | 症状 | 修正 |
|--------|------|------|
| **断言缺失 Missing Assertion** | 跑完不断言，或断言太弱 | 加明确断言（见 `../SKILL.md` 假测试清单） |
| **条件测试逻辑** | 测试体内有 if/for/try-catch 决定断言 | 拆成多个测试 |
| **测试代码重复** | 多个测试逐字复制 setup | 提取工厂/辅助方法 |
| **大型测试 Large Test** | 一个测试验证多件事 | 按行为拆分 |
| **神秘客人 Mystery Guest** | 依赖测试外的文件/DB/环境且未声明 | 内联数据或用 Fake |

## 三、组织类（隔离性受损）

| 坏味道 | 症状 | 修正 |
|--------|------|------|
| **共享夹具污染** | 测试间通过共享对象互相影响 | Fresh Fixture（见 `fixtures.md`） |
| **测试依赖链** | 必须按顺序执行 | 每个测试独立准备 |
| **测试类过大** | 一个测试类塞几十个测试 | 按功能拆分测试类 |

## 四、测试重构手法（测试代码也要重构）

| 手法 | 适用 |
|------|------|
| Extract Method | 测试中重复的 setup 或断言 |
| Extract Testcase Superclass | 多个测试类共享公共夹具 |
| Parameterize Test | 多个测试只有输入不同 |
| Replace Test Double with Real Object | mock 过度，测试失真 |
| Replace Real Object with Test Double | 测试太慢或依赖不稳定 |
| Move Test to Correct Class | 测试放在了错误的测试类 |
| Inline Test | 测试过简，独立方法反而增加噪音 |
| Introduce Custom Assertion | 断言重复且失败消息差 |

## 五、假测试的完整模式（判定 → Critical）

| 模式 | 示例 | 为什么无价值 |
|------|------|--------------|
| Null 检查 | `not.toBeNull()` / `ASSERT_NE(nullptr, p)` | 任何非空都过 |
| 无异常检查 | `EXPECT_NO_THROW(fn())` 作为唯一断言 | 只证明不崩溃 |
| 已定义检查 | `toBeDefined()` / `toBeTruthy()` | 任何非空都过 |
| Mock 调用 | `verify(mock).called()` 无其它断言 | 测替身而非逻辑 |
| 空测试 | `TEST(X, works) {}` | 什么都不过 |
| 永真断言 | `EXPECT_TRUE(true)` | 骗覆盖率 |
| 仅快乐路径 | 无边界/错误输入 | 一遇异常就崩 |
| 内部状态 | 断言私有字段 | 重构即碎 |

**每个测试必须含**：一个具体行为 + 有意义的断言（具体值）+ 真实输入 + 公共接口。

## 六、评审顺序（code-reviewer 用）

1. 有没有假测试 → 有即 Critical
2. 测试是否独立可乱序 → 否则 Major
3. 断言是否够强（具体值 vs 非空）→ 弱则 Major
4. 是否只测快乐路径 → 边界缺失记 Minor/Major
5. 命名是否表达场景与预期 → 否则 Minor
6. 是否 mock 过度 / 断言实现细节 → 否则 Major
