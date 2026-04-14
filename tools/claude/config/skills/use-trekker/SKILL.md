---
name: use-trekker
description: Full reference for the trekker task management workflow. Use when working with trekker issues, planning multi-step work, or managing task lifecycle.
allowed-tools: [Bash]
model: haiku
---

## Quick Reference

```bash
# Finding work
trekker ready                                   # Unblocked tasks + what they unblock
trekker task list --status in_progress          # Active work
trekker task show TREK-1                        # Full task details
trekker comment list TREK-1                     # Context from prior sessions
trekker search "query"                          # Full-text across everything

# Single tasks
trekker task create -t "..." -d "..." -p 1
trekker task update TREK-1 -s in_progress
trekker comment add TREK-1 -a "claude" -c "Resolution: ..."
trekker task update TREK-1 -s completed

# Epics
trekker epic create -t "..." -d "..." -p 2
trekker task create -t "..." -d "..." -p 2 -e EPIC-1
trekker dep add TREK-2 TREK-1                   # TREK-2 depends on TREK-1
trekker epic show EPIC-1                        # Epic details
trekker task list --epic EPIC-1                 # Children
trekker epic complete EPIC-1                    # Archive epic + all tasks
```

## Before Implementing: Always Create a Task

When the user approves work, run `trekker task create` BEFORE reading any files or writing code. Context loss can happen anytime — the task is the handoff for the next agent.

```bash
trekker task create -t "Fix Pushover notifications" -p 1 \
  -d "Problem: X. Approach: Y. Done when: Z."
trekker task update TREK-1 -s in_progress
# THEN read files and implement
```

## Writing Descriptions

Descriptions are the primary context a future agent has. Focus on **intent, constraints, and validation** — not one specific implementation.

**Structure every description around:**

1. **Problem / Goal** — what's wrong or what we want, and why it matters now
2. **Approach** — the agreed strategy and why it was chosen over alternatives
3. **Constraints** — what must not break, what's out of scope
4. **Done when** — observable, pass/fail criteria (not "tests pass" — what *behaviour* is correct?)

**Example — good:**
```
Problem: watch mode loses all history when the terminal scrolls or
disconnects. Operators can't diagnose issues that happened overnight.

Approach: add a FileHandler in configure_logging() gated by a
--log-file flag. Chose this over auto-creating log files because
explicit is simpler and avoids disk cleanup concerns.

Constraints: must not change existing stderr output format. Must
work with the existing timestamped StreamHandler.

Done when: running `agent-loop watch --log-file /tmp/test.log`
writes timestamped output to the file while also printing to
stderr. Killing and restarting appends rather than truncates.
```

**Example — bad:**
```
Add a FileHandler to logging.py line 12. Import logging at the top.
Create a new parameter log_file: Path | None = None. Wire it in
cli.py by adding --log-file to the argparse watch subparser.
```

The bad example prescribes one implementation rather than capturing intent. A future agent can't tell *why* these changes exist or how to validate them.

## Closing Tasks

Trekker has no single close-with-resolution command. Use this two-step pattern:

```bash
# 1. Record what was done and what to know
trekker comment add TREK-1 -a "claude" \
  -c "Resolution: added FileHandler gated by --log-file flag. Appends on restart. StreamHandler output unchanged."

# 2. Mark complete
trekker task update TREK-1 -s completed
```

Always add the resolution comment **before** marking complete. The comment is the audit trail — without it, "completed" tells the next agent nothing about what happened.

## Creating Epics

When approved work has multiple distinct pieces, create an **epic** with **child tasks**. The epic holds the *why* and *shape*; each child is self-contained.

**Epic descriptions** — goal, constraints, key decisions, implementation order. No code snippets or per-step instructions. The epic description is a *summary* — it explains why the work exists and how the pieces fit together, not what to do.

**All actionable work must be a child task.** If something needs to be implemented, tested, fixed, or validated, it's a task — not a bullet point in the epic description. The epic is complete when all its children are complete. If the epic description contains work items that aren't represented by children, the epic is malformed.

**Child descriptions** — each child gets its own problem/approach/constraints/done-when, even if derived from the parent. A fresh agent running `trekker task show TREK-N` must have enough context to start without reading the epic.

```bash
# 1. Create the epic (shape only — no actionable items here)
trekker epic create -t "Observability gaps" -p 2 \
  -d "Goal: ... Key decisions: ... Order: 1, 2, 3."

# 2. Every work item becomes a child task
trekker task create -t "Add verbose subprocess logging" -p 1 -e EPIC-1 \
  -d "Problem: ... Approach: ... Done when: ..."
trekker task create -t "Add persistent log file" -p 1 -e EPIC-1 \
  -d "Problem: ... Approach: ... Done when: ..."

# 3. Express ordering with dependencies
trekker dep add TREK-2 TREK-1   # TREK-2 depends on TREK-1
```

**Never** create an epic without children in the same step. **Never** leave actionable work described only in the epic — if it's worth mentioning, it's worth tracking as a child task.

## Task Lifecycle

### Single task

1. Claim → `trekker task update TREK-1 -s in_progress`
2. Implement in small themes (one coherent change per commit)
3. After each theme: STOP, report, wait for commit approval
4. When done → resolution comment + mark completed

### Epic child

1. Find ready work → `trekker ready`
2. Claim → `trekker task update TREK-N -s in_progress`
3. Implement + commit (same stop-and-report cycle)
4. Close child → resolution comment + mark completed
5. Next child unblocks automatically via dependencies
6. Repeat until all children done
7. Close epic → `trekker epic complete EPIC-1`

### After closing, present next options

```
Task complete! What's next?

1. Continue with this epic:
   - TREK-N: [next unblocked task]

2. Other ready work: trekker ready

3. Something else?
```

## Starting a New Session

```bash
trekker ready                              # What's unblocked
trekker task list --status in_progress     # What's in flight
trekker task show TREK-1                   # Full context
trekker comment list TREK-1                # Prior session notes
trekker search "keyword"                   # Find relevant tasks
```

## Checkpoint Comments

When context may be lost (long task, switching focus, end of session), record a checkpoint:

```bash
trekker comment add TREK-1 -a "claude" \
  -c "Checkpoint: completed X and Y. Remaining: Z. Key decision: chose A over B because C. Files touched: foo.py, bar.py."
```

## Priority Scale

0=critical, 1=high, 2=medium (default), 3=low, 4=backlog, 5=someday
