---
name: issue-master
description: Analyze requirements, split into vertical-sliced issues, create them on GitHub or GitLab.
license: MIT
compatibility: opencode
requires:
  - gh (for GitHub)
  - glab (for GitLab)
---

# Issue Master

Split requirements into vertical-sliced issues, auto-detect repo type, create on GitHub or GitLab.

## Vertical Slicing Rules

1. **User value per issue** - Each ships independently
2. **Small** - Target ½-1 day
3. **Independent** - No circular dependencies
4. **Testable** - Clear acceptance criteria

## Issue Template

```markdown
## Issue #{n}: {Short Title}
**Priority:** P0/P1/P2 | **Effort:** ½-2 days | **Depends on:** #{issues}

**User Story:**  
As a {user}, I want {goal}, so that {benefit}.

**Acceptance Criteria:**
- [ ] {Criterion 1}
- [ ] {Criterion 2}

**Description:**
{What to build}
```

## Workflow

### 1. Analyze Requirements

Understand: scope, users, success. Ask clarifying questions if vague.

### 2. Split Vertically

Foundation → Features → Polish. Each issue must ship alone.

### 3. Detect Repo Type

```bash
# Check if GitHub or GitLab
git remote -v | head -1
# github.com → use gh
# gitlab.com or other → use glab
```

### 4. Create Issues

⚠️ **NEWLINE FIX:** Always use `--body "$(cat <<'EOF'...)"` (single quotes around EOF).

**GitHub:**
```bash
gh issue create \
  --title "Issue #{n}: {Title}" \
  --body "$(cat <<'EOF'
**Priority:** P0 | **Effort:** 1 day | **Depends on:** None

**User Story:**  
As a {user}, I want {goal}, so that {benefit}.

**Acceptance Criteria:**
- [ ] {Criterion 1}
- [ ] {Criterion 2}

**Description:**
{Description}
EOF
)"
```

**GitLab:**
```bash
glab issue create \
  --title "Issue #{n}: {Title}" \
  --description "$(cat <<'EOF'
**Priority:** P0 | **Effort:** 1 day | **Depends on:** None

**User Story:**  
As a {user}, I want {goal}, so that {benefit}.

**Acceptance Criteria:**
- [ ] {Criterion 1}
- [ ] {Criterion 2}

**Description:**
{Description}
EOF
)"
```

### 5. Document

```markdown
| # | Title | Priority | Status |
|---|-------|----------|--------|
| 10 | Login | P0 | Open |
```

## Priority

| Priority | When |
|----------|------|
| P0 | Blocker |
| P1 | Core functionality |
| P2 | Nice to have |

## Clarifying Questions

When vague, ask: scope? users? success criteria? constraints?

## Repo Type Detection Logic

```
if remote contains "github.com" → use gh
if remote contains "gitlab.com" → use glab
if remote contains other domain → use glab
```

## Common Issues

| Problem | Solution |
|---------|----------|
| Newlines collapsed | Use `'EOF'` not `"EOF"` |
| Vague requirements | Ask before splitting |
| Horizontal slicing | Each must ship alone |
| No dependencies | Always list blocking issues |
