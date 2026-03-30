---
name: review-conventions
description: Perform a comprehensive review of all codebase conventions using subagents and report your findings. Use when asked to review the codebase or identify opportunities to improve it.
---

## Your task

1. Assign each of the following prompts to a separate subagent, scoped to the entire codebase (or subsection if the user specified a smaller scope) with your preferred response format specified:
   a. **Subagent 1**: `/review-architecture` skill
   a. **Subagent 2**: `/review-documentation` skill
   a. **Subagent 3**: `/review-observability` skill
   a. **Subagent 4**: `/review-testing` skill
   a. **Subagent 5**: `/review-types` skill
   a. **Subagent 6**: `/review-code-style` skill
2. Wait for all subagents to report their results to you in the format you requested
3. Ensure you understand the results and are equipped to compare their relative importance (explore specific areas of the codebase yourself if that helps you)
4. Rank the findings by priority for the user to address (based on impact, cost of delay, ROI, etc)
5. Present the prioritized findings to the user, ensuring a summary table is included near the end of your response for clarity
6. Recommend a next action and wait for the user's response
