---
name: conventions-for-observability
description: Observability patterns (when alternate patterns are not specified at the project level)
model: haiku
---

## Proactively make future debugging easier

- All code paths should emit signals that prepare to answer likely questions about what happened
