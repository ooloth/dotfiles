---
name: write-pr-description
description: Voice guide for writing PR descriptions. Use this skill for ALL PR creation and updates (via gh CLI or editing existing PRs). Contains your specific voice rules, anti-patterns, examples, and workflow. Never write PR descriptions without invoking this skill first.
allowed-tools: [Bash, Read, Glob, Grep]
---

# Writing PR Descriptions

## Workflow

1. Check for project PR template: `.github/PULL_REQUEST_TEMPLATE.md` or `.github/pull_request_template.md`
2. Detect base branch and gather changes:
   ```bash
   BASE=$(gh pr view --json baseRefName -q .baseRefName 2>/dev/null || git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo main)
   git log $BASE..HEAD --oneline
   git diff $BASE...HEAD --stat
   ```
3. Ask user for: Jira URL, Slack thread, screen recording (if UI change)
4. Draft using voice rules below
5. Write body to `/tmp/pr-body.md`, then create the PR:

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

**Self-check before posting:**

- [ ] Read project PR template if exists
- [ ] Reviewed all commits: `git log $BASE..HEAD`
- [ ] Reviewed file changes: `git diff $BASE...HEAD --stat`
- [ ] Asked user for Jira/Slack links
- [ ] Asked user for screen recording (if UI change)
- [ ] "Why" focuses on impact/outcome, and pre-empts the obvious reviewer question
- [ ] Validation is manual e2e only — no automated checks
- [ ] No implementation details snuck in

---

## Voice Guide

### Spirit

1. **Respect reviewer time** — Get to the point, then stop
2. **User-centric framing** — What problem does this solve for users?
3. **Show, don't tell** — Screen recordings > paragraphs of text
4. **Approachable** — A new junior teammate should be able to easily understand all phrasing choices
5. **Clear** — A senior tech lead should find each "Why" bullet relevant and clarifying

### What & Why

- **What**: A single flat bullet list. First bullet is a single-sentence TL;DR of the entire change.
  Subsequent bullets call out worthwhile details (variants covered, notable constraints, deployment
  notes) without confusing the main point. The key facts reviewers should be aware are in the diff
  are clearly stated, especially changes that affect the system's observable side effects and
  measurable characteristics
- **Why**: First bullet is a single-sentence TL;DR of the entire reason. Subsequent bullets add
  detail if needed. Prefer writing at the level of impact and outcome rather than implementation
  where possible — explain why this change needed to exist and try to pre-emptively answer the key
  question a reviewer would ask before reading the diff in this case (e.g. "Didn't we already fix
  this?", "Why do we need this?", "Aren't there better ways to solve this problem?", etc happen.
  If it's not visible to users or reviewers, skip it.
- **Phrasing:** Do not write like an LLM. Write like a mentor teaching a Junior Engineer. Onboard
  as you describe. Use simple, unintimidating language a coworker just joining the project could
  follow. Assume concepts and terminology may be new to the reader. Empower someone new to the
  codebase to effectively review the PR because your phrasing made the change and its impact so
  easy to understand.

### Validation

- A single flat `- [ ]` checklist — no nested items, no prose paragraphs
- Steps must be sequential, each building on the previous so the list reads like a walkthrough, not
  a grab-bag of independent checks
- Write each item in "Expect to see X" tutorial style
- Include evidence-providing observability signals to confirm correct behavior; if gaps exist,
  point them out now
- Manual e2e only — NEVER reference automated checks ("run the tests", "run CI", "run lint/checks")
- **Reviewer-frame**: every step must be executable on a laptop, before merging, without deploying
  anywhere. "Local dev environment" means `localhost` — not a DEV, UAT, staging, or any other
  deployed environment. The question being answered is: "what would a skeptic demand I prove
  without running tests or deploying?" If a step requires a deployment first, cut it.
- **Pre-draft check**: before writing the checklist, ask — _if there were no test suite, how would I
  watch this behavior happen?_ That answer is the checklist.

### Structure

- Start with `> [!NOTE]` callout if PR depends on another PR
- Include 🍿 screen recording for ANY UI changes
- Mention deployment timing if backend/frontend coordination needed
- Link actual Jira/Slack (ask user if not provided)
- Task link text: `[Jira task: PROJ-123](url)`, `[Monday task: 12345678](url)`, or bare GitHub Issue
  URL (since GitHub auto-renders those with a preview)

### Anti-patterns

❌ Listing every file changed (the diff already communicates that)
❌ Listing every test written (again, the diff)
❌ "Comprehensive" descriptions — less is more  
❌ Technical jargon when plain language is available
❌ Placeholder links — ask for real URLs  
❌ Escaped inline code like `` `variable` `` — `variable` is nicer to read
❌ Validation steps that run or reference automated tests — CI already shows this; zero marginal value to a reviewer
❌ Any step requiring a deployment — to DEV, UAT, staging, or prod — all require merging first and cannot be run by a reviewer before approving

---

## Template Handling

1. **Project template first** — Use `.github/PULL_REQUEST_TEMPLATE.md` or `.github/pull_request_template.md` as base
2. **Respect conventions** — Match their emoji style (✅ not 💪)
3. **Enhance sparingly** — Add sections only if project template is minimal

---

## Example

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

- New datasets introduce archived items for the first time and users need the option to hide them while building familiarity
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
- [Slack thread](https://workspace.slack.com/archives/C12345/p1234567890) discussing UX polish options with Sam
```
