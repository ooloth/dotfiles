---
description: Identify the highest ROI solution to the current problem and record its implementation and validation plan in a markdown file for a DIFFERENT agent to later use to implement the solution
---

## Context

- The plan you make must be recorded in a `.claude/specs/<this-topic>.md` file
- The `*.md` file should be optimized for hand-off to a DIFFERENT agent who will NOT be able to ask you any follow-up questions
- All potential detailed follow-up questions about what, why and should be anticipated and proactively answered
- No unnecessary fluff or repetition should be included - keep it concise and specific

## Steps

1. Create a `.claude/specs/<this-topic>.md` file if missing
1. Ask me any questions you have about what problem we're solving and why and what success looks like
1. Use one or more parallel subagents to gather all information you need from the codebase and the internet
1. Use one or more parallel subagents to explore alternative ways to solving the problem
1. Analyze the pros/cons of each alternative
1. Record your analysis, recommendation, implementation plan and validation plan in the `*.md`
1. Ask me to review the `*.md`

## Problem

Problem: $ARGUMENTS
