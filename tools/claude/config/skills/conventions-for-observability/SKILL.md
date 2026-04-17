---
name: conventions-for-observability
description: Observability patterns (when alternate patterns are not specified at the project level). Use when the user asks you to help identify opportunities to make the system easier to debug, monitor or analyze.
model: haiku
effort: low
---

## Proactively make future debugging easier

- All code paths should emit signals that prepare to answer likely questions about what happened

Apply these conventions to the current task.
