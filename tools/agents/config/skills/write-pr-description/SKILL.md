---
name: write-pr-description
description: Voice guide for writing PR descriptions. Use this skill for every PR description. `create-pr` runs it when opening a PR, and it applies directly when editing an existing PR's description. Contains your specific voice rules, anti-patterns, examples, and workflow. Never write PR descriptions without invoking this skill first.
allowed-tools: [Bash, Read, Write, Glob, Grep]
---

# Writing PR Descriptions

## Workflow

1. Detect base branch and gather changes:
   ```bash
   # Each fallback runs only when the step before it printed nothing. A `||` after a pipeline
   # would never fire, because the pipeline returns `sed`'s status, which is 0.
   BASE=$(gh pr view --json baseRefName -q .baseRefName 2>/dev/null)
   [ -n "$BASE" ] || BASE=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
   [ -n "$BASE" ] || BASE=main
   git log $BASE..HEAD --oneline
   git diff $BASE...HEAD --stat
   ```
2. Take the ticket and any links from the ticket `create-pr` passes in, the branch name, the commits
   and the approved task. Run `gh issue list -R <owner>/<repo> --state open --limit 200` to find any
   GitHub issue the PR fully resolves. Inside "Working Through to a Draft PR", ask nothing: leave
   out what you can't find, say in the description that it is missing, and list it in `missing.txt`
   for `create-pr` to report. In an unattended run, ask nothing and leave out what you can't find
   without mentioning it. Otherwise, ask the user for what you can't find (Jira URL, Slack thread),
   and for a screen recording of a UI change.
3. For each screenshot or recording the proof cites, open it and check it shows what its claim
   says and nothing secret, then upload it as `use-gh` describes and use the returned URL. List a
   file in `missing.txt` only when its upload is refused, with the error.
4. Draft using voice rules below, and a title: one line, in plain words, saying what the PR
   changes.
5. Write the title, the body and any `missing.txt` to files in a new directory, and hand the
   directory's path back to the caller:
   1. Run `mktemp -d` and note the directory it prints. It is new on every run, so another
      session writing a PR body at the same time can't overwrite it.
   2. With the Write tool, write the title to `title.txt` and the body to `pr-body.md` in that
      directory. Writing them to files keeps the shell from mangling backticks in inline code.
      When step 2 left something out, write each missing item to `missing.txt`, one per line. Read
      them back before handing the path back.
   3. Run `uv run <this skill's folder>/scripts/check_pr_body.py <dir>/pr-body.md --repo
      <owner>/<repo>` and fix every problem it prints, running it again until it exits 0. Exit 1
      lists what to fix; exit 2 means a check could not run, which is never a pass. Updating an
      existing PR, save its live body when you read it and add `--live-copy <saved file> --pr <n>`,
      so a change someone made since then is merged, not overwritten. When `prove-it-works` saved
      the commands it ran, add `--commands <that file>`, so every step shown is one that ran.
   4. This skill does not open the PR. `create-pr` opens it with these files, and updating an
      existing PR's title and body goes through `create-pr` too. To change only the body, as when
      fixing its layout, run `gh pr edit <n> -R <owner>/<repo> --body-file <dir>/pr-body.md`.

**Self-check before handing the path back:**

- [ ] Reviewed all commits and file changes from step 1's output (run in a later command, `BASE`
      is no longer set, so `git log $BASE..HEAD` would print nothing)
- [ ] Found the Jira/Slack links, or got them as step 2 describes
- [ ] Got a screen recording of a UI change as step 2 describes
- [ ] "Why" focuses on impact/outcome, and pre-empts the obvious reviewer question
- [ ] What ends with the "See <ticket ID> for detailed explanations…" bullet when the ticket records
  an approach or a design, and holds no code block
- [ ] How to verify's rows are the design's Observable behaviour rows, proven as Proven by
  describes, with no unplanned row and no property number (P1…)
- [ ] The outline is Setup, What's new, What stays the same, Clean up and After merge, each part
  present only when it has something, with every row collapsed and nothing inside a row collapsed
- [ ] Each row has Proven by, Verification steps and What I saw as headings with lists, except a 🧪
  row or a row whose run waits under After merge, which has only Proven by, and the Setup, Clean up
  and After merge rows; its What I saw holds only output from running its own steps
- [ ] The body was rendered through GitHub's markdown API and checked
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
- **The last What bullet links the decision records:** when the ticket records an approach or a
  design, What ends with exactly `- See <ticket ID> for detailed explanations of this solution's
  overall approach and design`, with "approach" and "design" each linked to its ticket comment.
  Link only a comment that exists, and leave the bullet out when neither does.
- **Why**: First bullet is a single-sentence TL;DR of the entire reason. Subsequent bullets add
  detail if needed. Prefer writing at the level of impact and outcome rather than implementation
  where possible — explain why this change needed to exist and try to pre-emptively answer the key
  question a reviewer would ask before reading the diff in this case, such as "Didn't we already
  fix this?", "Why do we need this?" or "Aren't there better ways to solve this problem?".
  If it's not visible to users or reviewers, skip it.
- **Phrasing:** Do not write like an LLM. Write like a mentor teaching a Junior Engineer. Onboard
  as you describe. Use simple, unintimidating language a coworker just joining the project could
  follow. Assume concepts and terminology may be new to the reader. Empower someone new to the
  codebase to effectively review the PR because your phrasing made the change and its impact so
  easy to understand.

### Verification

`## 👩‍🔬 How to verify` is where a reviewer who doubts the change checks it for themselves. What
describes the change from the inside, the code and records it adds. How to verify describes it from
the outside: every behaviour of the running system the PR changes or must keep, each with the proof
that it holds. Read together, the two let a reviewer approve without having been there.

**The shape, and why.** A reviewer first sees a short numbered outline. Each behaviour is one
collapsed row, so the outline alone is a complete, scannable list of what the PR does to the
running system, and the reviewer opens only the rows they want to check. Opening a row is a click,
so only the rows are collapsed and nothing inside a row is. The outline, in this order:

1. **`🛠️ Setup`:** every step the rows share, grouped under `####` headings that each say what that
   part enables and which rows use it. Left out when no row needs setup.
2. **`✨ What's new`:** a bold label, not collapsed, followed by one collapsed row per behaviour the
   PR adds or changes. The behaviour the PR exists for comes first.
3. **`🟰 What stays the same`:** a bold label followed by one collapsed row per nearby behaviour
   users rely on that the PR must not change. Left out when there is none.
4. **`🧹 Clean up`:** the steps that undo the setup. Left out with the setup.
5. **`🚀 After merge`:** the steps that can only run on a deployed system, with where and when.
   Left out when there are none. It is the last collapsed row, not a section of its own, and there
   is no Pre-merge heading.

**Where the rows come from.** The rows are the design's Observable behaviour table, in its words and
order: its `New` rows under What's new and its `Unchanged` rows under What stays the same. The
design was approved before the code was written, so the PR shows the plan the reviewer can hold the
code to, and this skill never invents, drops or rewords a row's behaviour. `prove-it-works` takes
each row as a claim, proves it, and hands back the steps it ran and their output: use its report for
the PR's head commit, and when the session has none, or the head has moved since, run
`prove-it-works` on the PR first, with the design's Observable behaviour table. Work with no design
gets
its Observable behaviour table from the `design` skill before the PR opens, since that table is the
only source of rows. A row covers one behaviour a user or operator would notice; a finer point, such
as a format detail or a speed bound, goes inside the row whose behaviour it refines. Nothing that
isn't behaviour of the running system, such as a doc pointer or a code comment, is a row: it belongs
in What. A property number such as P1 is the approach's shorthand and never appears.

**A change nobody planned is never a row.** When a run finds behaviour the design didn't list, it is
either a bug, which stops the PR until it is fixed and run again, or behaviour the change should
have, which the design gains through a change comment on the ticket before it becomes an ordinary
row. The user hears about each one before the PR opens.

**A planned row that doesn't hold stops the PR.** A row `prove-it-works` disproves is a bug, which
stops the PR until it is fixed and run again. A row it rates not observable is proven by the tests,
types or assertions that cover it at the head commit, as a 🧪 row, and with none it stops the PR
like a disproven row. When a row's proof differs from the design's plan,
because a planned test, type or assertion doesn't exist at the head commit or a planned run did not
hold, the user hears about it before the PR opens.

**Inside a row,** in this order, each a `####` heading with a blank line above it:

- **`#### 🧾 Proven by`:** a bullet list of what proves the behaviour at the head commit, not what
  the design planned: the run below, when `prove-it-works` proved the row by running it, and each
  named test CI runs, type, runtime assertion or CI check that exists at the head commit and covers
  the row. A row only a deployed system can show names the run under After merge instead of the run
  below. A planned proof that doesn't exist there, or a run that did not hold, is left out. Every
  entry is a bullet.
- **`#### 🔍 Verification steps`:** a `- [ ]` checklist a reviewer can follow from a fresh
  checkout, each item an action or an "Expect to see X" line, each building on the one before.
  Left out, with What I saw, in a 🧪 row, whose behaviour can't be seen from outside.
- **`#### 👀 What I saw`:** what running exactly those steps showed. A reviewer trusts a step
  because its output is here, so this holds only output pasted from that run, never from another
  run, another script or memory. Text goes in a list, numbered for a sequence and bulleted
  otherwise, with each output block under the item it supports. A screenshot or recording is
  uploaded as `use-gh` describes, with alt text saying what it shows.

**A row's summary** is an emoji for the kind of evidence the row holds, then the behaviour in
plain words, stated as what is true after the change, in plain text with `<code>…</code>` for code
and values: 📄 for text output of any kind (a terminal, a browser console, a log), 📸 for a
screenshot, 🎬 for a recording, and 🧪 for a behaviour shown only by tests. Setup, Clean up and
After merge are the rows whose summaries are bold.

**Where evidence goes.** All of it goes in the What I saw of the row it proves, and nowhere else:
not in What, not in Why, not in a section of its own. Evidence that proves two rows is two runs, one
in each. An earlier run that the steps don't reproduce, such as an ad hoc script, is either turned
into steps of the row it proves and run again, or left out.

**Judgement across PRs.** Every PR gets the same outline, so a reviewer learns it once.

- Earlier evidence stays in a row only when the row's steps and everything the row depends on are
  unchanged since that run, and the row says which commit it came from. Otherwise the row runs
  again at the head.
- A change to the shared Setup runs every row that uses it again.
- Setup holds what two or more rows share. Setup only one row needs stays in that row's steps.
- A row that builds the artifact a reviewer would run, such as an image, runs the system, not the
  test suite, so it is an ordinary row.

- A PR that only fixes docs or comments changes no behaviour: it has What stays the same rows, or
  none, and How to verify says in one line why.
- A PR whose behaviour shows only on a live system puts its steps under After merge, and each such
  row's Proven by names the run under After merge.
- A behaviour covered only by tests is still a row, a 🧪 one, so the outline stays complete. Its
  Proven by names the test and the CI check that ran it at the head commit, and it has no
  Verification steps and no What I saw, since CI already shows that result.
- A row whose steps need a browser, another machine or credentials says so, and the user hears it
  before the PR opens.

**Markup that keeps it readable:**

- The outline is an ordered list. `1. <details>` starts a row at the top level, and each grouped row
  is a nested item, `   1. <details>`, under its label. Everything inside a row is indented to the
  row's text, with `<summary>…</summary>` on the next line and a blank line after it.
- A row numbered 10 or higher has its text one column further right than one numbered 9, so
  everything inside it is indented one more space.
- A code block that belongs to a step is indented to the step's text, so it sits inside the step,
  and every line inside it is indented exactly as its fence. A line indented less ends the step and
  leaves the block empty. GitHub drops the indentation when the code is copied.
- What holds no code block: one makes GitHub space out every bullet in the list.
- **Never link a local path, or put one in a step's command.** A path on your machine, such as your
  home folder or a `mktemp -d` folder, is one no reviewer has.
- Nested markup breaks in ways that look fine in the source: a code block that renders empty, a
  row pushed inside the row above it, a summary turned into a bullet, a row whose summary falls out
  of it. So the body is never posted until `check_pr_body.py` passes, as step 5 says. It renders
  the body through GitHub's markdown API and checks the markup rules in this section, no code
  block in What, at least one bullet and only bullets under Proven by, no property number, no local
  path in a step's code block and no Pre-merge heading. Nothing checks hard wrapping, the outline's
  order or a row's three headings, so read the body for those.

### Structure

- A PR that must merge before or after another PR starts with a `> [!IMPORTANT]` callout giving
  the merge order of the whole set, linking every other PR in it, and saying what breaks if the
  order is not followed. A PR in the set that is not open yet is named by what it does, and once
  it opens, its link is added to the callout of every PR in the set. A PR that only builds on
  another's code, with no order to follow, uses a `> [!NOTE]` instead
- A UI change is shown by a 📸 or 🎬 row, its screenshot or recording in that row's What I saw
- Mention deployment timing if backend/frontend coordination needed
- When the PR changes how parts of the system interact in a way a reviewer can
  observe, add a before and after diagram of that interaction under What, drawn
  to the diagram standards in `~/.agents/standards/documentation.md`. Most PRs
  have nothing to draw and include no diagram
- Link actual Jira/Slack, found or asked for as step 2 describes
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
  `merge-and-verify` closes it only after its proof, on its own close conditions or the user's
  choice

### Anti-patterns

❌ Listing every file changed (the diff already communicates that)
❌ Listing every test written (again, the diff)
❌ "Comprehensive" descriptions — less is more  
❌ Technical jargon when plain language is available
❌ Placeholder links — link real URLs, or say which link is missing, except in an unattended run,
which leaves it out (see step 2)  
❌ Hard-wrapped prose — GitHub shows each newline as a line break, so a wrapped paragraph renders as
ragged short lines; write each paragraph and list item as one line
❌ Escaped inline code like `` `variable` `` — `variable` is nicer to read
❌ Verification steps that run the test suite or CI — CI already shows this; a behaviour covered
only by tests is a 🧪 row whose Proven by names the test

---

## Template Handling

This skill's template is the only one used: its sections, their order and its emoji, whatever PR
template the project keeps in `.github/`. A reviewer then meets the same outline on every PR these
skills open, in any repo.

---

## Example

````markdown
> [!IMPORTANT]
> **Merge order:** merge #142 first, then this PR. This PR uses #142's frontend helpers, so it fails to build if it merges first.

## ✅ What

- Adds an "Include archived items" toggle to all views, with a tooltip explaining what archived items are
- Hides completely (no tooltip either) when the current dataset has no archived items
- Since this toggle won't appear until datasets with archived items are in prod, it's safe to deploy backend and frontend together
- See PROJ-123 for detailed explanations of this solution's overall [approach](https://jira.example.com/browse/PROJ-123?focusedCommentId=1001) and [design](https://jira.example.com/browse/PROJ-123?focusedCommentId=1002)

## 🤔 Why

- New datasets introduce archived items for the first time and users need the option to hide them while building familiarity
- Defaulting them visible gives reviewers the full picture until users understand what they mean

## 👩‍🔬 How to verify

1. <details>
   <summary><b>🛠️ Setup</b></summary>

   #### 💻 The app, with a dataset that has archived items (every row)

   - [ ] Start the API and the frontend:

     ```sh
     ./bin/dev.sh
     cd frontend && npm start
     ```

   - [ ] Open `http://localhost:3000` and pick the "Sample orders" dataset

   </details>

2. **✨ What's new**

   1. <details>
      <summary>📸 The "Include archived items" toggle appears for a dataset that has archived items</summary>

      #### 🧾 Proven by

      - The run below
      - In CI, `test_toggle_shows_only_with_archived_items`

      #### 🔍 Verification steps

      - [ ] Expect the toggle at the right end of the toolbar

      #### 👀 What I saw

      - The toolbar, with "Include archived items" at its right end:

        ![The toolbar with the "Include archived items" toggle at its right end](https://github.com/user-attachments/assets/…)

      </details>

   2. <details>
      <summary>📸 Turning the toggle off removes archived items from every view</summary>

      #### 🧾 Proven by

      - The run below

      #### 🔍 Verification steps

      - [ ] Query a few items, including one with the `[archived]` badge, and expect it in the list, detail view and charts
      - [ ] Turn the toggle off and expect its chip to be disabled, with a tooltip saying why
      - [ ] Expect the archived item to no longer appear in any view

      #### 👀 What I saw

      - The archived item's chip, disabled, with its tooltip open:

        ![The archived item's disabled chip with its tooltip open](https://github.com/user-attachments/assets/…)

      </details>

3. **🟰 What stays the same**

   1. <details>
      <summary>📸 A dataset with no archived items shows the same toolbar as before</summary>

      #### 🧾 Proven by

      - The run below

      #### 🔍 Verification steps

      - [ ] Pick the "Empty" dataset and expect no "Include archived items" toggle

      #### 👀 What I saw

      - The toolbar, unchanged, with no toggle:

        ![The toolbar for a dataset with no archived items, with no toggle](https://github.com/user-attachments/assets/…)

      </details>

4. <details>
   <summary><b>🧹 Clean up</b></summary>

   - [ ] Stop the API and the frontend with `Ctrl+C`

   </details>

5. <details>
   <summary><b>🚀 After merge</b></summary>

   - [ ] Once it deploys, open a production dataset with archived items and expect the toggle, on by default

   </details>

## 🔖 Related links

- [Jira task: PROJ-123](https://jira.example.com/browse/PROJ-123)
- [Slack thread](https://workspace.slack.com/archives/C12345/p1234567890) discussing UX polish options with Alice
````
