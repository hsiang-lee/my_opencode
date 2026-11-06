# 全局 Agent 规则（所有 OpenCode 项目）

## 输出风格

- 结论先行，只给必要依据；不重复已知信息，无客套与空泛总结
- 顺利 = 1 行；异常、风险、需决策才展开
- 面向用户 ≤40 行，超出写入报告文件，对话内留摘要 + 路径
- 用数字不用形容词（"62/62 通过"）；说人话（"卡住：缺 XXX"）

## 变更分级

| 条件 | 去向 |
|------|------|
| 文件 ≤2 且改动 ≤50 行 且不改公共接口 | Patch |
| 文件 3-8 且无新增模块 / 公共接口 / 数据模型 | Forge 精简档 |
| 文件 >8，或新增模块 / 公共接口 / 数据结构 / 并发 / 权限 / 迁移 | Forge 完整档 |
| 行为与预期不符（bug） | Trace |

超界即停，不「先做一点看看」。

## Agent

| Agent | 用途 | 调用 |
|-------|------|------|
| Patch | 小改工作流 | Tab |
| Forge | feature 工作流 | Tab |
| Trace | bug 修复工作流 | Tab |
| QA-Explorer | 前端探索测试 | Tab |
| story-writer | 决策确认后产出 Epic + 故事清单 | `Task("story-writer", ...)` |
| story-executor | 按批次执行 TDD 故事 | `Task("story-executor", ...)` |
| code-reviewer | 实现完成后独立审查 | `Task("code-reviewer", ...)` |
| branch-finisher | 分支收尾 | `Task("branch-finisher", ...)` |
| metis | 任务前厘清意图与风险 | `@metis` |
| momus | 故事评审（可执行性 / AC / 契约） | `@momus` |
| explore | 代码库搜索 | `@explore` |
| librarian | 外部库与文档 | `@librarian` |
| oracle | 复杂调试 / 高难度架构 | `@oracle` |

## Skill 加载

- `SKILL.md` 是索引 + 判定层：先读它，再按「要做什么 → 读哪个文件」表只打开当前任务需要的 1 个 reference。
- 同一 reference 本会话不重读；不确定读哪个就看索引，不猜、不通读。
- 阈值冲突以 SKILL.md 为准；加载声明只写在 agent 正文，dispatch 不重复指定。

## TDD

- 执行侧（story-executor / branch-finisher）：RED-GREEN-REFACTOR，先写失败测试；判定标准在 story-executor 正文。
- 编排侧（Forge / Patch / Trace）：不写代码、不跑测试；dispatch 要求先给失败测试，核对 RED 证据，无证据不验收。

## 红线

- 禁止直推 main / master，一律 PR/MR。
- 禁止 `git checkout` / `git restore` 丢弃改动。编译报错：看错误 → `git diff` 定位 → 手改；暂存用 `git stash`。
- 删改一行前先答：它做什么？没有它会怎样？删分配前先找到释放点。
- 修完 A 仍有问题 → 重查根因，不顺手改 B；每个 bug 单独验证。

## Build

增量编译优先，不轻易 `rm -rf build`（vcpkg 全量重编）。编译错误先修代码，不清缓存。

## 依赖（vcpkg）

`vcpkg.json` 声明 → `find_package(X CONFIG REQUIRED)` → `target_link_libraries(... X::X)`。
禁止硬编码 `-I/-L`、绝对路径、手链 `.a/.so`。

## 分支与提交

- 分支：`feature|fix|hotfix/issue-{id}-{description}`
- Commit 英文：`type(scope): summary`；正文只写「为什么」
- PR 正文 ≤5 行：What / Why / `Tested: <命令> — N passed`；禁止逐文件清单与长篇论证
