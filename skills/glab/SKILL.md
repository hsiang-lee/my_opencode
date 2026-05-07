---
name: glab
description: GitLab CLI tool for interacting with GitLab repositories.
license: MIT
compatibility: opencode
---

# glab - GitLab CLI Tool

glab 是 GitLab 官方命令行工具，用于与 GitLab 仓库交互。

## 配置

```bash
# 设置跳过 TLS 验证 (内部 GitLab 实例)
glab config set -h addev.bicv.com skip_tls_verify true

# 设置 git 协议
glab config set -h addev.bicv.com git_protocol ssh

# 设置 API 协议
glab config set -h addev.bicv.com api_protocol https
```

## 认证

```bash
# 使用 token 认证
echo "YOUR_TOKEN" | glab auth login --hostname addev.bicv.com --stdin

# 查看认证状态
glab auth status
```

> **Token 要求**: 需要 `api` 和 `write_repository` 权限
> **生成 Token**: https://addev.bicv.com/-/profile/personal_access_tokens?scopes=api,write_repository

## 常用命令

### Merge Request

```bash
# 创建 MR
glab mr create \
  --title "feat: add new feature" \
  --description "## Summary
- Description of changes

## Test Plan
- How to test" \
  --target-branch main \
  --source-branch feature/my-feature \
  --yes

# 查看 MR 列表
glab mr list

# 查看 MR 详情
glab mr view <mr-number>

# 查看 MR 检查状态
glab mr checks <mr-number>

# 合并 MR
glab mr merge <mr-number>

# 关闭 MR
glab mr close <mr-number>
```

### Issue

```bash
# 创建 Issue
glab issue create \
  --title "Bug: something broken" \
  --description "## Description
Steps to reproduce..." \
  --label "bug"

# 查看 Issue 列表
glab issue list

# 关闭 Issue
glab issue close <issue-number>
```

### Pipeline

```bash
# 查看 Pipeline 列表
glab pipeline list

# 查看 Pipeline 详情
glab pipeline view <pipeline-id>

# 下载 Pipeline artifacts
glab pipeline ci artifacts <pipeline-id>
```

### Release

```bash
# 创建 Release
glab release create v1.0.0 \
  --name "Release v1.0.0" \
  --description "## Changes
- Feature A
- Bug fix B" \
  --assets-file CHANGELOG.md
```

## 环境变量

| 变量 | 说明 |
|------|------|
| `GITLAB_TOKEN` | 认证 token (优先于配置文件) |
| `CI_SERVER_URL` | GitLab 实例 URL |

## Troubleshooting

| 问题 | 解决 |
|------|------|
| `tls: failed to verify certificate` | `glab config set -h <host> skip_tls_verify true` |
| `not authenticated` | `echo "TOKEN" \| glab auth login --hostname <host> --stdin` |
| `none of the git remotes point to known GitLab host` | 先配置 host: `glab config set -h <host> api_protocol https` |

## 参考文档

- [glab 官方文档](https://glab.readthedocs.io/)
- [GitLab Personal Access Tokens](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html)
