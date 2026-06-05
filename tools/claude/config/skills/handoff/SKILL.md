---
name: handoff
description: Tell the next agent everything they need to know to continue your work.
argument-hint: 'What will the next session focus on? [optional]'
disable-model-invocation: true
---

## Goal

Hand off all context and instructions necessary for a fresh agent to continue your work.

## Guidance

- If the user passed arguments, treat them as a description of what the next session will focus on
  and tailor the handoff accordingly
- DO NOT constrain the next agent's implementation choices; focus on ensuring they are aware of the
  current vs ideal state, any gotchas and other learnings, any important invariants, and generally
  everything YOU would want to know so you could decide yourself how to achieve those goals
- Do not duplicate content already captured in other artifacts (e.g. docs, issues, commits, diffs);
  reference them by path or URL instead
- Redact any sensitive information, such as API keys, passwords, or PII
- If the work is tracked in a GitHub Issue, Linear Issue, Jira Task, etc, record your handoff as a
  comment on that existing issue
- Otherwise, record it a `/tmp/` markdown doc and provide the file path
