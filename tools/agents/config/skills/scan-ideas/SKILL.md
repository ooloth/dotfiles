---
name: scan-ideas
description: Rank every tracked issue and work item idea in the current project by cost of delay, and find the ones that are stale. Use when the user asks for the whole backlog ranked or cleaned up, not just for what to work on next.
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
- Work in flight: branches, open PRs, and commits not yet pushed
- Open question files, such as `docs/questions/`

The ranking rule is the one the `next` skill uses, in [../next/SKILL.md](../next/SKILL.md): cost of
delay decides, kind sets the default order, and the repo's own docs come first. Read that file
before Phase 1, and follow its notes on each tracker, such as invoking the matching `use-*` skill
and passing `--limit` to every list. This skill applies the rule to every item instead of the top
few, so the checks `next` runs only on its candidates run here on every item. `next`'s closing
offers do not apply here.

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
3. Investigate until you can say, for each item, whether it still applies to the current code and
   docs and how it compares with the others. For items that look stale, gather enough evidence to
   recommend redefining or cancelling them.

### Phase 3: Prioritize all work items

1. Rank every item that still applies by the rule in `../next/SKILL.md`, including its default
   order and the one-sentence reason any item needs to cross a kind boundary. Run every check in its
   "Before recommending" section on every item, so an item that waits on an unmade decision puts
   that decision at its rank
2. An item whose problem is gone has no cost of delay. It leaves the ranking and goes in the stale
   list, with the evidence and a recommendation to redefine or cancel it. So does everything else
   `next` reports for cleanup: a branch whose PR closed unmerged, a `status:agent-working` label
   whose PR is closed, and a question file nothing needs
3. An item with no kind label is ranked by the kind you propose for it, and also appears in a
   needs-a-kind list with that proposal. An item an agent is working on, by a
   `status:agent-working` label with its PR still open, goes in an in-progress list and is not
   ranked
4. When every item is in the ranking, the stale list or the in-progress list, this phase is done

### Phase 4: Present your findings

1. Present the prioritized findings to the user, ensuring a summary table is included near the end
   of your response for clarity. Show the stale, needs-a-kind and in-progress lists separately,
   each item with its evidence, so the user can overrule any of them
2. Generate a self-contained HTML slide deck of the prioritized findings:
   - `mkdir -p .outputs/<yyyy-mm-dd>`
   - Write the report to `.outputs/<yyyy-mm-dd>/prioritized-work-items.html` — use clean, minimal
     styling, one slide per kind in the default order plus one for each of the lists above and a
     summary/title slide, and keyboard arrow-key and click navigation between slides
   - `open .outputs/<yyyy-mm-dd>/prioritized-work-items.html`
3. Recommend a next action and wait for the user's response. Change nothing in any tracker until
   the user approves it
