---
name: prioritize
description: Find all tracked issues and work item ideas for the current project and rank them by priority to address. TRIGGER whenever the user asks for help deciding what to work on next.
argument-hint: '[issue source]'
effort: high
model: opus
---

## Context

Possible sources of tracked work ideas include:

- Jira (if mentioned in project)
- Monday (if mentioned in project)
- GitHub Issues
- Trekker
- TODO and FIXME comments

## Your task

### Phase 1: Confirm what work items to consider

1. If the user specified what issue source they want you to focus on, this phase is done
2. If the user did not specify where potential work items can be found, use subagents to search
   for each of the potential sources mentioned above
3. Confirm with the user which sources you found and whether they should all be included in your
   analysis
4. Wait for the user's response

### Phase 2: Understand all work items

1. Use as many subagents as you need to read every potential work idea identified above
2. Use as many subagents as you need to explore all relevant code paths and documentation to
   understand and validate each potential work item and its relevance to the project's current
   and ideal future state
3. Proactively answer every question and follow-up question that occurs to you by exploring the
   codebase and anything else that would help you
4. If a potential work item seems stale or otherwise a poor fit for the current codebase and docs,
   use as many subagents as you need to proactively investigate whatever would help you and the user
   decide whether this work should be redefined, cancelled, etc
5. Wait for all subagents to return their results
6. Ensure you understand the results you have received and are equipped to compare their relative
   importance (explore specific areas of the codebase yourself if that will help you)
7. Once you understand each task and its present day validity, this phase is done

### Phase 3: Prioritize all work items

1. After thoroughly understanding all work ideas, rank them by their priority
2. When prioritizing, consider the cost of delay and ROI, and especially the relevance to any known
   near-term milestones
3. When you are clear how to rank the ideas, this phase is done

### Phase 4: Present your findings

1. Present the prioritized findings to the user, ensuring a summary table is included near the end
   of your response for clarity
2. Generate a self-contained HTML slide deck of the prioritized findings:
   - `mkdir -p .claude/reports`
   - Write the report to `.claude/reports/prioritized-work-items.html` — use clean, minimal styling,
     one slide per category plus a summary/title slide, and keyboard arrow-key and click navigation
     between slides
   - `open .claude/reports/prioritized-work-items.html`
3. Recommend a next action and wait for the user's response
