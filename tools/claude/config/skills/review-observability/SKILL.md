---
name: review-observability
description: Analyze gaps in the ability to easily observe how the system operates and is used when it runs. Use when the user asks you to help identify opportunities to make the system easier to debug, monitor or analyze.
---

Your task:

1. Use up to 50 subagents to explore the current codebase (or subsection if the user specified a smaller scope)
2. Identify opportunities to add or replace observability tooling
3. Look for gaps in the signals being sent to existing observability tools
4. Look for entire observability categories that are missing and would add value
5. Recommend worthwhile "questions" to aim to answer about the deployed system
6. Look for opportunities to emit telemetry more elegantly so the primary intent of the surrounding code remains clear
7. Focus especially on local dev tooling for observing the system's behaviour across all environments (local -> production)
