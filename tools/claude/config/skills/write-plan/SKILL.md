---
name: write-plan
description: Build a persisted plan document — problem through implementation design — for any ambiguous, multi-step, or risky task. ALWAYS invoke before proposing an approach to non-trivial work, before any side-effecting action.
argument-hint: '[task number or description]'
effort: high
model: opus
---

## Context

- Task: $ARGUMENTS

## Your task

Fill out the template in `~/.claude/references/plans.md`, in order, upholding every Must/Should/Consider invariant in that file as you go. Read-only exploration is allowed throughout — no edits, writes, mutating shell commands, commits, or ticket creation until an approval gate below is passed.

1. Read `~/.claude/references/README.md` and `~/.claude/references/plans.md`.
2. Load any other reference file the task touches (`type-design.md`, `testing.md`, `code-structure.md`, `code-readability.md`, language-specific files). Explore existing domain types, naming, and testing patterns in the codebase before drafting new ones.
3. Before establishing the foundation, confirm the task's premise still holds given what you find — if it's already solved, stale, or no longer matches the current codebase, surface that to the user before continuing rather than building a plan for a stale request.
4. Work the template top to bottom. Don't start a later section while an earlier required one is unresolved. When weighing alternatives, assess reversibility first — two-way doors don't need exhaustive comparison and can move to a decision quickly.
5. Facts are your job, not the user's — dispatch subagents to find them. For what blocks a correct decision: batch every such question whose prerequisites are already settled into one numbered round, each with a recommended answer, and wait for the answers before opening the next round. Don't ask about anything still gated on a question you haven't gotten an answer to yet.
6. Before presenting: review every entry in Assumptions and every stated Constraint/Priority — for each, ask "would this being wrong change the recommendation?" If yes, it belongs in Questions, not Assumptions; resolve it (ask the user or investigate) before presenting.
7. Stop after Approach decision. Present what's written and ask for explicit approval. On approval, persist it (ticket comment or Trekker task) before continuing.
8. Continue from Implementation alternatives considered through Open questions, same discipline.
9. Repeat step 6's review, then stop again before implementation begins. On approval, persist the rest, then proceed with the first slice.
