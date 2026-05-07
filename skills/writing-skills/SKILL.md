---
name: writing-skills
description: Use when creating new skills, editing existing skills, or verifying skills work before deployment
---

# Writing Skills

## Overview

**Writing skills IS TDD applied to process documentation.**

You write test cases (pressure scenarios with subagents), watch them fail (baseline behavior), write the skill (documentation), watch tests pass (agents comply), and refactor (close loopholes).

**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.

**REQUIRED BACKGROUND:** Understand tdd before using this skill.

**Official guidance:** See anthropic-best-practices.md for Anthropic's official skill authoring best practices.

## What is a Skill?

A **skill** is a reference guide for proven techniques, patterns, or tools. Skills help future Claude instances find and apply effective approaches.

**Skills are:** Reusable techniques, patterns, tools, reference guides

**Skills are NOT:** Narratives about how you solved a problem once

## TDD Mapping for Skills

| TDD Concept | Skill Creation |
|-------------|----------------|
| **Test case** | Pressure scenario with subagent |
| **Production code** | Skill document (SKILL.md) |
| **Test fails (RED)** | Agent violates rule without skill (baseline) |
| **Test passes (GREEN)** | Agent complies with skill present |
| **Refactor** | Close loopholes while maintaining compliance |
| **Write test first** | Run baseline scenario BEFORE writing skill |
| **Watch it fail** | Document exact rationalizations agent uses |
| **Minimal code** | Write skill addressing those specific violations |
| **Watch it pass** | Verify agent now complies |
| **Refactor cycle** | Find new rationalizations → plug → re-verify |

The entire process follows RED-GREEN-REFACTOR.

## When to Create a Skill

**Create when:** Technique wasn't obvious, you'd reference again, pattern applies broadly, others would benefit.

**Don't create for:** One-off solutions, well-documented standards, project-specific conventions (use CLAUDE.md), mechanical constraints (automate with regex).

## Skill Types

| Type | Description |
|------|-------------|
| **Technique** | Concrete method with steps (condition-based-waiting) |
| **Pattern** | Way of thinking (flatten-with-flags) |
| **Reference** | API docs, syntax guides (office docs) |

## Directory Structure

```
skills/
  skill-name/
    SKILL.md              # Required main reference
    supporting-file.*     # Only if needed (heavy reference 100+ lines, reusable tools)
```

**Flat namespace** - all skills in one searchable directory.

**Keep inline:** Principles, code patterns (<50 lines), everything else.

## SKILL.md Structure

**Frontmatter (YAML):**
- Required: `name` (letters, numbers, hyphens only) and `description`
- Max 1024 characters total
- `description`: Third-person, starts with "Use when...", describes ONLY triggering conditions (NOT workflow)

**Template:**
```markdown
---
name: Skill-Name-With-Hyphens
description: Use when [specific triggering conditions and symptoms]
---

# Skill Name

## Overview
What is this? Core principle in 1-2 sentences.

## When to Use
[Small inline flowchart IF decision non-obvious]
Bullet list with SYMPTOMS and use cases. When NOT to use.

## Core Pattern
Before/after code comparison

## Quick Reference
Table or bullets for scanning common operations

## Implementation
Inline code for simple patterns. Link to file for heavy reference.

## Common Mistakes
What goes wrong + fixes

## Real-World Impact (optional)
Concrete results
```


## Claude Search Optimization (CSO)

### 1. Rich Description Field

**Purpose:** Claude reads description to decide which skills to load. Make it answer: "Should I read this skill right now?"

**Format:** Start with "Use when..." describing triggering conditions only.

**CRITICAL: Description = When to Use, NOT What the Skill Does**

Testing revealed: when description summarizes workflow, Claude follows description instead of reading full skill. A description saying "code review between tasks" caused ONE review, even though flowchart showed TWO reviews.

When changed to just "Use when executing implementation plans with independent tasks" (no workflow), Claude correctly followed two-stage review.

**The trap:** Descriptions that summarize workflow create a shortcut Claude will take.

```yaml
# BAD: Summarizes workflow - Claude follows description instead of skill
description: Use when executing plans - dispatches subagent per task with code review

# BAD: Too much process detail
description: Use for TDD - write test first, watch it fail, write minimal code, refactor

# GOOD: Just triggering conditions
description: Use when executing implementation plans with independent tasks
```

**Content:**
- Concrete triggers, symptoms, situations that signal this skill applies
- Describe *problem* (race conditions, inconsistent behavior) not language-specific symptoms
- Keep triggers technology-agnostic unless skill is technology-specific
- Write in third person
- **NEVER summarize the skill's process or workflow**

```yaml
# BAD: Too abstract
description: For async testing

# BAD: First person
description: I can help you with async tests when they're flaky

# GOOD: Problem-focused
description: Use when tests have race conditions, timing dependencies, or pass/fail inconsistently
```

### 2. Keyword Coverage

Use words Claude would search: error messages ("Hook timed out", "ENOTEMPTY"), symptoms ("flaky", "hanging", "zombie"), synonyms ("timeout/hang/freeze", "cleanup/teardown/afterEach"), tools (commands, library names).

### 3. Descriptive Naming

Use active voice, verb-first: `creating-skills` not `skill-creation`, `condition-based-waiting` not `async-test-helpers`. Gerunds (-ing) work well for processes.

### 4. Token Efficiency

**Problem:** getting-started and frequently-referenced skills load into EVERY conversation.

**Target word counts:** getting-started workflows <150, frequently-loaded <200, other skills <500.

**Techniques:**
- Move details to `--help`: Reference instead of documenting all flags
- Use cross-references: "Use [other-skill] for workflow" instead of repeating details
- Compress examples: Minimal example beats verbose
- Eliminate redundancy: Don't repeat cross-referenced skills

**Verification:** `wc -w skills/path/SKILL.md`

### Cross-Referencing

Use skill name only with explicit markers:
- `**REQUIRED SUB-SKILL:** Use tdd`
- `**REQUIRED BACKGROUND:** You MUST understand debugging`

❌ Bad: `See skills/testing/test-driven-development` (unclear if required)
❌ Bad: `@skills/testing/test-driven-development/SKILL.md` (force-loads, burns context)

**Why no @ links:** @ syntax force-loads files, consuming 200k+ context before needed.

## Flowchart Usage

Use flowcharts ONLY for: non-obvious decision points, process loops where you might stop too early, "When to use A vs B" decisions.

Never use for: reference material (use tables), code examples (use markdown blocks), linear instructions (use numbered lists), labels without semantic meaning.

```
digraph when_flowchart {
    "Need to show information?" [shape=diamond];
    "Decision where I might go wrong?" [shape=diamond];
    "Use markdown" [shape=box];
    "Small inline flowchart" [shape=box];
    "Need to show information?" -> "Decision where I might go wrong?" [label="yes"];
    "Decision where I might go wrong?" -> "Small inline flowchart" [label="yes"];
    "Decision where I might go wrong?" -> "Use markdown" [label="no"];
}
```

See @graphviz-conventions.dot for style rules. Render to SVG with `render-graphs.js`: `./render-graphs.js ../some-skill` or `./render-graphs.js ../some-skill --combine`.

## Code Examples

**One excellent example beats many mediocre ones.**

Choose most relevant language (TypeScript/JS for testing, Shell/Python for debugging, Python for data processing).

Good example: complete and runnable, explains WHY, from real scenario, shows pattern clearly, ready to adapt.

Don't: implement in 5+ languages, create fill-in-the-blank templates, write contrived examples.

## File Organization

| Structure | When to Use |
|-----------|-------------|
| `skill/SKILL.md` (inline) | All content fits |
| `skill/SKILL.md + tool file` | Tool is reusable code |
| `skill/SKILL.md + reference files` | Reference material too large for inline |

## The Iron Law

```
NO SKILL WITHOUT A FAILING TEST FIRST
```

Applies to NEW and EDITS. Write skill before testing? Delete it. Start over. Edit skill without testing? Same violation.

**No exceptions:** Not for "simple additions", "just adding a section", "documentation updates". Don't keep untested changes as "reference". Don't "adapt" while running tests. Delete means delete.

## Testing All Skill Types

| Skill Type | Test Approach | Success Criteria |
|------------|--------------|------------------|
| **Discipline-enforcing** (TDD, verification) | Academic questions, pressure scenarios, combined pressures (time + sunk cost + exhaustion) | Agent follows rule under maximum pressure |
| **Technique** (condition-based-waiting) | Application scenarios, variation scenarios, missing information tests | Agent successfully applies technique |
| **Pattern** (reducing-complexity) | Recognition scenarios, application scenarios, counter-examples | Agent correctly identifies when/how to apply |
| **Reference** (API docs) | Retrieval scenarios, application scenarios, gap testing | Agent finds and correctly applies information |

## Common Rationalizations for Skipping Testing

| Excuse | Reality |
|--------|---------|
| "Skill is obviously clear" | Clear to you ≠ clear to other agents. Test it. |
| "It's just a reference" | References can have gaps. Test retrieval. |
| "Testing is overkill" | Untested skills have issues. Always. |
| "I'll test if problems emerge" | Problems = agents can't use skill. Test BEFORE deploying. |
| "No time to test" | Deploying untested skill wastes more time fixing it later. |

**All mean: Test before deploying. No exceptions.**

## Bulletproofing Against Rationalization

Discipline-enforcing skills need to resist rationalization. Agents are smart and find loopholes under pressure.

**Psychology note:** See persuasion-principles.md for research (Cialdini, 2021; Meincke et al., 2025) on authority, commitment, scarcity, social proof, unity.

### Close Every Loophole Explicitly

❌ Bad: `Write code before test? Delete it.`

✅ Good:
```markdown
Write code before test? Delete it. Start over.

**No exceptions:**
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete
```

### Address "Spirit vs Letter" Arguments

Add early:
```markdown
**Violating the letter of the rules is violating the spirit of the rules.**
```

### Build Rationalization Table

Capture rationalizations from baseline testing. Every excuse agents make:

```markdown
| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
```

### Create Red Flags List

```markdown
## Red Flags - STOP and Start Over

- Code before test
- "I already manually tested it"
- "Tests after achieve the same purpose"
- "It's about spirit not ritual"
- "This is different because..."

**All mean: Delete code. Start over with TDD.**
```

## RED-GREEN-REFACTOR for Skills

### RED: Write Failing Test (Baseline)

Run pressure scenario with subagent WITHOUT skill. Document exact behavior: choices made, rationalizations used (verbatim), pressures that triggered violations.

### GREEN: Write Minimal Skill

Write skill addressing those specific rationalizations. Run same scenarios WITH skill. Agent should now comply.

### REFACTOR: Close Loopholes

Agent found new rationalization? Add explicit counter. Re-test until bulletproof.

**Testing methodology:** See @testing-skills-with-subagents.md - how to write pressure scenarios, pressure types (time, sunk cost, authority, exhaustion), plugging holes systematically.

## Anti-Patterns

| Anti-Pattern | Why Bad |
|--------------|---------|
| Narrative example ("In session 2025-10-03...") | Too specific, not reusable |
| Multi-language dilution (example-js.py, example-go.go) | Mediocre quality, maintenance burden |
| Code in flowcharts | Can't copy-paste, hard to read |
| Generic labels (helper1, step2) | Labels should have semantic meaning |

## STOP: Before Moving to Next Skill

**After writing ANY skill, you MUST STOP and complete the deployment process.**

Do NOT: create multiple skills in batch without testing each, move to next skill before current is verified, skip testing because "batching is more efficient".

Deploying untested skills = deploying untested code.

## Skill Creation Checklist

**IMPORTANT: Use TodoWrite to create todos for EACH item.**

**RED Phase - Write Failing Test:**
- [ ] Create pressure scenarios (3+ combined pressures for discipline skills)
- [ ] Run scenarios WITHOUT skill - document baseline behavior verbatim
- [ ] Identify patterns in rationalizations/failures

**GREEN Phase - Write Minimal Skill:**
- [ ] Name uses only letters, numbers, hyphens
- [ ] YAML frontmatter with `name` and `description` (max 1024 chars; see spec)
- [ ] Description starts with "Use when...", specific triggers/symptoms, third person
- [ ] Keywords throughout for search
- [ ] Clear overview with core principle
- [ ] Address specific baseline failures from RED
- [ ] Code inline OR link to separate file
- [ ] One excellent example (not multi-language)
- [ ] Run scenarios WITH skill - verify agents now comply

**REFACTOR Phase - Close Loopholes:**
- [ ] Identify NEW rationalizations from testing
- [ ] Add explicit counters (if discipline skill)
- [ ] Build rationalization table from all test iterations
- [ ] Create red flags list
- [ ] Re-test until bulletproof

**Quality Checks:**
- [ ] Small flowchart only if decision non-obvious
- [ ] Quick reference table
- [ ] Common mistakes section
- [ ] No narrative storytelling
- [ ] Supporting files only for tools or heavy reference

**Deployment:**
- [ ] Commit skill to git and push to fork (if configured)
- [ ] Consider contributing back via PR (if broadly useful)

## Discovery Workflow

How future Claude finds your skill:

1. **Encounters problem** ("tests are flaky")
2. **Finds SKILL** (description matches)
3. **Scans overview** (is this relevant?)
4. **Reads patterns** (quick reference table)
5. **Loads example** (only when implementing)

Optimize for this flow - put searchable terms early and often.

## The Bottom Line

**Creating skills IS TDD for process documentation.**

Same Iron Law: No skill without failing test first.
Same cycle: RED (baseline) → GREEN (write skill) → REFACTOR (close loopholes).
Same benefits: Better quality, fewer surprises, bulletproof results.

Follow TDD for code? Follow it for skills.
