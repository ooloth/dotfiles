---
name: review-code
description: Standalone code review for any scope — PR number, branch, file paths, or current changes. Synthesizes intent, runs 12 parallel specialized agents, and presents actionable findings with a verdict. A dependency update (Dependabot, Renovate, any lockfile change) gets a check of each release it adopts instead. For PR scope, optionally posts the review to GitHub with inline comments.
argument-hint: '[pr number, branch name, file paths, or nothing for current branch]'
allowed-tools: Bash Read Grep Glob
effort: high
model: opus
---

## Step 1: Determine scope

Identify what to review and the exact diff command to pass agents.

| Argument                      | File list                                       | Diff command                             |
| ----------------------------- | ----------------------------------------------- | ---------------------------------------- |
| PR number or URL              | `gh pr diff <n> -R <owner>/<repo> --name-only` | `gh pr diff <n> -R <owner>/<repo>`       |
| Branch name                   | `git diff <branch>...HEAD --name-only`          | `git diff <branch>...HEAD`               |
| File path(s)                  | use provided paths                              | `git diff HEAD -- <files>`               |
| None, on feature branch       | `git diff main...HEAD --name-only`              | `git diff main...HEAD`                   |
| None, on main, staged         | `git diff --staged --name-only`                 | `git diff --staged`                      |
| None, on main, nothing staged | —                                               | ask: "What would you like me to review?" |

Substitute the actual base ref (main, master, trunk) where needed. Detect the current branch with
`git symbolic-ref --short HEAD`. Every `gh` command in this skill names its repository with `-R` (or
`--repo`), so it cannot act on a same-numbered PR or issue in whatever repo the shell is in.

**Skip non-reviewable files:**

- package-lock.json, \*.lock, yarn.lock, Gemfile.lock
- Generated code (_.generated._, \*\_pb2.py, etc.)
- Test snapshots (**snapshots**/\*)
- Vendored dependencies (vendor/, node_modules/ if committed)
- Binary files
- Formatting-only changes (whitespace/style only)

**For PR scope — fetch PR context before Step 2:**

```bash
gh pr view <n> -R <owner>/<repo> --json title,body,number
```

Store the title and body for use in Step 2. Store the PR number for Step 5.

**For PR scope, also fetch what earlier reviewers said:**

```bash
uv run <skill-base-dir>/../review-pr-comments-converge/scripts/fetch_pr_comments.py <n> --repo <owner>/<repo>
```

It prints every review, every inline thread with its replies, and every PR conversation comment,
which is where some bots post their reviews. A default `gh pr view` shows none of these. Keep the
output in this session for Step 4 and out of every agent's prompt and the Step 2 intent block: an
agent handed an earlier verdict tends to return it confirmed, and the point of this review is a
read that isn't anchored on anyone else's. The one exception is a dry run that CI posted, which
Step 2 carries to the agents.

Output the reviewable file list and diff command before proceeding. When the skip rules leave
nothing because every changed file is a lockfile or package manifest, say so and name those files
as going to Step 1a.

**A dependency update takes Step 1a.** When the changed files include a lockfile or a package
manifest (`package.json`, `pyproject.toml`, `Cargo.toml` and the like), run Step 1a. If those are
the only files changed and the PR only changes the versions of dependencies already present, Step
1a replaces Steps 2 to 3.5 and you continue at Step 4. If the PR adds a direct dependency (a name
new to a manifest's dependency lists), also run Step 2, because whether a dependency earns its place
depends on what the change is for. If other files changed too, review those through Steps 2 to 3.5
as usual. Either way, bring Step 1a's findings into Step 4 alongside anything else found.

## Step 1a: Dependency updates

A lockfile is skipped above because nobody reads one line by line, not because it carries no risk.
The risk is in the releases the update adopts, and no diff shows them. A release can be malicious
(a compromised maintainer account, an install script that steals the credentials on a developer
machine or CI runner), and a matching lockfile hash says nothing about that: it proves only that the
lockfile agrees with the registry. This applies to dev dependencies as much as to runtime ones,
because install scripts run wherever the package is installed.

1. **Run the check for npm and uv lockfiles.** Skip this when no `package-lock.json` or `uv.lock`
   changed; the script would only exit 2 to say there is nothing for it to check. It reads
   everything through `gh`, the registries and OSV, so it runs from any directory.

   ```bash
   uv run <skill-base-dir>/scripts/review_dependency_bump.py <pr-number> --repo <owner>/<repo>
   ```

   It compares each changed lockfile at the merge base and the PR head, and lists every entry
   that changed. For each bumped npm package it checks the hash against the registry, the resolved
   host, the publisher, install scripts, new dependencies, `engines`, provenance and publish age;
   `npm ls` checks every parent's range. For each bumped PyPI package it checks every locked file's
   hash, the registry source, the publisher its attestations name, new requirements,
   `requires_python`, yanked files, whether a wheel is still locked and upload age, and that every
   package depending on it still allows the new version. A package locked from an index other than
   PyPI is flagged `unchecked`, because the script never contacts a project's own index. `npm audit`
   or `uv audit` on both sides lists the advisories fixed, introduced and left in place. Exit 0
   means nothing is flagged, 1 means something is, and 2 means the check could not run. On 2,
   stderr says why: fix that, or do the checks by hand. Never read exit 2 as clean.

2. **Check other lockfiles by hand.** The script flags each one it cannot read as `unchecked`. Do
   the same checks against that ecosystem's registry: each locked hash, the publisher, new
   dependencies, install-time code, and publish age.

3. **Judge what a lookup cannot:**
   - **Every flag.** For a flagged release, read what changed in the published package, which is
     not the same as its repository. For npm, `npm diff --diff=<name>@<old> --diff=<name>@<new>`.
     For PyPI, download both releases' sdists from the URLs in the lockfile into a `mktemp -d`
     directory, unpack them, and diff the two trees. Look for code that runs on install or
     import and reaches the network, the environment, credentials or files outside the package.
     Facts the script reports without a flag are not findings. Provenance absent on both releases,
     for one, is common and changes nothing; only a release that drops provenance its predecessor
     had is flagged.
   - **A new direct dependency.** Judge it against the Must in
     `~/.agents/standards/dependencies.md`: what it covers, whether the standard library or an
     existing dependency already covers it, and the transitive tree it brings in, which the
     script's `added-entry` lines list.
   - **A major bump, or any bump of a runtime dependency.** A runtime dependency is one the
     running app loads, which the script marks with a heading without `(dev)`. Read the
     release notes in the PR body first, then the changelog between the two versions, and find
     where the repo imports the package, to judge whether a breaking change reaches this code. A
     package the repo never imports reaches it through the packages that depend on it, so look at
     how they use it.
   - **CI.** The check neither builds nor tests. Read the PR's check results
     (`gh pr checks <n> -R <owner>/<repo>`). A failing check rules out Approve. Name a skipped or
     pending check in the "Looks Good" line, so the reader knows the Approve did not rest on it.
   - **Tests CI may not have run.** When you cannot tell from the checks whether the tests ran
     against the new version, run the tests that exercise the bumped package yourself, in a copy
     of the PR head that touches no checkout:

     ```bash
     dir="$(mktemp -d)" && gh api repos/<owner>/<repo>/tarball/<head-sha> > "$dir/src.tar.gz" \
       && mkdir "$dir/src" && tar -xzf "$dir/src.tar.gz" -C "$dir/src" --strip-components=1
     ```

     Install and test inside `$dir/src` with the project's own commands. Never fetch, check out or
     add a worktree in the reviewed repository: a review only reads.

4. **Report in Step 4's format.** A flag that survives step 3 is a finding. Anchor it on the
   lockfile line of that entry's `version`, which is in the diff. A clean run is the evidence for
   an Approve. For this path, "Looks Good" may be a short list rather than one sentence: one item
   per check that ran, with what it found, so a reader can see what the Approve rests on.

## Step 2: Synthesize intent

Build a context block that every agent receives. Gather from these sources in priority order:

1. **PR title and body** — from Step 1 fetch (if PR scope)
2. **Linked tickets, body and every comment** — any ticket the PR body, branch name or commit
   messages reference, on whatever tracker holds it (GitHub, Jira, Linear). Read the body and all
   of its comments, not the body alone: the approach, the design and any later change are usually
   recorded in comments, and a default read omits them. GitHub:
   `gh issue view <n> -R <owner>/<repo> --json title,body,comments`. Jira: invoke `use-jira` and
   request the `comment` field.
3. **Decision records the PR, its tickets or the diff cite** — each cited record in full
   (`DECISIONS.md` entries, ADRs, `docs/decisions/`), read at the PR's head commit, including any
   record the diff amends. Carry its decision, rejected options and revisit triggers into Recorded
   decisions.
4. **Commit messages** — `git log <base>...HEAD --format="%s%n%b"`
5. **The diff itself** — read for intent when other sources are thin
6. **The change's dry-run output**: when CI posted what the change will do to running systems,
   such as a Terraform or OpenTofu plan, a Spacelift or Atlantis comment, a migration dry run or a
   `kubectl diff`, take the newest one from the Step 1 fetch. It reports what the change does, not
   a reviewer's opinion of it, so it goes to every agent. Note the commit it ran against, and say
   so when that is older than the PR's head. Save the whole dry run to a file in the scratchpad,
   because the attribute values it shows answer questions that the action lines alone leave open.

Consider everything in the ticket for inclusion in the block below, and carry what binds the
review: numbered properties (`P1`, `P2`, …), the options the ticket rejected and why, choices
recorded as deliberate, and anything deferred to another ticket. A reviewer who has not seen these
recommends reversing a choice the ticket already argued, or flags a deferral as a gap.

Synthesize into a single crisp block:

```
Problem: [what's broken, missing, or needed — and why it matters]
Approach: [how this change addresses it, at a high level]
Key outcomes: [invariants, constraints, or requirements the implementation must satisfy]
Recorded decisions: [the ticket's numbered properties, rejected options, deliberate choices and
  deferrals, each with where it is recorded; "none found in <where you looked>" when empty]
Dry-run output: [each planned action and the summary line, verbatim, then the path of a file
  holding the full dry run, attribute lines included, for agents to read; "none posted" when CI
  posted none]
Diff command: [exact command agents should run to read the diff]
```

Enhance if needed: if raw sources are vague, read the diff and fill in the gaps. Never leave this
block generic ("various improvements") or empty.

A finding that would reverse a recorded decision is not dropped. It is reported as a challenge to
that decision, naming the record, so the reader weighs the new argument against the old one.

## Step 3: Launch the agents in parallel

The twelve agents below always run. You may add more in the same fan-out when this particular
change raises a question none of the twelve prompts ask.

The bar is a named question, not a topic. "Add a concurrency agent" is a topic. "Does the new
retry path double-submit when the first attempt times out after the server committed?" is a
question, and it earns an agent. If you cannot write the question down, do not add the agent.

Add rather than enrich. Each agent answers its own question, so a concern appended to an existing
agent's prompt competes with that question for its attention. A new agent gives the concern a
question of its own.

Give an added agent the same shape as the twelve: the intent block, the file list, the provenance
requirement, and one question to answer. Record the question and why the twelve did
not cover it — Step 4 reports it.

Send a single message containing all Agent tool calls simultaneously. When the harness caps how
many subagents run at once, it refuses the calls past the cap, and each refused call's result says
so, often with "Do not retry". That forbids resending them at once, not later. Each time a running
agent reports, launch one refused agent, with the same prompt and model. Keep going until every
agent has run, and only then start Step 3.5. A review of several scopes, such as
several commits each reviewed on its own, often needs more agents than the cap allows.

Choose each agent's `model` from what its question demands of this change. The same agent can need
different models on different changes: Language on a docs-only commit reads one file list and
stops, while Correctness on a change to retry logic has to reason about states nobody wrote down.
Ask how much of the answer is judgement rather than lookup, and what a wrong answer would cost.
Step 3.5 catches a wrong claim, but not a finding the agent never made, so an agent whose question
needs judgement on this diff gets a model strong enough to make it. Pick the cheapest model that
meets that; cost rules a model out, never in. Pass each agent:

- The synthesized intent block from Step 2
- The list of changed/reviewable files
- Nothing from the earlier reviews fetched in Step 1, not even that they exist
- Its specific instructions below
- This line, verbatim: "Read the files yourself. Do not spawn subagents."
- This provenance requirement, verbatim:

  > For every finding, state whether the change under review **introduced** it or whether it is
  > **pre-existing** — already true on the base ref before this change. Decide it mechanically,
  > not by impression: run `git show <base-ref>:<path>` (or `git log -S '<the exact line>'`) and
  > say which you ran. A line that appears in the diff as unchanged context is pre-existing even
  > when it sits inside a function the change rewrote. Label each finding `[introduced]` or
  > `[pre-existing]`. If you cannot determine it, say `[provenance unknown]` rather than guessing.

---

### Agent 1: Intent Alignment

```
Question: Does the implementation actually achieve the stated intent of this change?

**Report every finding you would act on, most severe first, one or two lines each. List anything you considered and rejected in one line each. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.agents/standards/README.md`, then `~/.agents/standards/correctness.md`. Use these standards as your evaluation criteria.
2. Run the diff command from Context to read what changed.
3. Compare the diff carefully against the Problem, Approach, and Key outcomes in the Context block.

Look for gaps between stated intent and actual implementation:
- Does the code fully address the stated problem, or only partially?
- Are there stated outcomes not implemented or only half-implemented?
- Are there edge cases implied by the problem statement that the implementation ignores?
- Are there implicit requirements from the problem domain that the implementation misses, even if not explicitly stated?

Also check for drift:
- Does the code do things unrelated to the stated intent? (scope creep, unrelated refactoring bundled in)
- Are commit messages consistent with what the diff actually changes?

For each gap: what the stated intent says | what the implementation actually does | what's missing or misaligned
If implementation matches intent: report "Implementation aligns with stated intent."
```

---

### Agent 2: Approach

```
Question: Is this the simplest correct solution to the stated problem, and is it the best available approach?

**Report every finding you would act on, most severe first, one or two lines each. List anything you considered and rejected in one line each. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.agents/standards/README.md`, then `~/.agents/standards/code-readability.md` and `~/.agents/standards/code-structure.md`. Use these standards as your evaluation criteria.
2. Search for project docs defining standards or preferences (README.md, CONTRIBUTING.md, docs/, style guides) — CLAUDE.md is already loaded. Use them to inform your review.
3. Run the diff command from Context to read what changed.
4. Read the unchanged files the diff calls or imports, to see existing patterns and available utilities.

Simplicity check — ask this first:
What is the minimum code that correctly solves the stated problem? Compare it to what was written. If the answer is substantially less, that gap is the most important finding. Look for:
- Abstractions for a single call site, or layers that exist for one use case
- Problems being solved that were never stated — hypothetical future requirements, speculative flexibility
- Existing utilities, patterns, or libraries in the project or standard library that would make this trivial
- Complexity whose justification isn't obvious to a competent reader of the problem statement

Ground every observation in the actual code and the problem being solved. Don't flag superficial rewrites.

If a simpler or better approach exists: describe it concretely, explain what makes it better, and note the cost of switching.
If the approach is well-chosen: report "Approach is well-suited to the problem."
```

---

### Agent 3: Structure

```
Question: Is the internal organisation of this code sound?

**Report every finding you would act on, most severe first, one or two lines each. List anything you considered and rejected in one line each. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.agents/standards/README.md`, then `~/.agents/standards/code-structure.md` and `~/.agents/standards/code-readability.md`. Use these standards as your evaluation criteria.
2. Search for project docs defining standards or preferences (README.md, CONTRIBUTING.md, docs/, style guides) — CLAUDE.md is already loaded. Use them to inform your review.
3. Run the diff command from Context to read what changed.
4. Read related unchanged files to understand existing structural patterns and conventions.

For each issue: file:line | what's wrong | specific alternative
If structure is sound, report "Structure and internal organisation look solid."
```

---

### Agent 4: Public Surface

```
Question: From the caller's perspective, is this code well-designed and discoverable?

**Report every finding you would act on, most severe first, one or two lines each. List anything you considered and rejected in one line each. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.agents/standards/README.md`, then `~/.agents/standards/type-design.md`, `~/.agents/standards/api-design.md`, and `~/.agents/standards/documentation.md`. If the project has a CLI binary or command-line interface, also load `~/.agents/standards/cli-design.md`. Use these standards as your evaluation criteria.
2. Search for project docs defining standards or preferences (README.md, CONTRIBUTING.md, docs/, style guides) — CLAUDE.md is already loaded. Use them to inform your review.
3. Run the diff command from Context to read what changed.
4. Find all documentation that could be affected: .md files, help text, docstrings, CLI --help output, code comments in changed files.

For each issue: file:line | what's wrong | specific fix
If the public surface is well-designed and documented, report "Public surface is well-designed and documented."
```

---

### Agent 5: Correctness

```
Question: Does this code behave correctly across all inputs, states, and callers?

**Report every finding you would act on, most severe first, one or two lines each. List anything you considered and rejected in one line each. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.agents/standards/README.md`, then `~/.agents/standards/correctness.md` and `~/.agents/standards/error-handling.md`. Use these standards as your evaluation criteria.
2. Search for project docs defining standards or preferences (README.md, CONTRIBUTING.md, docs/, style guides) — CLAUDE.md is already loaded. Use them to inform your review.
3. Run the diff command from Context to read what changed. For files under 500 lines, read the full file. For larger files, read each changed section plus ~30 lines of context.
4. Read 2-3 similar unchanged files to understand existing patterns for error handling and validation.

For each issue: file:line | what's wrong | concrete impact | specific fix
Skip theoretical what-ifs — report actual problems in the code.
```

---

### Agent 6: Data Safety

```
Question: Is data protected from external threats, personal data mishandling, and write-time corruption?

**Report every finding you would act on, most severe first, one or two lines each. List anything you considered and rejected in one line each. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.agents/standards/README.md`, then `~/.agents/standards/security.md`, `~/.agents/standards/privacy.md`, and `~/.agents/standards/data-integrity.md`. Use these standards as your evaluation criteria.
2. Search for project docs defining standards or preferences (README.md, CONTRIBUTING.md, docs/, style guides) — CLAUDE.md is already loaded. Use them to inform your review.
3. Run the diff command from Context to read what changed, then read surrounding context.
4. If database models or migrations changed, read them in full.

For each issue: file:line | what's wrong | severity (Critical/High/Medium/Low) | specific fix
Only report actual violations, not theoretical what-ifs.
If no concerns found, report "No data safety concerns identified."
```

---

### Agent 7: Runtime Behaviour

```
Question: How does this code behave under real-world conditions — load, failure, and concurrency?

**Report every finding you would act on, most severe first, one or two lines each. List anything you considered and rejected in one line each. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.agents/standards/README.md`, then `~/.agents/standards/performance.md`, `~/.agents/standards/async-coordination.md`, `~/.agents/standards/reliability.md`, `~/.agents/standards/observability.md`, and `~/.agents/standards/instrumentation.md`. Use these standards as your evaluation criteria.
2. Search for project docs defining standards or preferences (README.md, CONTRIBUTING.md, docs/, style guides) — CLAUDE.md is already loaded. Use them to inform your review.
3. Run the diff command from Context to read what changed, then read surrounding context.
4. Check how similar operations are handled in unchanged files.

Observability:
- If this fails in production, would we know? Is the failure diagnosable from logs alone?

For each issue: file:line | what's wrong | concrete impact | specific fix
Only report actual problems, not theoretical micro-optimizations.
If no concerns found, report "No runtime behaviour concerns identified."
```

---

### Agent 8: Testing

```
Question: Is the test suite trustworthy and sufficient to catch regressions in this change?

**Report every finding you would act on, most severe first, one or two lines each. List anything you considered and rejected in one line each. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.agents/standards/README.md`, then `~/.agents/standards/testing.md`. Use these standards as your evaluation criteria.
2. Search for project docs defining standards or preferences (README.md, CONTRIBUTING.md, docs/, style guides) — CLAUDE.md is already loaded. Use them to inform your review.
3. Run the diff command from Context to read what changed.
4. Find and read the corresponding test files (new and existing).
5. Read 2-3 existing test files to understand the project's test conventions and style.

Coverage:
- Are critical paths tested? (auth, payments, data integrity, error paths)
- Specify exact missing cases: not "add tests" but "add tests for: expired token, missing token, wrong signature"

Sensitivity:
- For each test the change adds or rewrites whose name or docstring says what it guards (a property, a commit, a rollback, an isolation), name the line of code it guards and a one-line break of that line: delete the commit, drop the savepoint, skip the reset, return a constant.
- Make the cheapest breaks, at most three, and run only the test that should catch each. Never edit the reviewed tree, which other agents are reading: work in a scratch worktree, `REF=$(git stash create); DIR=$(mktemp -d); git worktree add --detach "$DIR" "${REF:-HEAD}"`, and `git worktree remove --force "$DIR"` when done.
- A test that still passes under its break is a finding: name the test, the break, and why its setup cannot produce the failure (a shared session, a fixture that raises before writing, an environment that never holds the guarded value).

For each issue: file:line | what's wrong | specific fix
If tests are well-designed, report "Test design is solid and coverage is appropriate."
```

---

### Agent 9: Release Readiness

```
Question: Is this change ready to ship responsibly — dependencies justified, deployment safe, config correct?

**Report every finding you would act on, most severe first, one or two lines each. List anything you considered and rejected in one line each. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.agents/standards/README.md`, then `~/.agents/standards/dependencies.md`, `~/.agents/standards/deployment.md`, and `~/.agents/standards/config.md`. Use these standards as your evaluation criteria.
2. Search for project docs defining standards or preferences (README.md, CONTRIBUTING.md, docs/, style guides) — CLAUDE.md is already loaded. Use them to inform your review.
3. Run the diff command from Context to read what changed.
4. If package files changed, read them in full. If config or env handling changed, read those files in full.

For each issue: file:line | what's wrong | specific recommendation
If no concerns found, report "No release readiness concerns identified."
```

---

### Agent 10: Language

```
Question: Does this code use the language correctly, following the project's established idioms?

**Report every finding you would act on, most severe first, one or two lines each. List anything you considered and rejected in one line each. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Identify which programming languages are present in the changed files by file extension (`.rs` → Rust, `.py` → Python, `.ts`/`.tsx` → TypeScript, `.sh`/`.bash` → bash).
2. Read `~/.agents/standards/README.md`, then load only the reference files that apply: `~/.agents/standards/rust.md` if Rust files are present, `~/.agents/standards/python.md` if Python files are present, `~/.agents/standards/typescript.md` if TypeScript files are present, `~/.agents/standards/bash.md` if bash scripts are present.
3. If no language-specific reference files apply to the changed files, report "No language-specific reference files apply to this change." and stop.
4. Otherwise, run the diff command from Context to read what changed.

Apply the loaded standards to the changed files. Look for violations specific to the language — idioms, error handling patterns, type system conventions, and anti-patterns called out in the standards files.

For each issue: file:line | what's wrong | specific fix
If no language-specific issues found, report "No language-specific concerns identified."
```

---

### Agent 11: Failure Paths

```
Question: For each failure path this change adds or moves — a throw, a non-zero exit, an error return, a new branch that gives up — is it reachable from the program's real entry point, and when it fires, what does the process observably do?

**Answer the question path by path first, then report every issue you would act on, most severe first, one or two lines each. List anything you considered and rejected in one line each. If the change adds no failure path, say so in one sentence and stop.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.agents/standards/README.md`, then `~/.agents/standards/error-handling.md`, `~/.agents/standards/reliability.md`, `~/.agents/standards/observability.md`, `~/.agents/standards/instrumentation.md`, and `~/.agents/standards/async-coordination.md`. Use these as your evaluation criteria.
2. Run the diff command from Context. List every failure path the diff adds or relocates. A path that merely changes its message is not one; a path that changes when, whether, or how loudly it fires is.
3. For each path, find the program's real entry point (the binary, the `main`, the script the scheduler runs, the handler the framework calls) and trace whether anything reachable from it reaches that path. Grep for importers of the module, then importers of those. Say plainly when nothing does: an unreachable failure path protects nothing, however correct it looks.
4. For each reachable path, read the enclosing function IN FULL plus its callers, and determine what actually happens when it fires. Name the observable outcome: exit code, what appears in logs, and whether remaining work continues, is skipped, or is silently reported as success.
5. Check specifically for handlers that do not catch what they look like they catch: a synchronous throw evaluated while building an argument, before the promise/future it is passed to exists; a throw in a constructor or at module load; an error raised outside the `try` that visually surrounds it; a rejected promise nothing awaits.
6. Judge each outcome against the intent block. A change whose stated point is failing earlier or louder has not delivered it if the failure is caught and logged deep in the stack, or if the process still exits 0.

For each issue: file:line | the path | reachable from where, or not at all | what the process actually does | why that is wrong given the intent
```

---

### Agent 12: Out-of-Diff References

```
Question: For each thing this change withdraws, restricts or renames — a route, page, command, flag, field, column, config key, file path, URL, message or permission that is removed, gated, renamed or narrowed — which references to it live OUTSIDE the diff, and does each one still work, or is it now broken, dead or misleading?

**Answer thing by thing first, then report every issue you would act on, most severe first, one or two lines each. List anything you considered and rejected in one line each. If the change withdraws, restricts or renames nothing, say so in one sentence and stop.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.agents/standards/README.md`, then `~/.agents/standards/correctness.md` (the Must "Implementation is complete and finished") and `~/.agents/standards/config.md` (the Should on combinations of switches). Use these as your evaluation criteria.
2. Run the diff command from Context. List every thing the diff withdraws, restricts or renames, and for each, every identifier a reference to it could use: its name, its path or URL, its key, its label, and any helper that builds it.
3. Search the whole repository for each identifier, excluding the changed files. Search for the identifier itself, not for the rule the change introduces, because a reference that never mentions the rule is the one most likely to be broken. Include code that generates links or messages the system sends (emails, notifications, redirects), documentation, config and deployment files, and tests. If the project's deployment config or consumers live in another repository you can read, search there too; if you cannot, say which repository and what you would have searched for.
4. For each reference found, decide whether it still works after the change. A reference is broken when it calls, links, navigates or points to something that is now gone, refused or renamed; misleading when it describes the old state as current.
5. Where the change introduces switches, modes or options that can be combined, list each combination the system accepts (does not refuse at startup). For each accepted combination, check every consumer of those switches, including consumers outside the diff, and report any that misbehaves under it. Treat a comment or doc calling a combination supported as a claim to check.
6. Pre-existing references the change newly breaks are findings for this change: label them `[pre-existing]` for the line and say the change is what breaks them.

For each issue: file:line | the reference | the thing it points to | why it is broken or misleading after this change | what would fix it, or which ticket should own it
```

---

## Step 3.5: Verify before presenting

Before writing a single line of output, audit the agent findings for claims that assert specific
library behavior, numerical values, runtime semantics, or API guarantees. These are the highest-risk
claims — most likely to be subtly wrong — and the ones a reviewer would have to take on faith.

**For each such claim, run a targeted check:**

- Library default values → `python3 -c "import lib; print(lib.DEFAULT_X)"`
- API signature or accepted kwargs → `python3 -c "import inspect, lib;
  print(inspect.signature(lib.Cls.method))"`
- Stdlib availability → `python3 -c "import lib; print(hasattr(lib, 'func'))"`
- Source behavior → read the relevant installed source with `python3 -c "import inspect, lib;
  print(inspect.getsource(lib.func))"`
- File/doc claims → read the file

**Apply the results:**

- Strike claims that don't survive the check rather than softening them, and list each one under
  **Dropped** in Step 4.
- Correct claims that are partially right — state what's actually true.
- Merge duplicate findings — when multiple agents flag the same issue, keep the most precise version
  and note the convergence.
- Drop findings you cannot verify and that are speculative rather than grounded in the diff, and
  list each one under **Dropped** in Step 4.

Only carry verified findings into Step 4.

## Step 4: Present findings

Produce a prioritized action list — not a categorized findings report. The reader's question is
"what should I change?" Answer it directly.

**First, reconcile with the earlier reviews fetched in Step 1.** Both paths reach this step, the
agents' and Step 1a's. Read each earlier finding and open question, and give it one verdict:

- **agreed**: your own evidence supports it. Cite that evidence, not theirs.
- **disputed**: your evidence contradicts it. Say what you found.
- **answered**: it was an open question, or a check the reviewer could not run, and your work
  settles it.
- **not checked**: nothing you did bears on it. Say so rather than adopting their claim.

An earlier finding is a claim to verify, not a finding of yours. One you have not checked does not
enter Findings, however confident it sounds. Note where a review describes an older commit than the
one you reviewed, and whether a thread is already resolved. Skip praise, summaries and boilerplate.

```
## Code Review

### Verdict: [Approve | Request Changes | Comment]
[One sentence on what to do next]

### Findings

| # | Severity | Location | Action |
|---|----------|----------|--------|
| 1 | must | `file:line` | [imperative: what to do] |
| 2 | should | `file:line` | [imperative: what to do] |
| 3 | consider | `file:line` | [imperative: what to do] |
| 4 | ? | `file:line` | [open design question] |

---

**1. `file:line` — [imperative: what to do]** *(must)*

[1–3 sentences. Explain why this matters — what breaks, degrades, or becomes harder if left unfixed. Then describe what work you did to verify the claim: which file or function you read, which command you ran, what the output showed. Use hedging language ("no guard visible in the surrounding context", "appears to", "may") if confidence is less than certain.]

**2. `file:line` — [imperative: what to do]**

[Same structure. Cite the specific code or source that grounds the finding. If you ran a command to verify a library behavior or default value, say so and include the result.]

**4. `file:line` — [open design question]**

- (a) [one path and its tradeoff]
- (b) [another path and its tradeoff]

### Added agents
[Omit this section entirely if you added none.]

- **[the question you added it to answer]** — Why the twelve did not cover it: [reason] — What it
  found: [finding, or "nothing"]

**Generalisable?** [One of: this was specific to this change, nothing to close. | This is a
category — [what recurs] — close it by [adding a standing 13th agent for X / adding a standard to
`~/.agents/standards/<file>.md` saying Y / both].]

### Prior reviews
[Omit this section entirely if nobody else has reviewed or commented.]

- **[reviewer] ([date]), [their claim in a few words]:** [agreed | disputed | answered | not
  checked]. [Your evidence in one sentence.]

### Looks Good
[One sentence: what the change gets right, or which concern areas came back clean.]

### Dropped
[Omit this section entirely if nothing was dropped.]

- [the claim, and its agent]: [why it was struck or could not be verified]
```

**Formatting rules:**

- The table is a scannable index only — one row per finding, action phrased as an imperative.
- Severity column values: `must`, `should`, `consider`, `?` (open question). Order rows by severity.
- Each detail section is 1–3 sentences of integrated prose — no labeled sub-fields. It must answer
  two questions: (1) why does this matter, and (2) what did you actually look at to verify it. These
  are not optional; a finding with no impact explanation or no verification basis should not be
  reported.
- Use hedging language within the prose when confidence is less than certain — don't assert facts
  you haven't confirmed.
- Open question items (`?`) get the (a)/(b) tradeoff format instead of prose.
- Omit "What's Working Well" and "All Clear" sections — consolidate into the single "Looks Good"
  line.
- If there are no recommended changes, say so in one sentence under the verdict and skip the
  Findings section.

**Verdict mapping:**

- **Approve** — no blockers; all remaining items are optional
- **Request Changes** — one or more `must` items
- **Comment** — open questions or suggestions worth discussing, nothing blocking

## Step 5: Post review (PR scope only)

After presenting findings, if this is a PR and the author is the user (ooloth), ask the user to
indicate which changes to make locally or discuss further first and then stop and wait for a reply
(skip the rest of this skill's instructions).

Otherwise, if this is a PR and the author is NOT the user, ask:

> "Post this as a GitHub review? (yes / approve / request-changes / comment / skip)"

**Authorization gate:** Only proceed if the user explicitly answers this question with yes, approve,
request-changes, comment, or skip. Do NOT infer authorization from numbered responses to
individual findings (e.g., "(1) do it" answers finding #1, not this question). Wait for a
separate, unambiguous reply to the posting question before posting anything to GitHub.

On any answer other than "skip":

- Map to GitHub event: yes → use verdict from Step 4; approve → APPROVE;
  request-changes → REQUEST_CHANGES; comment → COMMENT
- Write a 2–3 sentence overall summary for the review body (see audience guidance below). Where an
  earlier review raised a point, refer to it by reviewer instead of restating it, and say so when
  your work answered a question it left open or disputes something it claimed.
- Collect every finding that has a `file:line` reference as an inline comment
- Get the PR's head commit, so the comments stay pinned to the code you reviewed:
  `gh pr view <pr-number> -R <owner>/<repo> --json headRefOid -q .headRefOid`
- When you show the user drafts to approve, show each body exactly as it will be posted, line
  breaks included (one blockquote per comment works), so approving the words also approves the
  shape.
- Write the review to a JSON file in the scratchpad with the **Write tool**. Never build it with a
  shell heredoc, `echo`, or command-line arguments: the shell rewrites backticks, `$(...)` and
  quotes, and a mangled review cannot be un-posted. `line` is the line number in the PR's version
  of the file; `side` is `RIGHT` for those and `LEFT` only for a line the PR deletes.

```json
{
  "event": "APPROVE",
  "body": "<summary>",
  "commit_id": "<head SHA>",
  "comments": [
    { "path": "<file>", "line": 42, "side": "RIGHT", "body": "<comment>" }
  ]
}
```

- Dry-run it and read the output. It prints the exact payload that would be sent. Check that every
  body reads as intended and every `path`/`line` points where you meant; fix the file and dry-run
  again until it does. The dry run also notes any body that runs several sentences together in
  one paragraph. Reread those and split off the point, unless the comment genuinely reads better
  whole:

```bash
uv run <skill-base-dir>/scripts/post_review.py <pr-number> <review.json> --repo <owner>/<repo> --dry-run
```

- Post it by running the same command without `--dry-run`. `--repo` is required, so the review
  cannot land on a same-numbered PR in whatever repo the shell is in.

**Summary audience:** The review body is read by GitHub users who only know what's in the PR diff —
they have no context from this review session. Write for that audience:

**Tone for inline comment bodies:** Write like a person talking to a teammate, not a report
generator. Approach it the way a mentor invested in someone's growth would: patient, curious, and
specific, not grading their work. Avoid em dashes; they're one of the more obvious signs a
comment was generated rather than typed by a person.

Structure: make the point of the comment stand out. Its first paragraph is the one thing you want
the author to take away: the question you're asking, or what you found. Then a blank line, then
the reasoning and evidence. Someone skimming the review should get each comment's point from its
first line alone. A comment that's a single sentence anyway needs no break. The review body works
the same way: verdict and overall point first, detail after.

Asking something you already have a strong idea about is fine, as long as the question genuinely
invites them into the reasoning: their intent, an edge case, a judgment call. What's not fine is
replaying a fact you've already fully nailed down as if it were still open. If you've proven
something and there's nothing left to discover, skip the question. Say what you found and ask
for the fix.

How direct to be depends on what's at stake:

- Going to break something, and you're sure? Ask for the fix directly, then say what you found.
  "Can you add a check for the empty queue here? / This throws in production when the queue's
  empty. I traced it to line 40."
- Have an opinion but nothing's actually wrong? Ask if they want the change, then say why, and
  make clear it's optional. "Want to pull this into a shared helper? / It's the same fixture as
  `test_x.py:40`, not a big deal either way."
- Real choice, no clear right answer? Ask which way they'd rather go, then lay out what's
  different. "Did you consider clearing the audit stamp on revert instead of keeping it? /
  Keeping it preserves who reverted; clearing it treats the row as fresh."
- Don't know why something was done a certain way? Ask if it was on purpose, then say what looked
  off. "Was skipping the null check here intentional? / The sibling function has one and this
  doesn't."
- Small, and you don't feel strongly? Skip the question, just mention what you saw.

**Vary the phrasing across a batch.** The phrasings above ("Can you...", "Want to...", "Did you
consider...", "Was... intentional?") illustrate the register for each situation, not a set of
stock openers to cycle through. A real person doesn't open four comments in the same review with
the same three words; reaching for the same opener each time is one of the more obvious tells that
a comment was generated rather than typed. Before posting a batch, scan the first few words of
every comment: if two or more start the same way (especially "Want to..."), rewrite until each one
reads distinctly. A few alternatives per category, just to show the range:

- Sure it breaks, direct fix: "Can you add...", "Mind adding...", "This needs a...", or skip the
  question and phrase the fix as a plain instruction ("Add a check for the empty queue here.").
- Opinion, optional: "Want to...", "Any interest in...", "Worth pulling this into...?", "Thoughts
  on...?", or lead with the observation and land the question after ("This repeats the fixture
  from `test_x.py:40`, worth sharing it?").
- Real design choice: "Did you consider...", "Which way did you lean on...", "Curious why you went
  with X over Y here", "Is X or Y closer to what you want?"
- Unclear intent: "Was this intentional?", "Did you mean to...", "Is this deliberate, or...?",
  "This looked like it might be a slip, was it?"

These are a handful of examples to illustrate the range, not the full menu. Don't ration yourself
to a small rotating set of phrases either, since that just trades one tell for another (a
reviewer who always says "Can you", "Want to", "Did you consider", or "Was this intentional" in
some rotation still reads as generated). Use your own words each time, the way you'd actually say
it out loud to the person sitting next to you. The goal is a batch that reads like one attentive
person moved down the file making distinct, differently-voiced observations, not like a template
applied four times or a fixed phrasebook applied on rotation.

Use a quick example when it makes the impact click, and say something nice when it's earned. When
a code snippet or a suggested fix would make the ask concrete, include it directly in the
comment: quote the line in question, or show the small change you have in mind, rather than
describing it in prose alone.
