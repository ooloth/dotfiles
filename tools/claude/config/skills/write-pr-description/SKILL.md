---
name: write-pr-description
description: Voice guide for writing PR descriptions. Use this skill for ALL PR creation and updates (via gh CLI or editing existing PRs). Contains your specific voice rules, anti-patterns, examples, and workflow. Never write PR descriptions without invoking this skill first.
allowed-tools: [Bash, Read, Glob, Grep]
---

# Writing PR Descriptions

## ⚡ QUICK START

1. Check for project PR template: `.github/PULL_REQUEST_TEMPLATE.md`
2. Gather changes: `git log main..HEAD --oneline` and `git diff main...HEAD --stat`
3. Ask user for: Jira URL, Slack thread, screen recording (if UI)
4. Draft using voice rules below
5. Write body to `/tmp/pr-body.md`, then: `gh pr create --draft --title "..." --body-file /tmp/pr-body.md`

---

## Voice Guide

### Spirit

1. **Respect reviewer time** - Get to the point, then stop
2. **User-centric framing** - What problem does this solve for users?
3. **Show, don't tell** - Screen recordings > paragraphs of text
4. **Practical validation** - Teach reviewers like a tutorial
5. **Approachable** - A new junior teammate should be able to easily understand all "What" and "Why" phrasing choices
6. **Clear** - A senior tech lead teammate should find each "Why" bullet relevant and clarifying

### Conciseness Rules

- **What section**: First bullet is a single-sentence TL;DR of the entire change. Subsequent bullets call out worthwhile details (variants covered, notable constraints, deployment notes). No cap on total — whatever fits the PR.
- **Why section**: First bullet is a single-sentence TL;DR of the entire reason. Subsequent bullets add detail if needed (1-3 total, not a paragraph). Focus on user benefit.
- **Validation**: A single flat `- [ ]` checklist — no nested items, no prose paragraphs. Steps must be sequential, each building on the previous so the list reads like a walkthrough, not a grab-bag of independent checks. Write each item in "Expect to see X" tutorial style. Include evidence-providing observability signals to confirm correct behavior; if gaps exist, point them out now. NEVER reference automated checks — manual e2e only.

### Structure Requirements

- Start with `> [!NOTE]` callout if PR depends on another PR
- Include 🍿 screen recording for ANY UI changes
- Mention deployment timing if backend/frontend coordination needed
- Link actual Jira/Slack (ask user if not provided)
- Task link text: `[Jira task: PROJ-123](url)`, `[Monday task: 12345678](url)`, or bare GitHub Issue URL (GitHub auto-renders those with a preview)

### Language Rules

- Concrete examples over jargon: "item with `_` separator" not "multi-entity composite perturbation"
- Frame "Why" around USER benefit, not technical constraints
- Validation reads like a tutorial: "Expect to see X"

### What NOT to Do

❌ Listing every file changed
❌ "Comprehensive" descriptions - less is more
❌ Automated steps in "How to validate" — never "run the tests", "run CI", or "run lint/checks"; validation must be manual only (run the real thing e2e and expect to see X evidence of correct behavior)
❌ Prose paragraphs in "How to validate" — every step must be its own `- [ ]` checkbox item
❌ Nested lists in "How to validate" — keep it a single flat list
❌ Technical jargon when plain language works
❌ Business rule explanations (put in code comments)
❌ Placeholder links - ask for real URLs
❌ Escaped inline code like `variable` - `variable` is nicer to read

### Scope Discipline

- Focus on the FEATURE users will see
- Omit implementation wiring (threading params, type updates)
- If it's not visible to users or reviewers, skip it

---

## Template Handling

1. **Project template first** - Use `.github/PULL_REQUEST_TEMPLATE.md` or `.github/pull_request_template.md` as base
2. **Respect conventions** - Match their emoji style (✅ not 💪)
3. **Enhance sparingly** - Add sections only if project template is minimal

---

## Example: Good PR Description

```markdown
> [!NOTE]
> Builds on #142 to leverage its frontend helpers

## ✅ What

- Adds an "Include archived items" toggle to all views — hidden when the dataset has none, with a tooltip explaining the concept
- Hides completely (no tooltip either) when the current dataset has no archived items
- Since this toggle won't appear until datasets with archived items are in prod, it's safe to deploy backend and frontend together

### 🍿 Screen recording of validation steps below

[video]

## 🤔 Why

- New datasets introduce archived items for the first time, and users need the option to hide them while building familiarity
- Defaulting them visible gives reviewers the full picture until users understand what they mean

## 👩‍🔬 How to validate

- [ ] `./bin/dev.sh` + `cd frontend` + `npm start`
- [ ] Expect to **not** see the "Include archived items" toggle
- [ ] Select a dataset with archived items
- [ ] Expect to see the toggle now
- [ ] Query a few items, including one that's archived (look for the `[archived]` badge)
- [ ] Expect to see the archived item in the list, detail view, and charts
- [ ] Toggle archived items off
- [ ] Expect the archived item's chip to be disabled
- [ ] Expect the disabled item's tooltip to explain why
- [ ] Expect the archived item to no longer appear in your views

## 🔖 Related links

- [Jira task: PROJ-123](https://jira.example.com/browse/PROJ-123)
- [Slack thread](https://workspace.slack.com/archives/C12345/p1234567890)
```

### Why This Works

✅ Dependency callout at top
✅ Screen recording before text
✅ Deployment timing mentioned
✅ First What bullet summarises the entire change in one sentence
✅ First Why bullet summarises the entire reason in one sentence
✅ User-centric Why
✅ Concrete language
✅ Flat `- [ ]` checklist validation (10 steps, no nesting, no prose)
✅ Real links (not placeholders)

---

## PR Creation Commands

```bash
# Check for related issues
gh issue list --state open

# Write body to a file first — avoids escaped backticks mangling inline code in the GitHub UI
cat > /tmp/pr-body.md << 'EOF'
[PR body here]
EOF

# Create draft PR
gh pr create --draft --title "Title" --body-file /tmp/pr-body.md

# View PR
gh pr view --web
```

---

## Process Checklist

- [ ] Read project PR template if exists
- [ ] Review all commits: `git log main..HEAD`
- [ ] Review file changes: `git diff main...HEAD --stat`
- [ ] Ask user for Jira/Slack links
- [ ] Ask user for screen recording (if UI change)
- [ ] Draft description using voice rules
- [ ] Check: Is "Why" user-centric?
- [ ] Check: Validation all manual e2e testing and evidence observation (e.g. UI, logs)?
- [ ] Check: No implementation details?
- [ ] Create draft PR via `gh pr create --draft`
- [ ] Return PR URL to user
