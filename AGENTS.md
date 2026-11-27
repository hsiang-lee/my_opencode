# 全局 Agent 规则（所有 OpenCode 项目）

## 输出风格

- 面向人类的汇报/请示：按 `reporting` skill 组织（结论先行、决策前置、不填空模板）。
- 子 agent 报告保持结构化；编排者转述时必须重写，不得转发原文。

## 场景判定（先判场景，再判档位）

| 顺序 | 判据                                      | 场景           |
| ---- | ----------------------------------------- | -------------- |
| 1    | 行为与预期不符（bug），有或可构造复现路径 | **Fix**        |
| 2    | 新增/变更行为                             | **Feature**    |
| 3    | 前端探索测试（只报告不修复）              | **QAExplorer** |

判据重叠按上表顺序；场景不符即停，不「先做一点看看」。

无测试不构成独立场景：改动点缺覆盖时，由所在场景（Fix / Feature / story-executor）自己补安全网后继续，不转交、不停下。

## 档位判定（Feature 入口）

| 档位   | 判据                                                 | 效果                                     |
| ------ | ---------------------------------------------------- | ---------------------------------------- |
| 轻量档 | ≤2 文件且 ≤50 行且不改公共接口                       | 跳过设计/故事/评审，保留 TDD、审查、收尾 |
| 精简档 | 3-8 文件且无新增模块/公共接口/数据模型               | 跳过 momus，其余照走                     |
| 完整档 | >8 文件，或新增模块/公共接口/数据结构/并发/权限/迁移 | 走满全流程                               |

档位一旦确定不得中途升降。Fix / QAExplorer 不设档位。

## Agent

| Agent                                        | 用途                                                   | 调用                                                |
| -------------------------------------------- | ------------------------------------------------------ | --------------------------------------------------- |
| Feature                                      | 场景 2：行为变更                                       | Tab                                                 |
| Fix                                          | 场景 1：bug 修复                                       | Tab                                                 |
| QAExplorer                                   | 前端探索测试                                           | Tab                                                 |
| story-writer                                 | 决策确认后产出 Epic + 故事清单                         | `Task("story-writer", ...)`                         |
| story-executor                               | 逐故事 TDD + 批末三 scout 扫描 → refactor（无覆盖时自己补安全网） | `Task("story-executor", ...)`                       |
| refactor                                     | 按 scout 清单逐项重构：查手法 / 先补测试 / 检查点验证   | `Task("refactor", ...)`（executor 自动派发）        |
| smell-scout / pattern-scout / test-smell-scout | 坏味道扫描（Fowler 24 / 模式 12 / 测试 13），只报告不改 | `@smell-scout` 等（executor 自动派发）              |
| code-reviewer                                | 实现完成后独立审查（profile=feature，不含坏味道）      | `Task("code-reviewer", ...)`                        |
| branch-finisher                              | 分支收尾                                               | `Task("branch-finisher", ...)`                      |
| metis / momus / explore / librarian / oracle | 预判 / 评审 / 搜索 / 文档 / 复杂调试与架构咨询         | `@metis / @momus / @explore / @librarian / @oracle` |

## Subagent 状态处理与 dispatch 模板

```
Task(agent, "描述",
  "## Task: [做什么]
   ## Context: [精选背景: 项目概述1句 + 相关模式 + 依赖 + 文件路径]
   ## Skill: 由 subagent 自身声明，不在此指定
   ## Output: [格式]")
```

反模式：❌ 让 subagent 自己探索已知的 ❌ 倾倒全部上下文 ❌ 不提供任何上下文。

| 状态                   | 行动                                                                    |
| ---------------------- | ----------------------------------------------------------------------- |
| **DONE**               | 继续下一步                                                              |
| **DONE_WITH_CONCERNS** | 读疑虑：正确性/范围先解决；观察性记录后继续                             |
| **NEEDS_CONTEXT**      | 提供缺失上下文，重新 dispatch                                           |
| **BLOCKED**            | 按各 primary 正文处理；同一 subagent 连续 3 次 BLOCKED → 停止，升级用户 |

## Skill 加载

- 多文件 skill：`SKILL.md` 是索引 + 判定层，先读它，再按「要做什么 → 读哪个文件」表只打开当前任务需要的 1 个 reference；单文件 skill（`refactoring` / `legacy-code` / `testing-techniques`）一次读完，没有 reference。
- 同一 reference 本会话不重读；不确定读哪个就看索引，不猜、不通读；阈值冲突以 SKILL.md 为准。
- 加载声明只写在 agent 正文，dispatch 不重复指定。

## TDD

- 执行侧：`story-executor`（每故事 RED→GREEN；故事内不改结构，重构只在批末由 `refactor` 执行）。
- 批末扫描：每批次 commit 前，executor 并行派 `smell-scout` / `pattern-scout` / `test-smell-scout`，汇总去重后交 `refactor` 逐项重构（`commit: none`，成果并入批次单 commit）；报告必须含 `SMELL_SCAN`。
- 编排侧不写代码、不改测试；Feature 不跑测试；Fix 只跑只读验证命令。dispatch 先给失败测试或安全网证据，无证据不验收。
- 无测试不转交、不 BLOCKED：按 `skills/legacy-code/SKILL.md`「安全网三分类」自补，补完继续 TDD。
- 重构必须一次只处理一种坏味道、不改行为、测试保持绿；坏味道判定以 `smell-scout` / `pattern-scout` / `test-smell-scout` 的清单为准，手法查 `skills/refactoring/SKILL.md`；找不到对应手法 → 停止说明，禁止即兴发挥。

## 测试与编译经济性

- 针对性优先；全量只在批次/簇收尾、公共接口或跨模块改动、测试/构建配置改动、准备 PR。
- 同一 SHA + 工作区干净 + 已有成功结果（命令 + `N passed`）→ 引用（标 `reused`），不重跑；代码一变即失效。
- 编译同理：增量优先；未改源码/构建配置时复用上次成功构建。
- 报告：`TEST: <命令> → N passed @ <sha>`；reviewer 在 SHA 一致且证据完整时可复用，否则抽跑目标测试。

## 注释

- **代码必须自解释。只有代码本身无法表达、且这条隐含信息必须留下时，才允许写注释；否则坚决不写。**
- 唯一允许的内容：为什么这样做——外部约束、协议要求、踩过的坑、非显然的取舍。
- 禁止：复述代码、解释参数和类型、描述显而易见的控制流、给函数写功能说明。
- 顺序固定：先靠命名和结构让代码自解释；仍然表达不了，才写注释。
- 违反上面的禁止项 = 缺陷，删掉。

## 红线

- 禁止直推 main / master，一律 PR/MR。
- 禁止 `git checkout` / `git restore` 丢弃改动；暂存用 `git stash`。
- 删改一行前先答：它做什么？没有它会怎样？删分配前先找到释放点。
- 修完 A 仍有问题 → 重查根因，不顺手改 B；每个 bug 单独验证。

## 反合理化

| 借口                     | 现实                                           |
| ------------------------ | ---------------------------------------------- |
| "改动太小不用测试/审查"  | 小改动也会引入 bug、改错文件。必须测、必须审。 |
| "我手动测过 / 直接提 PR" | 手动测试不可重复；PR 前必须过 code-reviewer。  |
| "先做一点看看"           | 场景/档位错了，后面的门全对不上。先判再动。    |

## Build

增量编译优先，不轻易 `rm -rf build`（vcpkg 全量重编）。编译错误先修代码，不清缓存。

## 依赖（vcpkg）

`vcpkg.json` 声明 → `find_package(X CONFIG REQUIRED)` → `target_link_libraries(... X::X)`。
禁止硬编码 `-I/-L`、绝对路径、手链 `.a/.so`。

## 分支与提交

- 分支：`feature|fix|hotfix/issue-{id}-{description}`；Commit 英文：`type(scope): summary`，正文只写「为什么」
- PR 只在收尾步骤（`branch-finisher`）创建：Step 1–5 只本地 commit，**不 push、不开 PR**；推送与 PR 由收尾独占一次
- 一个分支一个 PR：先 `gh pr list --head <branch>` 查重；已存在就复用，追加提交前先问用户
- PR 正文 ≤5 行：What / Why / `Tested: <命令> — N passed`；禁止逐文件清单与长篇论证

## ripgrep

- 系统安装了ripgrep，rg命令可以使用
