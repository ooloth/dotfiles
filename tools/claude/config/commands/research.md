---
description: Gather all facts needed to support a DIFFERENT agent's ability to understand the related problem well enough to solve it and record them in a research.md
---

## Context:

- All useful findings must be recorded in a `.claude/specs/<this-topic>/research.md` file
- The `research.md` should be optimized for hand-off to a DIFFERENT developer or agent who will not be able to ask you any follow-up questions
- All questions clarifying interpretation or specifics should be anticipated and proactively answered
- Anyone should be able to read the `research.md` and understand everything you learned

## Steps

1. Create a `.claude/specs/<this-topic>/research.md` file if missing
1. Ask me clarifying questions about what to research and why until you are 95% sure you understand the goal
1. Summarize what is being researched and why in the `research.md`
1. Use one or more parallel subagents to gather all information you need from the codebase
1. Summarize their findings in the `research.md`, including file names and line number ranges when referencing code
1. Use one or more parallel subagents to gather all information you need from the internet, including URLs when referencing documentation and best practices
1. Summarize their findings in the `research.md`
1. Review the `research.md` from the point of view of a new developer/agent trying to plan the solution to the relevant problem - what questions would they have?
1. Repeat the steps above to record the answers to those questions in the `research.md` until you can't think of anything else they might ask
1. Ask me to review the `research.md`

## Research topic

Topic: $ARGUMENTS
