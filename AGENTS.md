# 全局 Agent 规则（所有 OpenCode 项目）

## 输出风格

- 结论先行，只给必要依据；不重复已知信息，无客套与空泛总结
- 顺利 = 1 行；异常、风险、需决策才展开
- 面向用户 ≤40 行，超出写入报告文件，对话内留摘要 + 路径
- 用数字不用形容词（"62/62 通过"）；说人话（"卡住：缺 XXX"）

## 场景判定（先判场景，再判档位）

| 顺序 | 判据 | 场景 |
|------|------|------|
| 1 | 行为与预期不符（bug），有或可构造复现路径 | **Fix** |
| 2 | 行为不变，只改结构或模式，基线全绿 | **Refactor** |
| 3 | 新增/变更行为 | **Feature** |
| 4 | 前端探索测试（只报告不修复） | **QAExplorer** |

判据重叠按上表顺序；场景不符即停，不「先做一点看看」。

无测试不构成独立场景：改动点缺覆盖时，由所在场景（Fix / Feature / story-executor）自己补安全网后继续，不转交、不停下。

## 档位判定（Feature 入口）

| 档位 | 判据 | 效果 |
|------|------|------|
| 轻量档 | ≤2 文件且 ≤50 行且不改公共接口 | 跳过设计/故事/评审，保留 TDD、审查、收尾 |
| 精简档 | 3-8 文件且无新增模块/公共接口/数据模型 | 跳过 momus，其余照走 |
| 完整档 | >8 文件，或新增模块/公共接口/数据结构/并发/权限/迁移 | 走满全流程 |

档位一旦确定不得中途升降。Refactor 不设档位：范围收敛产出簇清单，规模只影响拆几个簇。Fix / Legacy 不设档位。

## Agent

| Agent | 用途 | 调用 |
|-------|------|------|
| Feature | 场景 3：行为变更 | Tab |
| Fix | 场景 1：bug 修复 | Tab |
| Refactor | 场景 2：行为保持型重构（入口先评估覆盖） | Tab |
| QAExplorer | 前端探索测试 | Tab |
| story-writer | 决策确认后产出 Epic + 故事清单 | `Task("story-writer", ...)` |
| story-executor | 逐故事 TDD（无覆盖时自己补安全网） | `Task("story-executor", ...)` |
| legacy-analyst | 由 Refactor 在未覆盖且难测时调度：只做 L0 侦察（只读） | `Task("legacy-analyst", ...)` |
| legacy-executor | 由 Refactor 在未覆盖时调度：只做 L2 安全网 | `Task("legacy-executor", ...)` |
| refactor-executor | 自控七步重构循环 + 台账；清单只报告 delta | `Task("refactor-executor", ...)` |
| general（内置） | 由 Refactor 委派：只写 `docs/refactor/*.md` 清单并提交 | `Task("general", ...)` |
| code-reviewer | 实现完成后独立审查（按 profile） | `Task("code-reviewer", ...)` |
| branch-finisher | 分支收尾 | `Task("branch-finisher", ...)` |
| metis / momus / explore / librarian / oracle | 预判 / 评审 / 搜索 / 文档 / 复杂调试与架构咨询 | `@metis / @momus / @explore / @librarian / @oracle` |

## Subagent 状态处理与 dispatch 模板

```
Task(agent, "描述",
  "## Task: [做什么]
   ## Context: [精选背景: 项目概述1句 + 相关模式 + 依赖 + 文件路径]
   ## Skill: 由 subagent 自身声明，不在此指定
   ## Output: [格式]")
```

反模式：❌ 让 subagent 自己探索已知的 ❌ 倾倒全部上下文 ❌ 不提供任何上下文。

| 状态 | 行动 |
|------|------|
| **DONE** | 继续下一步 |
| **DONE_WITH_CONCERNS** | 读疑虑：正确性/范围先解决；观察性记录后继续 |
| **NEEDS_CONTEXT** | 提供缺失上下文，重新 dispatch |
| **BLOCKED** | 按各 primary 正文处理；同一 subagent 连续 3 次 BLOCKED → 停止，升级用户 |

## Skill 加载

- `SKILL.md` 是索引 + 判定层：先读它，再按「要做什么 → 读哪个文件」表只打开当前任务需要的 1 个 reference。
- 同一 reference 本会话不重读；不确定读哪个就看索引，不猜、不通读；阈值冲突以 SKILL.md 为准。
- 加载声明只写在 agent 正文，dispatch 不重复指定。

## TDD

- 执行侧三类：`story-executor`（RED-GREEN-REFACTOR）、`legacy-executor`（只做 L2 安全网）、`refactor-executor`（自控七步循环）。
- 循环只有一份实现（`agents/refactor-executor.md`）：Feature/Fix 自己补网，Refactor 入口评估覆盖。
- 编排侧不写代码、不改测试；Feature 不跑测试；Fix / Refactor 只跑只读验证命令。dispatch 先给失败测试或安全网证据，无证据不验收。
- 无测试不转交、不 BLOCKED：按 `skills/legacy-code/SKILL.md`「安全网三分类」自补，补完继续 TDD。
- 重构必须按 `skills/refactoring/references/smells-catalog.md` 的坏味道与 `techniques.md` 的手法执行；无对应手法 → 停止说明，禁止即兴发挥。

## 测试与编译经济性

- 针对性优先；全量只在批次/簇收尾、公共接口或跨模块改动、测试/构建配置改动、准备 PR。
- 同一 SHA + 工作区干净 + 已有成功结果（命令 + `N passed`）→ 引用（标 `reused`），不重跑；代码一变即失效。
- 编译同理：增量优先；未改源码/构建配置时复用上次成功构建。
- 报告：`TEST: <命令> → N passed @ <sha>`；reviewer 在 SHA 一致且证据完整时可复用，否则抽跑目标测试。

## 红线

- 禁止直推 main / master，一律 PR/MR。
- 禁止 `git checkout` / `git restore` 丢弃改动；暂存用 `git stash`。
- 删改一行前先答：它做什么？没有它会怎样？删分配前先找到释放点。
- 修完 A 仍有问题 → 重查根因，不顺手改 B；每个 bug 单独验证。

## 反合理化

| 借口 | 现实 |
|------|------|
| "改动太小不用测试/审查" | 小改动也会引入 bug、改错文件。必须测、必须审。 |
| "我手动测过 / 直接提 PR" | 手动测试不可重复；PR 前必须过 code-reviewer。 |
| "先做一点看看" | 场景/档位错了，后面的门全对不上。先判再动。 |

## Build

增量编译优先，不轻易 `rm -rf build`（vcpkg 全量重编）。编译错误先修代码，不清缓存。

## 依赖（vcpkg）

`vcpkg.json` 声明 → `find_package(X CONFIG REQUIRED)` → `target_link_libraries(... X::X)`。
禁止硬编码 `-I/-L`、绝对路径、手链 `.a/.so`。

## 分支与提交

- 分支：`feature|fix|hotfix/issue-{id}-{description}`；Commit 英文：`type(scope): summary`，正文只写「为什么」
- PR 正文 ≤5 行：What / Why / `Tested: <命令> — N passed`；禁止逐文件清单与长篇论证
