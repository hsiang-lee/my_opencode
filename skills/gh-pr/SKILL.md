---
name: gh-pr
description: Use when creating GitHub pull requests via command line, checking PR status, adding reviewers, or updating PR metadata.
---

# GitHub Pull Request — gh 命令

## When to Use

- 需要创建 PR 并指定目标分支、标题、描述
- 需要查看 PR 状态、审查进度
- 需要添加/移除 reviewers 或 assignees
- 需要给 PR 添加 label、milestone
- 需要合并或关闭 PR

## Quick Reference

| 操作 | 命令 |
|------|------|
| 创建 PR | `gh pr create --base main --head feature` |
| 查看列表 | `gh pr list --state open` |
| 查看详情 | `gh pr view 123` |
| 添加 reviewer | `gh pr edit 123 --add-reviewer username` |
| 设置 label | `gh pr edit 123 --label bug,priority` |
| 合并 PR | `gh pr merge 123 --squash --delete-branch` |
| 关闭 PR | `gh pr close 123` |

## Core Pattern

### 创建 PR 完整流程

```bash
# 1. 查看当前分支状态
git status

# 2. 确认远程仓库
git remote -v

# 3. 创建 PR（自动关联当前分支）
gh pr create \
  --title "feat: add user authentication" \
  --body "## Summary
- Add JWT-based authentication
- Add login/logout endpoints" \
  --base main \
  --reviewer alice,bob \
  --label enhancement

# 4. 检查创建结果
gh pr view --web
```

### PR 描述模板

```
## Summary
[1-3 bullet points]

## Changes
- [具体改动]

## Testing
[测试方式]

## Screenshots (if UI)
```

## 常见错误

| 错误 | 原因 | 解决 |
|------|------|------|
| `GraphQL` 错误 | 未登录或 token 过期 | `gh auth login` |
| `--base` 分支不存在 | 拼写错误 | `gh repo view --branch` 确认 |
| Reviewer 不存在 | 用户名错误 | `gh api users/username` 验证 |
| PR 已存在 | 重复创建 | `gh pr list` 查看已有 |

## 交互式创建

```bash
# 完全交互式（省略参数）
gh pr create

# 半交互式（指定标题，跳过 body）
gh pr create --title "My PR" --fill
```

## Link 设置

```bash
# 在 PR 描述中引用 issue
Closes #123
Fixes #456

# 引用其他 PR
Closes #123
See also #789
```
