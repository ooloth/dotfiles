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
- If the next agent should read specific files to understand the overall vision or important
  constraints, include those in the list of places for that agent to start
- Do not duplicate content already captured in other artifacts (e.g. docs, issues, commits, diffs);
  reference them by path or URL instead
- Redact any sensitive information, such as API keys, passwords, or PII
- **Before writing, read any existing comments on the issue.** Identify what is already captured
  and what is stale or missing. Correct and extend rather than duplicate.
- **Before writing, ask: does any of this context have lasting value beyond this handoff?**
  If something would be useful to every future agent working in this area — not just the next one
  — consider whether it belongs in an appropriate project file (architecture doc, README,
  CLAUDE.md/AGENTS.md, decision record, etc.). Capture it there and reference it from the
  handoff rather than only in the comment.
- **Inform about relevant prior decisions** — design choices, trade-offs, things tried and
  rejected. Share the context; the next agent may have new information and should form their own
  view.
- **Call out existing things to reuse**: code, types, patterns, stubs, reference implementations.
  Give file paths. Don't make the next agent discover independently what already exists.
- **Make the starting order explicit** for multi-part work. State the entry point and sequence;
  don't make the next agent infer dependencies.

## Where to record

- If the work is tracked in a GitHub Issue, Linear Issue, Jira Task, etc, record your handoff as a
  comment on that existing issue
- If the project uses a shared issue tracker like that but this represents a new issue, record it
  as such
- Otherwise, record it in a `/tmp/` markdown doc and provide the file path

## Final step

As your final step, provide the ideal 1-2 sentence prompt for me to provide to the next agent to
point them towards the right next step with an overall understanding of the overall design vision
if "/discuss <handoff write-up location>" is not sufficient; ensure any relevant doc references not
included in the handoff doc are mentioned (though prefer to put those references in the handoff
write-up instead when possible).
