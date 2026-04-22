---
name: discuss
description: Plan how to best implement a solution, focusing on deeply understanding the problem and intended outcomes. TRIGGER whenever the user has a task they want you to work on.
argument-hint: '[task number or description]'
effort: high
model: opus
---

## Context

- The task (or issue, problem, ticket, etc) the user wants to discuss is what they mentioned here: $ARGUMENTS

## Your task

### Phase 0: Load Conventions

Before exploring the problem, load the conventions that will govern the implementation:

1. List `~/.claude/conventions/` and the project's `.claude/conventions/` (if it exists)
2. Based on the task description and likely file types involved, load the relevant convention files
3. If the task scope is unclear, load all of them — it's cheaper to load too many than to miss one

These are the criteria the implementation will be evaluated against. Having them in context now
means the plan you propose will already respect them, and the implementation agent will inherit
that awareness rather than discovering violations at review time.

### Phase 1: Discuss the Problem

1. If the user did not specify what they want to discuss, ask them for that information
2. If you are unclear what the user is asking, clarify until you're quite sure
3. Once you understand the discussion topic, use as many subagents as you need to explore all
   relevant code paths and documentation
4. Proactively answer every question and follow-up question that occurs to you by exploring the
   codebase and anything else that would help you
5. If the task (or topic) idea seems stale or otherwise a poor fit for the current codebase and
   docs, proactively investigate whatever would help you and the user decide whether this work
   should be redefined, skipped, etc
6. Once you are as informed as you can be by exploring on your own, have a discussion with the user
   and grill them about every requirement and intended outcome that is not already obvious

### Phase 2: Discuss the Solution

1. After thoroughly understanding the goal, discuss the ideal way to achieve it in the context of
   this project and its domain
2. Grill the user about every implementation decision that does not already have an obvious answer
3. Proactively recommend whether the implementation is best suited to a single PR vs multiple
   stacked PRs vs multiple parallel PRs
4. Present the full plan to the user and wait for their explicit approval before you act
