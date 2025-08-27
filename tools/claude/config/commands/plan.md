---
description: Identify the highest ROI solution to the current problem and record its implementation and validation plan in a plan.md in enough detail to support a DIFFERENT agent's ability to implement the solution without asking any follow-up questions
---

## Context

- You should not need to do any of your own research (e.g. reading the codebase, searching the web)
- All the facts you need should already be recorded in a `.claude/specs/<this-topic>/research.md` file
- The plan you make must be recorded in a `.claude/specs/<this-topic>/plan.md` file
- The `plan.md` should be optimized for hand-off to a DIFFERENT developer or agent who will NOT be able to ask you any follow-up questions
- All potential detailed follow-up questions should be anticipated and proactively answered
- Anyone should be able to read the `plan.md` and understand exactly how to implement this change and validate it

## Steps

1. Read the `.claude/specs/<this-topic>/research.md` - if you can't find it, ask me where it is
1. Create a `.claude/specs/<this-topic>/plan.md` file if missing
1. Ask me clarifying questions about what problem we're solving and why
1. Summarize what we're planning and why in the `plan.md`
1. Ask me clarifying questions about any constraints
1. Summarize any constraints in the `plan.md`
1. Ask me clarifying questions about success criteria
1. Summarize success criteria in the `plan.md`
1. Use one or more parallel subagents to explore alternative ways to solving the problem
1. Summarize their findings in the `plan.md`, including file names and line number ranges when referencing code and URLs when referencing documentation and best practices
1. Compare the pros/cons of each alternative and record your analysis in the `plan.md`
1. Recommend the solution with the best ROI given the current constrains and record your rationale in the `plan.md`
1. Make a detailed implementation plan, including references to specific code ranges, and add it to the `plan.md`
1. Make a detailed validation plan and add it to the `plan.md`
1. Review the `plan.md` from the point of view of a new developer/agent trying to implement the solution you've planned - what detailed follow-up questions might they have?
1. Repeat the steps above to record the answers to those questions in the `plan.md` until you can't think of any more potential follow-up questions
1. Ask me to review the `plan.md`

## Problem

Problem: $ARGUMENTS
