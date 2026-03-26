---
name: analyze-architecture
description: Perform an architecture review to identify antipatterns that are at risk of spreading. Use when asked to identify opportunities to make the system easier to understand and maintain.
---

Your task:

1. Use up to 50 subagents to explore the current codebase (or subsection if the user specified a smaller scope)
2. Identify opportunities to improve the architecture, shape, extensibility of the current system
3. Look for any code that does not represent a good example for humans or agents to follow
4. Focus especially on patterns you would not want a future agent to spread
