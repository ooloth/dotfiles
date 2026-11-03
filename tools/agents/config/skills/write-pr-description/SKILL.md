---
name: write-pr-description
description: Voice guide for writing PR descriptions. Use this skill for every PR description. `create-pr` runs it when opening a PR, and it applies directly when editing an existing PR's description. Contains your specific voice rules, anti-patterns, examples, and workflow. Never write PR descriptions without invoking this skill first.
allowed-tools: [Bash, Read, Write, Glob, Grep]
---

# Writing PR Descriptions

## Workflow

1. Check for project PR template: `.github/PULL_REQUEST_TEMPLATE.md` or
   `.github/pull_request_template.md`
2. Detect base branch and gather changes:
   ```bash
   # Each fallback runs only when the step before it printed nothing. A `||` after a pipeline
   # would never fire, because the pipeline returns `sed`'s status, which is 0.
   BASE=$(gh pr view --json baseRefName -q .baseRefName 2>/dev/null)
   [ -n "$BASE" ] || BASE=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
   [ -n "$BASE" ] || BASE=main
   git log $BASE..HEAD --oneline
   git diff $BASE...HEAD --stat
   ```
3. Take the ticket and any links from the ticket `create-pr` passes in, the branch name, the
   commits and the approved task. Run `gh issue list -R <owner>/<repo> --state open --limit 200`
   to find any GitHub issue the PR fully resolves. Inside "Working Through to a Draft PR", ask
   nothing: leave out what you can't find and say in the description that it is missing. In an
   unattended run, ask nothing and leave out what you can't find without mentioning it. Otherwise,
   ask the user for what you can't find (Jira URL, Slack thread), and for a screen recording of a
   UI change.
4. Draft using voice rules below, and a title: one line, in plain words, saying what the PR
   changes.
5. Write the title and body to files in a new directory, and hand the directory's path back to the
   caller:
   1. Run `mktemp -d` and note the directory it prints. It is new on every run, so another
      session writing a PR body at the same time can't overwrite it.
   2. With the Write tool, write the title to `title.txt` and the body to `pr-body.md` in that
      directory. Writing them to files keeps the shell from mangling backticks in inline code.
      Read them back before handing the path back.
   3. This skill does not open the PR. `create-pr` opens it with these files. To update an
      existing PR, run `gh pr edit <n> --body-file <dir>/pr-body.md`.

**Self-check before handing the path back:**

- [ ] Read project PR template if exists
- [ ] Reviewed all commits: `git log $BASE..HEAD`
- [ ] Reviewed file changes: `git diff $BASE...HEAD --stat`
- [ ] Found the Jira/Slack links, or got them as step 3 describes
- [ ] Got a screen recording of a UI change as step 3 describes
- [ ] "Why" focuses on impact/outcome, and pre-empts the obvious reviewer question
- [ ] Validation is manual e2e only — no automated checks
- [ ] No implementation details snuck in
- [ ] No hard-wrapped prose: each paragraph and list item is one line, because GitHub renders every
  newline as a line break
- [ ] Diagram present only if the PR changes observable interactions, and it replaces prose or shows
  what prose cannot

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
- Include evidence-providing observability signals to confirm correct behavior. Where a step has no
  signal a reviewer could watch, tell the user before drafting, so the signal can be added to the
  code; the PR body does not list gaps. Inside "Working Through to a Draft PR" or an unattended run,
  name the gap in the caller's final report instead
- Manual e2e only — NEVER reference automated checks ("run the tests", "run CI", "run lint/checks")
- **Reviewer-frame**: every step must be executable on a laptop, before merging, without deploying
  anywhere. "Local dev environment" means `localhost` — not a DEV, UAT, staging, or any other
  deployed environment. The question being answered is: "what would a skeptic demand I prove
  without running tests or deploying?" If a step requires a deployment first, cut it.
- **Pre-draft check**: before writing the checklist, ask — _if there were no test suite, how would I
  watch this behavior happen?_ That answer is the checklist.
- Any commands the reviewer should run must be provided in a complete, copy-pastable form, not
  alluded to; assume the reviewer is unfamiliar and will not figure it out unless you provide it

### Structure

- Start with `> [!NOTE]` callout if PR depends on another PR
- Include 🍿 screen recording for ANY UI changes
- Mention deployment timing if backend/frontend coordination needed
- When the PR changes how parts of the system interact in a way a reviewer can
  observe, add a before and after diagram of that interaction under What, drawn
  to the diagram standards in `~/.agents/standards/documentation.md`. Most PRs
  have nothing to draw and include no diagram
- Link actual Jira/Slack, found or asked for as step 3 describes
- Task link text: `[Jira task: PROJ-123](url)`, `[Monday task: 12345678](url)`, or, for a GitHub
  issue the PR does not fully resolve, a bare issue URL (since GitHub auto-renders those with a
  preview). An issue the PR resolves gets `Fixes #N`, as the next item says
- A GitHub issue the PR fully resolves is listed under Related links as `Fixes #N`, one per line,
  not as a bare URL. A squash merge can take its commit message from the PR body, which drops the
  branch's own commits and every `Fixes` line in them, so only a closing keyword in the body closes
  the issue on merge (seen on ooloth/hub#384, 2026-10-28). An issue the PR only relates to stays a
  bare URL

### Anti-patterns

❌ Listing every file changed (the diff already communicates that)
❌ Listing every test written (again, the diff)
❌ "Comprehensive" descriptions — less is more  
❌ Technical jargon when plain language is available
❌ Placeholder links — link real URLs, or say which link is missing, except in an unattended run,
which leaves it out (see step 3)  
❌ Hard-wrapped prose — GitHub shows each newline as a line break, so a wrapped paragraph renders as
ragged short lines; write each paragraph and list item as one line
❌ Escaped inline code like `` `variable` `` — `variable` is nicer to read
❌ Validation steps that run or reference automated tests — CI already shows this; zero marginal
value to a reviewer
❌ Any step requiring a deployment — to DEV, UAT, staging, or prod — all require merging first and
cannot be run by a reviewer before approving

---

## Template Handling

1. **Project template first** — Use `.github/PULL_REQUEST_TEMPLATE.md` or
   `.github/pull_request_template.md` as base
2. **Respect conventions** — Match their emoji style (✅ not 💪)
3. **Enhance sparingly** — Add sections only if project template is minimal

---

## Example

```markdown
> [!NOTE]
> Builds on #142 to leverage its frontend helpers

## ✅ What

- Adds an "Include archived items" toggle to all views, with a tooltip explaining what archived items are
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
