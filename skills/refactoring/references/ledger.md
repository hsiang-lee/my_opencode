# 重构台账模板

回到索引: [../SKILL.md](../SKILL.md)

## SCOPE_INVENTORY（Refactor 任务级清单）

存放：`docs/refactor/YYYY-MM-DD-<scope>.md`。清单是快照，不是执行计划；Refactor 每轮回来更新 SCOPE_INVENTORY（关闭 / 新增 / 拆分）。

| ID | 簇 / 文件:line | 候选坏味道（入口快扫） | 规模 | 风险 | 安全网 | 状态 | 基线 | Commit |
|----|----------------|------------------------|------|------|--------|------|------|--------|
| C1 | `path:40-120` | 过长函数? | 80 行 | 高 | covered | done | `<cmd>` → 42 passed | `abc1234` |

- **候选坏味道**：带 `?`；信息不足写 `unknown`，不猜；候选不排执行顺序、不限制扫描范围。
- **安全网**：`unknown` / `covered` / `direct-tests` / `legacy-L2`（记方式；`ready` 只出现在状态列）。
- **基线**：安全网就位后的全量命令与 `N passed`（已覆盖簇即入口结果），作为重构回滚锚点。
- **状态**：`pending` / `safety-net` / `ready` / `done` / `blocked`。进行中不设独立状态：`ready` 簇有未提交改动即视为 in-progress；`blocked` 修复后回 `pending` / `ready`，跳过须用户确认。
- **1 簇 = 1 个重构 commit**（`cluster: Cx`）；安全网另计 1 个 commit（`cluster: Cx safety-net`）。清单与重构 commit 同批更新。
- **COMMIT**：在下一个清单变更 commit 回填（自引用 SHA 不可写）；最后一簇由收尾 commit 回填。
- **落盘责任**：清单由 refactor-executor（`inventory-init` / `cluster`）与 legacy-executor（安全网行）写入；Refactor 只读。

每簇块：

```text
### C1 <簇名>
BASELINE: <全量命令> → N passed
SAFETY_NET: covered | direct-tests | legacy-L2（证据 file:line）
ROUNDS: 轮次 + 坏味道 + 手法 + 验证
CONFIRMED: <命中坏味道 + 位置>
NEW: <清单外新发现 + 位置>
SPLIT: <拆分去向 C1 → C1a, C1b | —>
CLOSED: <已消除>
COMMIT: <sha>
```

---

## 重构台账 (REFACTOR_LEDGER)

REFACTOR 阶段必须**逐类核对并输出台账**。台账是报告的一部分，不是可选附件；谎报台账（声称未命中但 diff 中明显命中）= 假测试级违规。

阈值唯一来源是 [SKILL.md 判定阈值表](../SKILL.md)；本模板只定义条目与格式，不另立数值。

```
REFACTOR_LEDGER:
- A1 共享常量重复: [命中→已提取至 X（证据）| 未命中: 理由一句]
- A2 绕过现有封装: [...]
- A3 测试setup复制: [...]
- A4 命名漂移: [...]
- A5 贫血模型/职责错位: [...]
- A6 伪多态: [...]
- A7 out-param 束: [...]
- 过长函数: [...]
- 深嵌套: [...]
- 批级质量遍(本批整体 diff, 含跨任务累积): [逐类人工核对命中与处置 | 未命中: 理由]
- 其他经典类(分类表中未被 A1-A7/过长/深嵌套覆盖的条目): [命中(指明编号+位置)| 未命中]
```

每一项要么给出命中后的处置与证据，要么给出一句未命中理由——不允许留空或省略。

---
