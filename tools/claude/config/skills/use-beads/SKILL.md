---
name: use-beads
description: Full reference for the beads task management workflow. Use when working with beads issues, planning multi-step work, or managing task lifecycle.
allowed-tools: [Bash]
---

## Quick Reference

```bash
bd ready                              # Find available work
bd list --status=in_progress          # See active work
bd show <id>                          # View issue details
bd create --title "..." --type task --priority P1 --design "..."
bd update <id> --status in_progress   # Claim work
bd update <id> --notes "..."          # Add implementation notes
bd update <id> --design "..."         # Add code snippets or decisions
bd close <id> -r "summary of work"    # Complete work
bd sync                               # Sync with git
```

## Before Implementing: Always Create a Beads Task

When the user approves work, run `bd create` BEFORE reading any files or writing code. Auto-compact or disconnection can happen anytime — the beads task is the handoff for the next Claude.

```bash
bd create --title "Fix Pushover notifications" \
  --type task --priority P1 \
  --design "What's broken: X. Approved approach: Y. Success: Z."
bd update <id> --status in_progress
# THEN read files and implement
```

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

1. User assigns work → `bd update <id> --status in_progress`
2. Implement as multiple themes/commits (one stop per theme)
3. After each theme: STOP, report, wait for "committed"
4. When all themes done → `bd close <id> -r "summary of all work"`
5. After closing, present next options:

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
```

## Capturing Context Before Auto-Compact

If within 10% of context limit, pause and capture all important decisions:
```bash
bd update <id> --notes "Current state: X. Next step: Y. Key decision: Z (reason)."
```
