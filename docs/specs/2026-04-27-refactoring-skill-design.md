# Refactoring Skill Design Specification

> **Status:** Draft

**Goal:** Add a standalone refactoring skill to the plan-executor TDD workflow that automatically detects and eliminates code smells after GREEN confirmation.

**Architecture:** Introduce a new `skills/refactoring/SKILL.md` loaded by plan-executor during the REFACTOR phase (Step 3). The skill provides a bad-smell classification system, a smell-to-technique cheat sheet, and a guarded execution flow. Plan-executor's Step 2 (GREEN) is extended to trigger refactoring before the commit boundary. Refactoring is always test-gated: no test failure, no refactoring.

**Tech Stack:** Markdown skill (same format as existing `skills/tdd/SKILL.md`)

---

## Architecture

### Component Overview

```
                    ┌──────────────────────────────────┐
                    │        plan-executor.md           │
                    │                                   │
                    │  Step 1: RED ──────────────────► │
                    │  Step 2: GREEN ────────────────► │
                    │         └── trigger refactoring ──┤
                    │  Step 3: REFACTOR ◄── load ───────┤
                    │         └── uses ────────────────┐│
                    │  Step 4: COMMIT (task-level)     ││
                    └──────────────────────────────────┘│
                                          ┌───────────────┴──┐
                                          │ skills/         │
                                          │ refactoring/    │
                                          │   SKILL.md      │
                                          └──────────────────┘
```

### Component Details

#### Component A: `skills/refactoring/SKILL.md` (new)

- **Responsibility:** Define the refactoring process: bad-smell classification, technique cheat sheet, and step-by-step refactoring flow with test-gate enforcement.
- **Interface:**
  - Input: None (skill is loaded via `Required` directive in plan-executor)
  - Output: Guidance consumed by plan-executor during REFACTOR phase
- **Dependencies:**
  - Plan-executor reads this skill and follows its execution flow
- **Error Handling:**
  - If refactoring breaks a test → revert the refactoring change, report the failure, stop refactoring
  - If no smell is detected → report clean, skip to commit

#### Component B: `agents/plan-executor.md` (modified)

- **Responsibility:** Execute the TDD cycle. After Step 2 GREEN, trigger the refactoring skill before commit.
- **Interface:**
  - Input: implementation plan (from plan-writer)
  - Output: DONE / BLOCKED / NEEDS_CONTEXT
- **Dependencies:**
  - `skills/refactoring/SKILL.md` — loaded via `Required` before Step 3
  - `skills/tdd/SKILL.md` — already loaded via existing `Required`
- **Error Handling:**
  - GREEN fails → stop, fix code, do not enter REFACTOR
  - Refactoring breaks tests → revert that refactoring step, report concern, continue to commit

---

## Data Flow

```
1. plan-executor completes Step 2 GREEN
   │
2. All tests pass? ──No──► Stop. Fix code. Do not refactor.
   │Yes
3. Load skills/refactoring/SKILL.md
   │
4. Scan code for one bad smell
   │
5. Smell found? ──No──► Report clean. Proceed to commit.
   │Yes
6. Apply refactoring technique (structural change only)
   │
7. Run all tests
   │
8. Tests pass? ──No──► Revert refactoring. Report failure. Stop.
   │Yes
9. Any more smells? ──Yes──► Go to step 4 (one smell at a time)
   │No
10. Proceed to Step 4 (commit)
```

---

## Error Handling

| Scenario | Handling |
|----------|----------|
| Tests fail after GREEN | Do not enter refactoring. Fix production code first. |
| Refactoring breaks a test | Revert the single refactoring change. Report "REFACTOR_FAILED: [smell] → [technique] broke test". Stop refactoring, proceed to commit. |
| Multiple smells detected | Process one at a time. Each step is independently verified. |
| No smells detected | Report "REFACTOR_SKIPPED: no code smells detected". Proceed to commit. |

---

## Testing Strategy

- No unit tests for the skill itself (it is a markdown document, not code)
- Verify plan-executor integration by:
  1. GREEN passes → confirm refactoring skill is loaded
  2. A deliberate bad smell in test code → confirm it is detected and flagged
  3. Refactoring breaks test → confirm reversion happens

---

## Constraints & Assumptions

### Hard constraints
- **No test failure, no refactoring.** If any test fails at any point, refactoring is forbidden.
- **One smell at a time.** Apply exactly one refactoring technique, verify, then repeat.
- **No new behavior.** Refactoring changes structure only — no feature addition, no API changes, no new public interfaces.
- **Revert on red.** If a refactoring step breaks a test, revert that step immediately.
- **No intermediate commits.** The entire RED → GREEN → REFACTOR cycle completes before a single task-level commit.

### Assumptions
- The refactoring skill's smell detection relies on the executor's judgment (no automated static analysis tool is introduced).
- The skill does not replace or modify the existing TDD skill — it supplements the REFACTOR phase.
- Plan-executor already has `Required: load tdd skill`; the refactoring skill is loaded as an additional `Required` before Step 3.

### Explicit non-goals
- Automated static analysis tools (e.g., linters) — detection is manual, guided by the cheat sheet
- Refactoring outside the TDD cycle
- Rewriting entire modules — each refactoring step is minimal and focused
- Changing test code — tests verify behavior; refactoring targets production code only
