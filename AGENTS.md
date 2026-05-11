# 全局 Agent 规则

**应用范围：所有通过 OpenCode 管理的项目**

---

## Agent 使用指南

| Agent | 功能 | 使用时机 | 调用方式 |
|-------|------|----------|----------|
| **explore** | 代码库搜索专家 | 查找"X在哪里实现"、"哪个文件包含Y"、"找到做Z的代码"时 | `@explore` 或 `Task("explore", "Find code that does X")` |
| **librarian** | 外部代码理解专家 | 搜索远程代码库、查找开源库用法、获取官方文档时 | `@librarian` 或 `Task("librarian", "How to use X library")` |
| **metis** | 预规划顾问 | 开始任务前需要分析意图、识别风险、厘清需求时 | `@metis` 或 `Task("metis", "Analyze this request")` |
| **momus** | 计划评审专家 | 计划写完后需要检查可执行性、引用有效性时 | `@momus` 或 `Task("momus", "Review plan at path")` |
| **oracle** | 战略技术顾问 | 遇到复杂调试问题、高难度架构设计需要深度推理时 | `@oracle` 或 `Task("oracle", "Debug why X is failing")` |

### 快速参考

- **探索代码库** → `@explore`
- **查开源库用法/文档** → `@librarian`
- **任务开始前厘清需求** → `@metis`
- **计划评审** → `@momus`
- **复杂问题深度分析** → `@oracle`

---

## TDD 工作模式

**重要提醒：所有代码实现必须遵循 TDD (Test-Driven Development) 工作模式。**

### 核心原则

1. **写代码前先添加测试** - 先写测试，再写实现
2. **小步前进，频繁测试** - 步骤要小，每一步都确保测试通过
3. **红绿循环**:
   - Red: 写一个会失败的测试
   - Green: 写最少的代码让测试通过
   - Refactor: 重构代码，保持测试通过

### 操作规范

- 实现任何功能前，先写测试
- 每个小步骤后运行测试确认通过
- 不要一次性实现大量代码
- 测试应该原子化，一个测试只验证一个行为

### 示例流程

```bash
# 1. 写测试 (RED)
# 2. 运行测试确认失败
# 3. 写最小实现 (GREEN)
# 4. 运行测试确认通过
# 5. 重构 (REFACTOR)
# 6. 提交
```

---

## Anti-Patterns (STRICTLY PROHIBITED)

- **严禁直接向 main 或 master 主分支推送代码** — 必须通过 PR/MR 合并
  - Never push directly to protected main/master branches
  - Always use PR/MR workflow for changes

---

## ⚠️ CRITICAL WARNINGS

### 严禁使用 `git checkout` 恢复代码

**绝对禁止使用 `git checkout` 或类似命令恢复代码！**

- `git checkout` 会直接撤销所有未提交的修改，导致大量工作成果丢失
- 如果编译出错需要修复，应该：
  1. 仔细分析错误信息
  2. 使用 `git diff` 查看具体改动
  3. 使用 `git stash` 暂存改动（如果需要）
  4. 手动编辑修复问题，而不是恢复整个文件
- 正确的做法是：逐步定位问题，然后针对性地修复有问题的代码

---

## Build Directory Management

**编译时不要轻易删除 build 目录！**

- 能增量编译就增量编译，不要 `rm -rf build` 再重新配置
- 删除 build 会导致：
  - vcpkg 依赖全部重新编译安装（耗时数分钟）
  - CMake 缓存丢失
  - 已编译的目标文件全部丢失
- 只有遇到以下情况才删除 build：
  - CMake 配置错误且无法通过增量修复
  - 依赖库的链接器路径发生变化
  - 需要完全干净的重配置
- 如果只是编译错误，优先检查并修复代码，而不是清理缓存

---

## 依赖管理规则

**优先使用 vcpkg 管理所有第三方依赖！**

- **必须使用 `find_package()` 机制** 导入 vcpkg 管理的库
- **严禁手动指定路径**（如 `-I/path/to/include` 或 `-L/path/to/lib`）
- 正确做法：
  1. 确保库在 `vcpkg.json` 中声明
  2. 使用 `find_package(XYZ CONFIG REQUIRED)` 导入
  3. 使用 `target_link_libraries(... XYZ::XYZ)` 连接目标
- 错误做法（**极其糟糕，禁止使用**）：
  - 手动 `target_include_directories(..., "/custom/path/...")`
  - 手动 `target_link_libraries(..., "/path/to/libxxx.a")`
  - 通过设置环境变量或硬编码路径绕过 vcpkg
- vcpkg 提供 CMake 目标（如 `pugixml::pugixml`、`osg::osgDB`）时必须使用这些目标

---

## Branch Naming Conventions

- Feature branches: `feature/issue-{id}-{description}`
- Bug fixes: `fix/issue-{id}-{description}`
- Hotfixes: `hotfix/issue-{id}-{description}`

---

## Critical Lessons Learned

### Lesson 1: 不要猜测，要追踪

**错误做法**: "我觉得这个调用不需要了"，然后删掉

**正确做法**:
- 找到分配代码
- 找到释放代码
- 确认路径是否匹配
- 不匹配就不能删

---

### Lesson 2: 每个bug单独验证

**错误做法**: 修了A之后还有问题，就觉得是B引起的，把B也改了

**正确做法**:
- 验证A确实修好了
- 如果还有问题，重新分析，不是直接改别的代码

---

### Lesson 3: 删代码前先问自己

1. 这行代码的作用是什么？
2. 没有它会发生什么？
3. 如果我不确定 → 不要删，查清楚再说

---

### Lesson 4: Commit message 要写清楚为什么

**错误**: "Remove XXX call"

**正确**: "Remove XXX call because XXX returns internal buffer, not allocated memory"