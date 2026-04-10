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
5. Create PR: `gh pr create --draft --title "..." --body "..."`

---

## Voice Guide

### Spirit

1. **Respect reviewer time** - Get to the point, then stop
2. **User-centric framing** - What problem does this solve for users?
3. **Show, don't tell** - Screen recordings > paragraphs of text
4. **Practical validation** - Teach reviewers like a tutorial

### Conciseness Rules

- **What section**: Include every significant change theme - no cap. Could be 2 bullets, could be 8. Whatever fits the PR.
- **Why section**: 1-3 bullets (not a paragraph). Focus on user benefit.
- **Validation**: Narrative "Expect to..." style. Should be a numbered list of manual e2e testing steps and what evidence-providing observability signals to look for to confirm correct behavior. If there are gaps in the latter, point them out! Now is the time to fill those gaps. Should NEVER make reference to automated checks - these should be higher-confidence manual checks.

### Structure Requirements

- Start with `> [!NOTE]` callout if PR depends on another PR
- Include 🍿 screen recording for ANY UI changes
- Mention deployment timing if backend/frontend coordination needed
- Link actual Jira/Slack (ask user if not provided)

### Language Rules

- Concrete examples over jargon: "item with `_` separator" not "multi-entity composite perturbation"
- Frame "Why" around USER benefit, not technical constraints
- Validation reads like a tutorial: "Expect to see X"

### What NOT to Do

❌ Listing every file changed
❌ "Comprehensive" descriptions - less is more
❌ Checkbox-heavy validation sections
❌ Automated steps in "How to validate" — never "run the tests", "run CI", or "run lint/checks"; validation must be manual only (run the real thing e2e and expect to see X evidence of correct behavior)
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

- Adds an "Include archived items" toggle to filter archived entries in/out of all views
- Includes a tooltip explaining what "archived items" are
- Hides the toggle completely if the current dataset doesn't have archived items
- Since this toggle won't appear until datasets with archived items are in prod, it's safe to deploy backend and frontend together

### 🍿 Screen recording of validation steps below

[video]

## 🤔 Why

- This dataset is the first appearance of archived items in the app
- While users gain an understanding of how to interpret these items, we want them to have the ability to hide them

## 👩‍🔬 How to validate

1. `./bin/dev.sh` + `cd frontend` + `npm start`
2. Expect to **not** see the "Include archived items" toggle
3. Select a dataset with archived items
4. Expect to see the toggle now
5. Query a few items, including one that's archived (look for the `[archived]` badge)
6. Expect to see the archived item in the list, detail view, and charts
7. Toggle archived items off
8. Expect the archived item's chip to be disabled
9. Expect the disabled item's tooltip to explain why
10. Expect the archived item to no longer appear in your views

## 🔖 Related links

- [Jira task](https://jira.example.com/browse/PROJ-123)
- [Slack thread](https://workspace.slack.com/archives/C12345/p1234567890)
```

### Why This Works

✅ Dependency callout at top
✅ Screen recording before text
✅ Deployment timing mentioned
✅ User-centric Why
✅ Concrete language
✅ Narrative validation (10 steps)
✅ Real links (not placeholders)

---

## PR Creation Commands

```bash
# Check for related issues
gh issue list --state open

# Create draft PR
gh pr create --draft --title "Title" --body "$(cat <<'EOF'
[PR body here]
EOF
)"

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
