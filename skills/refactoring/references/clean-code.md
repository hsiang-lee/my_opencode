# Clean Code 微规则（评审判据）

回到索引: [../SKILL.md](../SKILL.md)

## Clean Code 微规则（评审用）

| 维度 | 规则 | 反例 → 正例 |
|------|------|-------------|
| 命名 | 揭示意图，可读可搜 | `d` → `elapsedTimeInDays`；`genymdhms` → `generationTimestamp` |
| 命名 | 类的名词、方法用动词，避免 Manager/Data/Info/doStuff | `handle()` → `applyDiscount()` |
| 函数 | 3-10 行，只做一件事，同一抽象层级 | 业务判断与正则解析混在一起 |
| 函数 | 参数 0-2 个最优，≥3 个建议封装为对象，达到阈值即违规（见 SKILL.md） | `(x, y, w, h, color, label)` → `Rect` |
| 函数 | 无副作用，名字不说谎 | `getX()` 里修改全局状态 |
| 函数 | 指令与查询分离（CQS） | 既 return 旧值又改状态 |
| 嵌套 | ≤2 层，超出用卫语句 | 三层 `if` 包住整段逻辑 |
| 错误 | 异常优先，不返回 null，不吞异常 | `catch (e) {}` |
| 注释 | 解释「为什么」，不解释「做什么」 | `// 循环数组` |
| 格式 | 相关代码靠近，无关代码留空行分隔 | 变量声明与使用相隔 100 行 |

**这 10 条是 code-reviewer Phase 3 的判定依据——不写「关注点清晰？」这类空泛项。**

---
