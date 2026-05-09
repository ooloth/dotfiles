---
name: review-code
description: Standalone code review for any scope — PR number, branch, file paths, or current changes. Synthesizes intent, runs 10 parallel specialized agents, and presents actionable findings with a verdict. For PR scope, optionally posts the review to GitHub with inline comments.
argument-hint: '[pr number, branch name, file paths, or nothing for current branch]'
allowed-tools: Bash Read Grep Glob
effort: high
model: opus
---

## Step 1: Determine scope

Identify what to review and the exact diff command to pass agents.

| Argument                      | File list                              | Diff command                             |
| ----------------------------- | -------------------------------------- | ---------------------------------------- |
| PR number or URL              | `gh pr diff <n> --name-only`           | `gh pr diff <n>`                         |
| Branch name                   | `git diff <branch>...HEAD --name-only` | `git diff <branch>...HEAD`               |
| File path(s)                  | use provided paths                     | `git diff HEAD -- <files>`               |
| None, on feature branch       | `git diff main...HEAD --name-only`     | `git diff main...HEAD`                   |
| None, on main, staged         | `git diff --staged --name-only`        | `git diff --staged`                      |
| None, on main, nothing staged | —                                      | ask: "What would you like me to review?" |

Substitute the actual base ref (main, master, trunk) where needed. Detect the current branch with `git symbolic-ref --short HEAD`.

**Skip non-reviewable files:**

- package-lock.json, \*.lock, yarn.lock, Gemfile.lock
- Generated code (_.generated._, \*\_pb2.py, etc.)
- Test snapshots (**snapshots**/\*)
- Vendored dependencies (vendor/, node_modules/ if committed)
- Binary files
- Formatting-only changes (whitespace/style only)

**For PR scope — fetch PR context before Step 2:**

```bash
gh pr view <n> --json title,body,number
```

Store the title and body for use in Step 2. Store the PR number for Step 5.

Output the reviewable file list and diff command before proceeding.

## Step 2: Synthesize intent

Build a context block that every agent receives. Gather from these sources in priority order:

1. **PR title and body** — from Step 1 fetch (if PR scope)
2. **Linked issues** — if the PR body references issue numbers, fetch with `gh issue view <n>`
3. **Commit messages** — `git log <base>...HEAD --format="%s%n%b"`
4. **The diff itself** — read for intent when other sources are thin

Synthesize into a single crisp block:

```
Problem: [what's broken, missing, or needed — and why it matters]
Approach: [how this change addresses it, at a high level]
Key outcomes: [invariants, constraints, or requirements the implementation must satisfy]
Diff command: [exact command agents should run to read the diff]
```

Enhance if needed: if raw sources are vague, read the diff and fill in the gaps. Never leave this block generic ("various improvements") or empty.

## Step 3: Launch all 10 agents in parallel

Send a single message containing all 10 Agent tool calls simultaneously. Pass each agent:

- The synthesized intent block from Step 2
- The list of changed/reviewable files
- Its specific instructions below

---

### Agent 1: Change-Intent Alignment

```
Assess whether the implementation actually achieves the stated intent of this change.

**Return findings in 200 words or fewer. Report your top 3 issues only, ordered by severity. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.claude/references/README.md`, then `~/.claude/references/correctness.md`. Use these invariants as your evaluation criteria.
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

### Agent 2: Approach Alternatives

```
Assess whether the approach taken is the best available choice for this problem.

**Return findings in 200 words or fewer. Report your top 3 issues only, ordered by severity. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.claude/references/README.md`, then `~/.claude/references/design.md` and `~/.claude/references/architecture.md`. Use these invariants as your evaluation criteria.
2. Search for project docs defining standards or preferences (README.md, CONTRIBUTING.md, docs/, style guides) — CLAUDE.md is already loaded. Use them to inform your review.
3. Run the diff command from Context to read what changed.
4. Read related unchanged files and explore the broader codebase to understand existing patterns and available tools.

Consider whether an alternative approach would be meaningfully better on any of these axes:
- More reliable: fewer failure modes, better error recovery, more robust to edge cases
- More correct: fewer logical gaps, better coverage of the problem's full scope
- More idiomatic: uses the language, framework, or platform as intended
- Less complex: achieves the same outcome with less code or fewer moving parts
- More declarative: expresses what rather than how
- More expressive of intent: a reader immediately understands what this code is for and why

Ground every observation in the actual code and the problem being solved. Don't flag superficial rewrites or stylistic preferences — only raise an alternative if it's substantively better for the core problem.

If you see a meaningfully better approach: describe it concretely (not just "consider X"), explain what makes it better, and note the cost of switching.
If the approach is sound: report "Approach looks well-suited to the problem."
```

---

### Agent 3: Design & Code Quality

```
Review the changed files for design quality, expressiveness, readability, and simplicity.

**Return findings in 200 words or fewer. Report your top 3 issues only, ordered by severity. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.claude/references/README.md`, then `~/.claude/references/architecture.md`, `~/.claude/references/design.md`, `~/.claude/references/code-quality.md`, and `~/.claude/references/type-design.md`. Use these invariants as your evaluation criteria.
2. Search for project docs defining standards or preferences (README.md, CONTRIBUTING.md, docs/, style guides) — CLAUDE.md is already loaded. Use them to inform your review.
3. Run the diff command from Context to read what changed.
4. Read related unchanged files to understand existing design patterns and conventions.

Design coherence:
- Does the overall structure make sense, or is there a simpler mental model?
- Is the solution internally consistent, or are similar problems solved differently?
- Does implementation match the problem's inherent complexity (not over/under-engineered)?

Evolvability:
- Assume we're going to extend this code a lot over time; how could improving its structure better prepare for that?
- Could different structure unlock adding and removing pieces more easily?
- Could different structure expand unbroken regions of pure code that's easy to test comprehensively?

Expressiveness:
- Are domain-specific types used instead of primitives where intent would be clearer?
- Do types enforce invariants and make invalid states unrepresentable?
- Are there overly broad types (Any, untyped dicts) that provide no safety or documentation value?

Abstraction ROI:
- Do abstractions pull their weight? (used more than once, clearer than inline)
- Is there unnecessary indirection or wrapping?
- Are there helpers that exist for a single call site?

Readability & simplicity:
- Would a new maintainer struggle to understand intent?
- Is logic overly clever when a dumber approach would be clearer?
- Is there premature generality (configurable where hardcoded would suffice)?
- Are there long functions or deeply nested blocks that should be extracted?

Code noise:
- Dead code, commented-out code, unused imports or variables?
- Remnants from exploration (partial refactors, abandoned approaches)?
- Unrelated changes mixed in that should be a separate commit?

For each issue: file:line | what's wrong | specific alternative
If the code is well-designed, report "Design and code quality look solid."
```

---

### Agent 4: Correctness

```
Review the changed files for correctness issues.

**Return findings in 200 words or fewer. Report your top 3 issues only, ordered by severity. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.claude/references/README.md`, then `~/.claude/references/correctness.md`, `~/.claude/references/assertions.md`, and `~/.claude/references/error-handling.md`. Use these invariants as your evaluation criteria.
2. Search for project docs defining standards or preferences (README.md, CONTRIBUTING.md, docs/, style guides) — CLAUDE.md is already loaded. Use them to inform your review.
3. Run the diff command from Context to read what changed. For files under 500 lines, read the full file. For larger files, read each changed section plus ~30 lines of context.
4. Read 2-3 similar unchanged files to understand existing patterns for error handling, validation, etc.

Review for:
- Logic errors, off-by-one errors, incorrect conditionals
- Missing edge cases (empty input, null/None, zero, max values)
- Incomplete feature implementation (stated goals not fully met)
- Error propagation: are errors handled consistently with surrounding code?
- Backward compatibility: does this break existing callers or data?
- Are existing utilities/patterns reused, or is this reinventing the wheel?

For each issue: file:line | what's wrong | concrete impact | specific fix
Skip theoretical what-ifs — report actual problems in the code.
```

---

### Agent 5: Data Integrity

```
Review the changed files for data integrity and state consistency concerns.

**Return findings in 200 words or fewer. Report your top 3 issues only, ordered by severity. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.claude/references/README.md`, then `~/.claude/references/data-integrity.md`. Use these invariants as your evaluation criteria.
2. Search for project docs defining standards or preferences (README.md, CONTRIBUTING.md, docs/, style guides) — CLAUDE.md is already loaded. Use them to inform your review.
3. Run the diff command from Context to read what changed, then read surrounding context.
4. If database models or migrations changed, read them in full.

Validity:
- Can invalid data be written to persistent storage? (missing validation, no DB constraints)
- Are uniqueness, foreign key, and type constraints enforced at both application and DB level?
- Are there writes that bypass validation layers?

Atomicity:
- Are multi-step writes wrapped in transactions where partial failure would corrupt state?
- If a write sequence fails midway, is the resulting state valid or corrupt?
- Are there read-modify-write patterns missing locks or optimistic concurrency checks?

Consistency:
- Are related entities kept in sync? (denormalized counts, derived fields, both sides of a relationship)
- Are there race conditions where concurrent writers could produce inconsistent state?

Migrations:
- Does the migration handle existing rows correctly?
- Can existing data violate new constraints being added?
- Is the migration reversible? Is there a down migration?

For each issue: file:line | what's wrong | concrete failure scenario | specific fix
If no concerns found, report "No data integrity concerns identified."
```

---

### Agent 6: Test Inspector

```
Inspect the tests for the changed files — assess quality, design, and coverage without running the suite.

**Return findings in 200 words or fewer. Report your top 3 issues only, ordered by severity. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.claude/references/README.md`, then `~/.claude/references/testing.md`. Use these invariants as your evaluation criteria.
2. Search for project docs defining standards or preferences (README.md, CONTRIBUTING.md, docs/, style guides) — CLAUDE.md is already loaded. Use them to inform your review.
3. Run the diff command from Context to read what changed.
4. Find and read the corresponding test files (new and existing).
5. Read 2-3 existing test files to understand the project's test conventions and style.

Conventions:
- Do the tests follow project conventions (file naming, structure, assertion style)?
- Does new test code follow the patterns established in the codebase?

Coverage (with ROI lens):
- Do the tests provide evidence the changes work across all logical branches?
- Are critical paths tested? (auth, payments, data integrity, error paths)
- Specify exact missing cases: not "add tests" but "add tests for: expired token, missing token, wrong signature"

Test design:
- Do tests verify behavior, not implementation details?
- Are assertions focused on outcomes users care about?
- Will these tests break for the wrong reasons? (brittle selectors, testing internals)

Testing approaches — are more powerful techniques underused?
- Parametrization: could similar test cases collapse into one parametrized test?
- Snapshot testing: appropriate for UI output or serialized structures?
- Property-based testing: applicable where input space is large and relationships hold generally?
- Are the chosen approaches well-matched to what's being tested?

Test code quality:
- Copy-pasted setup that should be extracted to helpers/fixtures?
- Tests that pass but don't assert meaningful outcomes?
- Is test code held to the same quality standards as production code?

Flakiness risk:
- Timing dependencies, race conditions, order-sensitive assertions?
- Async operations not properly awaited or mocked?

For each issue: file:line | what's wrong | specific fix
If tests are well-designed, report "Test design is solid and coverage is appropriate."
```

---

### Agent 7: Security

```
Review the changed files for security issues.

**Return findings in 200 words or fewer. Report your top 3 issues only, ordered by severity. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.claude/references/README.md`, then `~/.claude/references/security.md` and `~/.claude/references/privacy.md`. Use these invariants as your evaluation criteria.
2. Search for project docs defining standards or preferences (README.md, CONTRIBUTING.md, docs/, style guides) — CLAUDE.md is already loaded. Use them to inform your review.
3. Run the diff command from Context to read what changed, then read surrounding context.

Review for:
- Input validation at system boundaries (APIs, CLI args, file uploads, env vars)
- Injection risks: SQL, command injection, XSS, path traversal
- Authentication and authorization gaps
- Secrets or credentials hardcoded or logged
- Error messages that leak sensitive information (stack traces, internal paths, user data)
- File permissions and access controls
- External dependencies from untrusted sources

For each issue: file:line | what's wrong | severity (Critical/High/Medium/Low) | specific fix
Only report actual security violations, not theoretical what-ifs.
If no issues found, report "No security concerns identified."
```

---

### Agent 8: Operational Health

```
Review the changed files for performance and observability concerns.

**Return findings in 200 words or fewer. Report your top 3 issues only, ordered by severity. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.claude/references/README.md`, then `~/.claude/references/operational-health.md`, `~/.claude/references/performance.md`, and `~/.claude/references/concurrency.md`. Use these invariants as your evaluation criteria.
2. Search for project docs defining standards or preferences (README.md, CONTRIBUTING.md, docs/, style guides) — CLAUDE.md is already loaded. Use them to inform your review.
3. Run the diff command from Context to read what changed, then read surrounding context.
4. Check how similar operations are handled in unchanged files — both for performance patterns and existing logging/metrics conventions.

Performance:
- N+1 queries or repeated fetches inside loops
- Blocking operations in async contexts
- Missing memoization or caching where appropriate
- Memory leaks: unclosed connections, resources, growing collections
- Missing pagination for potentially large datasets
- Expensive operations in hot paths (per-request, per-item, per-frame)
- Algorithmic inefficiency (O(n²) where O(n) is straightforward)

Observability:
- Does new behavior have corresponding logging, metrics, or analytics?
- Are new error paths surfaced (logged, tracked) or silently swallowed?
- Were existing logging or tracing calls changed or removed — is that intentional?
- If this fails in production, how would we know? Is the failure diagnosable from logs alone?
- Are log messages at appropriate levels with enough context to act on?

For each issue: file:line | what's wrong | concrete impact | specific fix
Only report actual problems, not theoretical micro-optimizations.
If no issues found, report "No operational health concerns identified."
```

---

### Agent 9: Documentation

```
Review whether the changed code is properly documented — check for stale docs and missing docs,
including .md files, diagrams, help text, docstrings, and code comments.

**Return findings in 200 words or fewer. Report your top 3 issues only, ordered by severity. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.claude/references/README.md`, then `~/.claude/references/documentation.md`. Use these invariants as your evaluation criteria.
2. Run the diff command from Context to read what changed.
3. Find all documentation that could be affected:
   - All .md files: `find . -name "*.md" -not -path "*/node_modules/*" -not -path "*/.git/*"`
   - Diagrams: look for .svg, .png, .drawio, .mermaid, or docs/diagrams/ directories
   - Docstrings and help text in changed source files
   - Code comments in changed files and closely related unchanged files
3. Read the docs most likely to describe the changed behavior.

Stale docs:
- Do existing .md files, diagrams, or help text describe behavior that was changed or removed?
- Are examples, command signatures, config keys, flags, or APIs in the docs now wrong?
- Are there code comments in changed files that no longer accurately describe what the code does?

Missing docs:
- Is new behavior, a new flag, a new API, or a new config option undocumented in any .md or help text?
- For public-facing interfaces: is there a docstring or equivalent describing what it does, its inputs, and its outputs?
- For non-obvious code: is there a comment explaining WHY — a hidden constraint, a subtle invariant, a workaround, behavior that would surprise a reader? (Don't flag missing comments for self-explanatory code.)

Changelogs:
- Does the project maintain a changelog? If so, does this change warrant an entry that isn't there?

For each issue: file:line | what's stale or missing | specific fix
If docs are complete and accurate, report "Documentation is up to date."
```

---

### Agent 10: Dependencies & Deployment

```
Review the changed files for dependency and deployment concerns.

**Return findings in 200 words or fewer. Report your top 3 issues only, ordered by severity. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.claude/references/README.md`, then `~/.claude/references/dependencies-deployment.md`. Use these invariants as your evaluation criteria.
2. Search for project docs defining standards or preferences (README.md, CONTRIBUTING.md, docs/, style guides) — CLAUDE.md is already loaded. Use them to inform your review.
3. Run the diff command from Context to read what changed.
4. If package files changed, read them in full.

Dependencies (if package files changed):
- Are new dependencies justified? Could existing deps cover this?
- Are dependencies well-maintained? (check for recent activity, known issues)
- Frontend deps: impact on bundle size?

Breaking changes (if public APIs or exports changed):
- Are any public interfaces, types, or exports modified?
- Would existing consumers break?
- Is a version bump needed? (major for breaking, minor for features, patch for fixes)

Deployment safety:
- Database migrations that could fail or lock tables?
- Backward compatibility with existing data/state in production?
- Deployment ordering issues? (config changes, service dependencies)
- Would a feature flag help with safe rollout?
- Could this be rolled back safely if issues arise?

For each issue: file:line | what's wrong | specific recommendation
If no concerns found, report "No dependency or deployment concerns identified."
```

---

## Step 4: Present findings

Collect all agent results. Focus on the 3–5 most impactful issues per severity tier; collapse agents with no findings to a single line.

```
## Code Review

### Verdict: [Approve | Request Changes | Comment]
[One sentence on what to do next]

### What's Working Well
- `file:line` — [specific praise grounded in actual code]

### All Clear
- [Agent name]: [one-line summary — e.g. "no issues found" or "12 tests passed"]

### Issues

#### Must Fix

1. `file:line` — [what's wrong; why it matters]
   - (a) [recommended fix]
   - (b) [alternative if meaningfully different]

#### Should Fix

2. `file:line` — [what's wrong; why it matters]
   - (a) [recommended fix]
   - (b) [alternative if meaningfully different]

#### Consider

3. `file:line` — [observation or suggestion]
   - (a) [one approach]
   - (b) [another approach]

### Open Questions

4. `file:line` — [genuine uncertainty or design decision]
   - (a) [one path and its tradeoff]
   - (b) [another path and its tradeoff]
```

**Verdict mapping:**

- **Approve** — no Must Fix issues; Should Fix and Consider items are optional
- **Request Changes** — one or more Must Fix issues present
- **Comment** — open questions or suggestions worth discussing, nothing blocking

## Step 5: Post review (PR scope only)

A helper script lives at `scripts/post_review.py` relative to this skill's base directory (shown at the top of this skill's content as "Base directory for this skill: ...").

After presenting findings, ask:

> "Post this as a GitHub review? (yes / approve / request-changes / comment / skip)"

On any answer other than "skip":

- Map to GitHub event: yes → use verdict from Step 4; approve → APPROVE; request-changes → REQUEST_CHANGES; comment → COMMENT
- Write a 2–3 sentence overall summary for the review body in a friendly tone
- Collect every finding that has a `file:line` reference as an inline comment
- Run:

```bash
python3 <skill-base-dir>/scripts/post_review.py <pr-number> <EVENT> "<summary>" "<file>:<line>:<body>" ...
```

**Tone for inline comment bodies:** Write as a curious teammate, not an auditor.

- Lead with an observation or question, not a directive: "Could this return `None` when the list is empty?" rather than "Handle the empty case."
- Show concrete impact with a brief example: "If `token` expires between the check and the refresh, this would issue a new token for an expired session."
- Acknowledge trade-offs where they exist: "This works well at our current scale — if we ever fan out to multiple instances, we'd likely want a shared cache here."
- Praise specifically and genuinely: "Nice! Using a `dataclass` here makes the shape obvious without extra boilerplate."
