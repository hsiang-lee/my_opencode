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
| 2 | 要改的代码无测试 / 难有可靠测试 | **Legacy** |
| 3 | 行为不变，只改结构或模式，基线全绿 | **Refactor** |
| 4 | 新增/变更行为，且目标可写测试 | **Feature** |
| 5 | 前端探索测试（只报告不修复） | **QA-Explorer** |

判据重叠时按上表顺序。场景不符即停，不「先做一点看看」。

## 档位判定（Feature / Refactor 入口）

**Feature**（行为变更）

| 档位 | 判据 | 效果 |
|------|------|------|
| 轻量档 | 文件 ≤2 且改动 ≤50 行 且不改公共接口 | 跳过设计、故事、评审，保留 TDD、审查、收尾 |
| 精简档 | 文件 3-8 且无新增模块 / 公共接口 / 数据模型 | 跳过 momus，其余照走 |
| 完整档 | 文件 >8，或新增模块 / 公共接口 / 数据结构 / 并发 / 权限 / 迁移 | 走满全流程 |

**Refactor**（行为保持）

| 档位 | 判据 | 效果 |
|------|------|------|
| 轻量档 | 单一坏味道且文件 ≤2 | 跳过 refactor-planner 与 momus，直接执行、审查、收尾 |
| 完整档 | 多处坏味道 / 跨模块 / 涉及模式引入 | planner → momus → 分批执行 → 审查 → 收尾 |

档位一旦确定不得中途升降；Fix / Legacy 不设档位（已是短流程）。

## Agent

| Agent | 用途 | 调用 |
|-------|------|------|
| Feature | 场景 4：行为变更 + 可写测试 | Tab |
| Fix | 场景 1：bug 修复 | Tab |
| Legacy | 场景 2：无测试代码改动 | Tab |
| Refactor | 场景 3：行为保持型重构 | Tab |
| QA-Explorer | 前端探索测试 | Tab |
| story-writer | 决策确认后产出 Epic + 故事清单 | `Task("story-writer", ...)` |
| story-executor | 有测试路径的逐故事 TDD | `Task("story-executor", ...)` |
| legacy-analyst | L0 侦察 + L1 改法建议（只读） | `Task("legacy-analyst", ...)` |
| legacy-executor | L1–L4 安全网与主循环 | `Task("legacy-executor", ...)` |
| refactor-planner | 坏味道诊断 + 分步重构计划 | `Task("refactor-planner", ...)` |
| refactor-executor | 行为保持型分批执行 + 台账 | `Task("refactor-executor", ...)` |
| code-reviewer | 实现完成后独立审查（按 profile） | `Task("code-reviewer", ...)` |
| branch-finisher | 分支收尾 | `Task("branch-finisher", ...)` |
| metis | 任务前厘清意图与风险 | `@metis` |
| momus | 计划/故事评审（故事、侦察报告、重构计划） | `@momus` |
| explore | 代码库搜索 | `@explore` |
| librarian | 外部库与文档 | `@librarian` |
| oracle | 复杂调试 / 高难度架构 | `@oracle` |

## Skill 加载

- `SKILL.md` 是索引 + 判定层：先读它，再按「要做什么 → 读哪个文件」表只打开当前任务需要的 1 个 reference。
- 同一 reference 本会话不重读；不确定读哪个就看索引，不猜、不通读。
- 阈值冲突以 SKILL.md 为准；加载声明只写在 agent 正文，dispatch 不重复指定。

## TDD

- 执行侧分三类：`story-executor`（有测试路径的 RED-GREEN-REFACTOR）、`legacy-executor`（L2 安全网 + L3 两顶帽子）、`refactor-executor`（行为保持型小步重构）；判定标准在各 agent 正文。
- 编排侧不写代码、不改测试。Feature 不跑测试；Fix / Legacy / Refactor 只允许跑只读验证命令（复现、基线、现有测试），不得修改测试或源码。dispatch 要求先给失败测试或安全网证据，核对 RED 证据，无证据不验收。
- 目标路径无测试时，`story-executor` 必须返回 `BLOCKED(需 legacy-executor)`，禁止自写特征测试。

## 红线

- 禁止直推 main / master，一律 PR/MR。
- 禁止 `git checkout` / `git restore` 丢弃改动。编译报错：看错误 → `git diff` 定位 → 手改；暂存用 `git stash`。
- 删改一行前先答：它做什么？没有它会怎样？删分配前先找到释放点。
- 修完 A 仍有问题 → 重查根因，不顺手改 B；每个 bug 单独验证。

## 反合理化

| 借口 | 现实 |
|------|------|
| "修改太小了不用测试" | 小修改也可能引入 bug。必须测。 |
| "就改一行不用审查" | 改一行也可能有问题。必须审。 |
| "我手动测过了没问题" | 手动测试不可重复。写自动化测试。 |
| "直接提 PR 吧" | 必须先过 code-reviewer。 |
| "改动太小，不用确认方案" | 小改也会改错文件。确认 10 秒，返工 30 分钟。 |
| "用户说了要做，等于同意了" | 说的是目标，不是方案。方案必须单独确认。 |
| "先做一点看看，超界再说" | 场景/档位错了，后面的门全对不上。先判再动。 |

## Build

增量编译优先，不轻易 `rm -rf build`（vcpkg 全量重编）。编译错误先修代码，不清缓存。

## 依赖（vcpkg）

`vcpkg.json` 声明 → `find_package(X CONFIG REQUIRED)` → `target_link_libraries(... X::X)`。
禁止硬编码 `-I/-L`、绝对路径、手链 `.a/.so`。

## 分支与提交

- 分支：`feature|fix|hotfix/issue-{id}-{description}`
- Commit 英文：`type(scope): summary`；正文只写「为什么」
- PR 正文 ≤5 行：What / Why / `Tested: <命令> — N passed`；禁止逐文件清单与长篇论证
