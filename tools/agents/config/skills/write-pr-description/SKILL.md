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
3. Take the ticket and any links from the ticket `create-pr` passes in, the branch name, the commits
   and the approved task. Run `gh issue list -R <owner>/<repo> --state open --limit 200` to find any
   GitHub issue the PR fully resolves. Inside "Working Through to a Draft PR", ask nothing: leave
   out what you can't find, say in the description that it is missing, and list it in `missing.txt`
   for `create-pr` to report. In an unattended run, ask nothing and leave out what you can't find
   without mentioning it. Otherwise, ask the user for what you can't find (Jira URL, Slack thread),
   and for a screen recording of a UI change.
4. For each screenshot or recording the proof cites, open it and check it shows what its claim
   says and nothing secret, then upload it as `use-gh` describes and use the returned URL. List a
   file in `missing.txt` only when its upload is refused, with the error.
5. Draft using voice rules below, and a title: one line, in plain words, saying what the PR
   changes.
6. Write the title, the body and any `missing.txt` to files in a new directory, and hand the
   directory's path back to the caller:
   1. Run `mktemp -d` and note the directory it prints. It is new on every run, so another
      session writing a PR body at the same time can't overwrite it.
   2. With the Write tool, write the title to `title.txt` and the body to `pr-body.md` in that
      directory. Writing them to files keeps the shell from mangling backticks in inline code.
      When step 3 left something out, write each missing item to `missing.txt`, one per line. Read
      them back before handing the path back.
   3. This skill does not open the PR. `create-pr` opens it with these files. To update an
      existing PR, run `gh pr edit <n> -R <owner>/<repo> --body-file <dir>/pr-body.md`.

**Self-check before handing the path back:**

- [ ] Read project PR template if exists
- [ ] Reviewed all commits and file changes from step 2's output (run in a later command, `BASE`
      is no longer set, so `git log $BASE..HEAD` would print nothing)
- [ ] Found the Jira/Slack links, or got them as step 3 describes
- [ ] Got a screen recording of a UI change as step 3 describes
- [ ] "Why" focuses on impact/outcome, and pre-empts the obvious reviewer question
- [ ] Verification is manual e2e only — no automated checks
- [ ] Why ends with one brief bullet linking the approach and design when the ticket records them,
  and no property number (P1…) appears anywhere
- [ ] The claims, steps and What I saw come from a `prove-it-works` report for the PR's head
- [ ] How to verify is Pre-merge's numbered list of collapsed rows (Setup, one per claim, Clean up),
  each claim opening to its Verification steps and then What I saw, with each step's code block
  indented to the step's text, and the body rendered through GitHub's markdown API and checked
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
- **How it was decided:** when the work's ticket records an approach or a design, Why ends with
  one bullet: a brief phrase saying why the change is built this way, then links to the approach
  and design comments, such as `- nginx sets the headers, so the policy ships and is tested with
  its code ([approach](…), [design](…))`. One phrase, never a summary of the comments. Leave it out
  when the ticket records neither.
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

### Verification

`## 👩‍🔬 How to verify` holds a short numbered list of collapsed rows, one per claim, so a reviewer
opens only the ones they want to check. Opening a row is a click, so rows are collapsed and nothing
inside a row is. When something can only be checked after a deploy, the list goes under
`### 🧪 Pre-merge` and those steps under `### 🚀 Post-merge`; with no post-merge steps, the list sits
directly under How to verify, with no Pre-merge heading. When every claim needs the deployed system,
there is no list, and Post-merge holds them all.

**What I saw is what running these exact steps showed.** A reviewer trusts each step because its
output is there, so What I saw holds output pasted from a run of the steps as written, never from
another run, another script or memory. Run every pre-merge step before the PR opens. A step that
fails as written is fixed and run again; a claim the run does not bear out is a finding to report,
never a description to write. A step that cannot run where the author works, such as one needing
a browser or another machine, says where it must run, and the user hears about it before the PR
opens.

**The proof comes from `prove-it-works`.** It decides the claims and the steps, as a reviewer who
doubts the change needs them, and this skill lays them out. Use its report for the PR's head
commit, with its claims, steps and saved output unchanged. When the session has no such report, or
the head has moved since, run `prove-it-works` on the PR first, passing the approach's properties
when the work has one and any steps the description already lists. Its steps that must run after a
deploy go under Post-merge. Where it names a binding property no claim shows, one line under How to
verify says in words what that property is and what covers it. Property numbers such as P1 are the
approach's shorthand and mean nothing to a reviewer, so a description never shows them. Where it
names a claim no signal shows, the user hears before drafting; inside "Working Through to a Draft
PR" or an unattended run, it also goes in `missing.txt`.

**Pre-merge is an ordered list,** so it lines up with the page's other lists and numbers itself.
Its items, in order:

1. **`🛠️ Setup`:** every step the claims share, grouped under `####` headings that each say what
   that part enables and which claims use it, such as `#### 📦 This branch's image (every claim)`.
   Leave it out when no claim needs setup.
2. **One item per claim.** Its summary is an emoji for the kind of evidence its What I saw
   holds, then the claim, stated as what is true after the change: 📄 for text output of any kind
   (a terminal, a browser console, a log), 📸 for a screenshot and 🎬 for a recording. Inside it:
   - **`#### 🔍 Verification steps`:** a `- [ ]` checklist, each item an action or an "Expect to
     see X" line, each building on the one before.
   - **`#### 👀 What I saw`:** what following those steps showed when the author ran them, so a
     reader can judge the claim without running anything. A sentence says what to look for, then
     comes the evidence: command output trimmed to the lines that differ, before and after, in a
     fenced block; console and log lines verbatim in a fenced block; a screenshot or recording
     uploaded as `use-gh` describes, with alt text saying what it shows.
3. **`🧹 Clean up`:** the steps that undo the setup. Leave it out with the setup.

**Markup that keeps it scannable:**

- Each item is `N. <details>`, with `<summary><b>…</b></summary>` on the next line, a blank line,
  and everything inside indented three spaces so it stays in the item.
- A code block that belongs to a step is indented two spaces more than the step's `- [ ]`, so it
  sits inside the step and lines up with the step's text. GitHub drops that indentation when the
  code is copied. A code block under What I saw stays at the item's indentation.
- Post-merge is a `- [ ]` checklist under its heading, not collapsed. With no post-merge steps,
  there is no Post-merge heading.
- Before handing the body back, render it with GitHub's markdown API, `gh api markdown --input
  <file>`, where the file holds `{"text": <body>, "mode": "gfm", "context": "<owner>/<repo>"}`.
  Confirm each `<details>` sits inside an `<li>`, each step's code block inside its
  `task-list-item`, and that no ` ``` ` shows as text.
- **Never link a local path.**

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
  the issue on merge (ooloth/hub#384 shows it). An issue the PR only relates to stays a
  bare URL
- In a repo whose `CLAUDE.md` or `AGENTS.md` says its PRs merge through `merge-and-verify`, a
  resolved issue is listed as `Resolves (closed by merge-and-verify once proven): #N` instead of
  `Fixes #N`, because a closing keyword closes the issue at merge, before any proof, and
  `merge-and-verify` closes it only on a proven verdict

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
❌ Verification steps that run or reference automated tests — CI already shows this; zero marginal
value to a reviewer

---

## Template Handling

1. **Project template first** — Use `.github/PULL_REQUEST_TEMPLATE.md` or
   `.github/pull_request_template.md` as base: its headings, their order and its emoji stand
2. **Extend it with what it lacks** — The verification layout goes inside the template's own
   verification section, under its heading. Each section this skill adds that the template has no
   equivalent for, such as How to verify or Related links when the template has only What and Why,
   goes after the template's sections. A section the template has and this skill doesn't stays

---

## Example

````markdown
> [!NOTE]
> Builds on #142 to leverage its frontend helpers

## ✅ What

- Adds an "Include archived items" toggle to all views, with a tooltip explaining what archived items are
- Hides completely (no tooltip either) when the current dataset has no archived items
- Since this toggle won't appear until datasets with archived items are in prod, it's safe to deploy backend and frontend together

### 🍿 Screen recording of verification steps below

[video]

## 🤔 Why

- New datasets introduce archived items for the first time and users need the option to hide them while building familiarity
- Defaulting them visible gives reviewers the full picture until users understand what they mean
- A toggle beside each view keeps an item's context while a user decides whether to hide it ([approach](https://jira.example.com/browse/PROJ-123?focusedCommentId=1001), [design](https://jira.example.com/browse/PROJ-123?focusedCommentId=1002))

## 👩‍🔬 How to verify

### 🧪 Pre-merge

1. <details>
   <summary><b>🛠️ Setup</b></summary>

   #### 💻 The app, with a dataset that has archived items (every claim)

   - [ ] Start the API and the frontend:

     ```sh
     ./bin/dev.sh
     cd frontend && npm start
     ```

   - [ ] Open `http://localhost:3000` and pick the "Sample orders" dataset

   </details>

2. <details>
   <summary><b>📸 The toggle appears only for a dataset with archived items</b></summary>

   #### 🔍 Verification steps

   - [ ] Pick the "Empty" dataset and expect to **not** see the "Include archived items" toggle
   - [ ] Pick "Sample orders" again and expect to see the toggle at the right end of the toolbar

   #### 👀 What I saw

   The toolbar with no archived items, then with them:

   ![The toolbar without the toggle, then with "Include archived items" at its right end](https://github.com/user-attachments/assets/…)

   </details>

3. <details>
   <summary><b>📸 Turning it off removes the archived item from every view</b></summary>

   #### 🔍 Verification steps

   - [ ] Query a few items, including one with the `[archived]` badge, and expect it in the list, detail view and charts
   - [ ] Toggle archived items off and expect its chip to be disabled, with a tooltip saying why
   - [ ] Expect the archived item to no longer appear in any view

   #### 👀 What I saw

   The item's chip is disabled and its tooltip says why:

   ![The archived item's disabled chip with its tooltip open](https://github.com/user-attachments/assets/…)

   </details>

4. <details>
   <summary><b>🧹 Clean up</b></summary>

   - [ ] Stop the API and the frontend with `Ctrl+C`

   </details>

### 🚀 Post-merge

- [ ] Once it deploys, open a production dataset with archived items and expect the toggle, on by default

## 🔖 Related links

- [Jira task: PROJ-123](https://jira.example.com/browse/PROJ-123)
- [Slack thread](https://workspace.slack.com/archives/C12345/p1234567890) discussing UX polish options with Sam
````
