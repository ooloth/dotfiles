---
name: use-beads
description: Full reference for the beads task management workflow. Use when working with beads issues, planning multi-step work, or managing task lifecycle.
allowed-tools: [Bash]
---

## Quick Reference

```bash
# Finding work
bd ready                              # Find unblocked work
bd list --status=in_progress          # See active work
bd show <id>                          # View issue details

# Single tasks
bd create --title "..." --type task --priority P1 --design "..."
bd update <id> --claim                # Set assignee + in_progress atomically
bd update <id> --notes "..."          # Add implementation notes
bd update <id> --design "..."         # Add code snippets or decisions
bd close <id> -r "summary of work"    # Complete work

# Epics
bd create --title "..." --type epic --priority P2 --design "..."
bd create --title "..." --type task --parent <epic-id> --design "..."
bd dep add <child-2> <child-1>        # child-2 depends on child-1
bd children <epic-id>                 # Check progress on children
bd epic status                        # Completion across all epics
```

> **Warning**: Never use `bd edit` — it opens `$EDITOR` (vim/nano) which blocks agents. Use `bd update --field "value"` instead.

## Before Implementing: Always Create a Beads Task

When the user approves work, run `bd create` BEFORE reading any files or writing code. Auto-compact or disconnection can happen anytime — the beads task is the handoff for the next Claude.

```bash
bd create --title "Fix Pushover notifications" \
  --type task --priority P1 \
  --design "What's broken: X. Approved approach: Y. Success: Z."
bd update <id> --claim
# THEN read files and implement
```

> **Tip**: `bd update` and `bd close` with no ID act on the last touched issue — useful right after `bd create`.

## Creating Epics

When approved work has multiple distinct pieces, create an **epic** with **children** — never a single monolithic item. The epic holds the _why_ and _shape_; each child is a self-contained task a fresh agent can pick up without reading the parent.

**Epic design** — keep it to: goal, constraints, key decisions, and implementation order. No code snippets, directory layouts, or per-step instructions.

**Child designs** — each child gets its own "what's broken / approach / success criteria" even if derived from the parent. A fresh agent running `bd show <child-id>` must have enough context to start working.

```bash
# 1. Create the epic (shape + decisions only)
bd create --title "Generalize loop engine" \
  --type epic --priority P2 \
  --design "Goal: ... Key decisions: ... Implementation order: 1, 2, 3."

# 2. Immediately create children with self-contained designs
bd create --title "Extract WorkSpec dataclass" \
  --type task --priority P2 --parent <epic-id> \
  --design "What: ... Approach: ... Success: ..."
bd create --title "Add RalphStrategy" \
  --type task --priority P2 --parent <epic-id> \
  --design "What: ... Approach: ... Success: ..."

# 3. If children must be done in order, express that with dependencies
bd dep add <child-2> <child-1>   # child-2 depends on child-1
```

**Never** create an epic without children in the same step. If you find yourself putting implementation detail (code, file paths, step-by-step instructions) in the epic design, that detail belongs in a child.

When children must be sequential, use `bd dep add` so `bd ready` naturally surfaces only the next unblocked child. Independent children need no dependencies — they'll all appear in `bd ready` immediately.

## When to Use Beads vs TodoWrite

**ALWAYS use beads for:**

- Work involving decisions about what to do/skip (PR reviews, optimization)
- Multi-item work where you need to record WHY you're addressing/skipping each item
- Any work that must survive auto-compact
- Assessments with categories (must fix, should fix, won't fix)

**TodoWrite only for:**

- Simple step tracking within a single beads issue
- Ephemeral notes that don't need to persist

## Assessing Multiple Items (PR feedback, bug lists, optimizations)

Create the beads task FIRST with a full assessment, before implementing anything:

```bash
bd create --title "Address PR review feedback" \
  --type task --priority P1 \
  --design "Assessment:

MUST FIX:
- Item 1 (reason)

SHOULD FIX:
- Item 2 (reason)

WON'T FIX:
- Item 3 (reason we're skipping)"
```

Then work through items, updating notes as you go:

```bash
bd update <id> --notes "Item 1: Discovered X during implementation"
```

## Task Lifecycle

### Single task

1. Claim work → `bd update <id> --claim`
2. Implement in small themes (one stop per commit)
3. After each theme: STOP, report, wait for "committed"
4. When all themes done → `bd close <id> -r "summary"`

### Epic child

1. Find ready work → `bd ready --parent <epic-id>`
2. Claim → `bd update <child-id> --claim`
3. Implement + commit (same stop-and-report cycle as single tasks)
4. Close child → `bd close <child-id> -r "summary"`
5. Next child unblocks automatically (if deps were set)
6. Repeat until all children closed
7. Close epic → `bd epic close-eligible` or `bd close <epic-id> -r "all children complete"`

### After closing, present next options:

```
Task complete! What's next?

1. Continue with [area] tasks:
   - META-xyz: [description]

2. Switch areas: bd ready

3. Something else?
```

## Starting a New Session

```bash
bd ready                        # Find available work
bd list --status=in_progress    # See what's in flight
bd show <id>                    # Get full context
bd children <id>                # If it's an epic, see children
```
