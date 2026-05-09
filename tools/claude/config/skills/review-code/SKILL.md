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

### Agent 1: Intent Alignment

```
Question: Does the implementation actually achieve the stated intent of this change?

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

### Agent 2: Approach

```
Question: Is this the simplest correct solution to the stated problem, and is it the best available approach?

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

Simplicity check — ask this first:
What is the minimum code that correctly solves the stated problem? Compare it to what was written. If the answer is substantially less, that gap is the most important finding. Look for:
- Abstractions for a single call site, or layers that exist for one use case
- Problems being solved that were never stated — hypothetical future requirements, speculative flexibility
- Existing utilities, patterns, or libraries in the project or standard library that would make this trivial
- Complexity whose justification isn't obvious to a competent reader of the problem statement

Also consider whether a meaningfully better approach exists on these axes:
- More reliable: fewer failure modes, better error recovery
- More idiomatic: uses the language or framework as intended
- More expressive: intent is immediately obvious without reading the implementation

Ground every observation in the actual code and the problem being solved. Don't flag superficial rewrites.

If a simpler or better approach exists: describe it concretely, explain what makes it better, and note the cost of switching.
If the approach is well-chosen: report "Approach is well-suited to the problem."
```

---

### Agent 3: Structure

```
Question: Is the internal organisation of this code sound?

**Return findings in 200 words or fewer. Report your top 3 issues only, ordered by severity. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.claude/references/README.md`, then `~/.claude/references/architecture.md`, `~/.claude/references/design.md`, and `~/.claude/references/code-quality.md`. Use these invariants as your evaluation criteria.
2. Search for project docs defining standards or preferences (README.md, CONTRIBUTING.md, docs/, style guides) — CLAUDE.md is already loaded. Use them to inform your review.
3. Run the diff command from Context to read what changed.
4. Read related unchanged files to understand existing structural patterns and conventions.

Boundaries & dependencies:
- Do dependencies flow in one direction? Are there cycles or upward imports?
- Do implementation details leak across component boundaries?
- Are side effects (I/O, mutation) at the edges, with pure logic in the middle?

Internal design:
- Does each function or type have one responsibility?
- Are abstractions used in more than one place, or only at a single call site?
- Does complexity match the problem — not over-engineered, not under-separated?
- Do existing patterns get followed, or is the same problem solved a new way without reason?

Code clarity:
- Is there dead code, unused imports, or commented-out remnants?
- Do names reflect intent without abbreviation?
- Are files and functions sized to be reasoned about (files under 2000 lines, functions without excessive nesting)?

For each issue: file:line | what's wrong | specific alternative
If structure is sound, report "Structure and internal organisation look solid."
```

---

### Agent 4: Public Surface

```
Question: From the caller's perspective, is this code well-designed and discoverable?

**Return findings in 200 words or fewer. Report your top 3 issues only, ordered by severity. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.claude/references/README.md`, then `~/.claude/references/type-design.md`, `~/.claude/references/api-design.md`, and `~/.claude/references/documentation.md`. If the project has a CLI binary or command-line interface, also load `~/.claude/references/cli-design.md`. Use these invariants as your evaluation criteria.
2. Search for project docs defining standards or preferences (README.md, CONTRIBUTING.md, docs/, style guides) — CLAUDE.md is already loaded. Use them to inform your review.
3. Run the diff command from Context to read what changed.
4. Find all documentation that could be affected: .md files, help text, docstrings, CLI --help output, code comments in changed files.

Types & interfaces:
- Are domain-specific types used instead of primitives where intent would be clearer?
- Do types make invalid states unrepresentable?
- Does a function transform its input into a more specific type, or return the same type it received?
- Is the public surface minimal — only what callers need?

API & CLI design:
- Is the API designed from the caller's perspective, not the implementation's?
- Is naming consistent across the public surface?
- For CLIs: does every command and flag have help text? Do errors go to stderr? Are exit codes meaningful?

Documentation:
- Do existing .md files, diagrams, or help text describe behavior that was changed or removed?
- Is new behavior, a new flag, a new API, or a new config option documented?
- For non-obvious code: is there a comment explaining WHY — a hidden constraint, a workaround, behavior that would surprise a reader?

For each issue: file:line | what's wrong | specific fix
If the public surface is well-designed and documented, report "Public surface is well-designed and documented."
```

---

### Agent 5: Correctness

```
Question: Does this code behave correctly across all inputs, states, and callers?

**Return findings in 200 words or fewer. Report your top 3 issues only, ordered by severity. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.claude/references/README.md`, then `~/.claude/references/correctness.md`, `~/.claude/references/assertions.md`, and `~/.claude/references/error-handling.md`. Use these invariants as your evaluation criteria.
2. Search for project docs defining standards or preferences (README.md, CONTRIBUTING.md, docs/, style guides) — CLAUDE.md is already loaded. Use them to inform your review.
3. Run the diff command from Context to read what changed. For files under 500 lines, read the full file. For larger files, read each changed section plus ~30 lines of context.
4. Read 2-3 similar unchanged files to understand existing patterns for error handling and validation.

Logic & edge cases:
- Logic errors, off-by-one errors, incorrect conditionals
- Missing edge cases (empty input, null/None/zero, single-element, boundary values)
- All reachable branches handled

Error handling:
- Errors propagated consistently with surrounding code
- Errors enriched with context as they cross boundaries
- Internal details not exposed to callers
- Domain errors (not found, validation failed) distinguished from programming errors (assertion violation)

Assertions:
- Preconditions and postconditions asserted where invariants must hold
- Assertions cover both what must be true and what must never be true

For each issue: file:line | what's wrong | concrete impact | specific fix
Skip theoretical what-ifs — report actual problems in the code.
```

---

### Agent 6: Data Safety

```
Question: Is data protected from external threats, personal data mishandling, and write-time corruption?

**Return findings in 200 words or fewer. Report your top 3 issues only, ordered by severity. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.claude/references/README.md`, then `~/.claude/references/security.md`, `~/.claude/references/privacy.md`, and `~/.claude/references/data-integrity.md`. Use these invariants as your evaluation criteria.
2. Search for project docs defining standards or preferences (README.md, CONTRIBUTING.md, docs/, style guides) — CLAUDE.md is already loaded. Use them to inform your review.
3. Run the diff command from Context to read what changed, then read surrounding context.
4. If database models or migrations changed, read them in full.

Security:
- Input validation at system boundaries (APIs, CLI args, file uploads, env vars)
- Injection risks: SQL, command injection, XSS, path traversal
- Authentication and authorization gaps
- Secrets or credentials hardcoded or logged
- Error messages leaking sensitive information (stack traces, internal paths, user data)

Privacy:
- PII appearing in logs, error messages, traces, or analytics
- Personal data collected without a stated purpose, or retained indefinitely
- Deletion paths that leave data accessible in secondary stores

Data integrity:
- Invalid data reachable by persistent storage (missing validation or DB constraints)
- Multi-step writes not wrapped in transactions where partial failure would corrupt state
- Read-modify-write patterns missing concurrency protection
- Migrations that break existing data or are irreversible without a compensating path

For each issue: file:line | what's wrong | severity (Critical/High/Medium/Low) | specific fix
Only report actual violations, not theoretical what-ifs.
If no concerns found, report "No data safety concerns identified."
```

---

### Agent 7: Runtime Behaviour

```
Question: How does this code behave under real-world conditions — load, failure, and concurrency?

**Return findings in 200 words or fewer. Report your top 3 issues only, ordered by severity. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.claude/references/README.md`, then `~/.claude/references/performance.md`, `~/.claude/references/concurrency.md`, `~/.claude/references/reliability.md`, and `~/.claude/references/observability.md`. Use these invariants as your evaluation criteria.
2. Search for project docs defining standards or preferences (README.md, CONTRIBUTING.md, docs/, style guides) — CLAUDE.md is already loaded. Use them to inform your review.
3. Run the diff command from Context to read what changed, then read surrounding context.
4. Check how similar operations are handled in unchanged files.

Performance:
- N+1 queries or repeated I/O inside loops
- Algorithmic inefficiency (O(n²) where O(n) is straightforward)
- Expensive operations in hot paths
- Large datasets loaded into memory rather than paginated or streamed

Concurrency:
- Unprotected access to shared mutable state
- Async operations not awaited; blocking operations in async contexts
- Unbounded queues or thread pools; inconsistent lock acquisition order

Reliability:
- External calls (network, DB, APIs) without explicit timeouts
- Transient failures retried without bounded backoff, or permanent failures retried as transient
- Failures in one dependency cascading to unrelated operations

Observability:
- New behavior without corresponding log output
- Error paths silently swallowed
- If this fails in production, would we know? Is the failure diagnosable from logs alone?

For each issue: file:line | what's wrong | concrete impact | specific fix
Only report actual problems, not theoretical micro-optimizations.
If no concerns found, report "No runtime behaviour concerns identified."
```

---

### Agent 8: Testing

```
Question: Is the test suite trustworthy and sufficient to catch regressions in this change?

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

Coverage (with ROI lens):
- Do the tests provide evidence the changes work across all logical branches?
- Are critical paths tested? (auth, payments, data integrity, error paths)
- Specify exact missing cases: not "add tests" but "add tests for: expired token, missing token, wrong signature"

Test design:
- Do tests verify behavior, not implementation details?
- Are assertions focused on outcomes callers care about?
- Will these tests break for the wrong reasons? (brittle selectors, testing internals)
- Is each test focused on one behavior — one reason to fail?

Technique:
- Could similar test cases collapse into one parametrized test?
- Is property-based testing applicable where the input space is large?
- Are mocks used only at system boundaries (external APIs, time, randomness)?

Test code quality:
- Copy-pasted setup that should be extracted to helpers or fixtures?
- Tests that pass but don't assert meaningful outcomes?
- Flakiness risk: timing dependencies, order-sensitive assertions, async not awaited?

For each issue: file:line | what's wrong | specific fix
If tests are well-designed, report "Test design is solid and coverage is appropriate."
```

---

### Agent 9: Release Readiness

```
Question: Is this change ready to ship responsibly — dependencies justified, deployment safe, config correct?

**Return findings in 200 words or fewer. Report your top 3 issues only, ordered by severity. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Read `~/.claude/references/README.md`, then `~/.claude/references/dependencies.md`, `~/.claude/references/deployment.md`, and `~/.claude/references/config.md`. Use these invariants as your evaluation criteria.
2. Search for project docs defining standards or preferences (README.md, CONTRIBUTING.md, docs/, style guides) — CLAUDE.md is already loaded. Use them to inform your review.
3. Run the diff command from Context to read what changed.
4. If package files changed, read them in full. If config or env handling changed, read those files in full.

Dependencies (if package files changed):
- Are new dependencies justified? Could existing deps cover this?
- Are dependencies well-maintained? (recent activity, known vulnerabilities)
- Frontend deps: impact on bundle size?

Deployment safety:
- Database migrations that could fail or lock tables?
- Deployment ordering issues? (consumer coordination, service dependencies)
- Could this be rolled back safely if issues arise?
- Would a feature flag help with safe rollout?

Configuration (if config or env handling changed):
- Is config validated at startup rather than lazily?
- Is config parsed into typed structs at the boundary?
- Are all config keys documented?

For each issue: file:line | what's wrong | specific recommendation
If no concerns found, report "No release readiness concerns identified."
```

---

### Agent 10: Language

```
Question: Does this code use the language correctly, following the project's established idioms?

**Return findings in 200 words or fewer. Report your top 3 issues only, ordered by severity. If nothing found, say so in one sentence.**

Context:
[insert synthesized intent block]

Changed files:
[insert file list]

Instructions:
1. Identify which programming languages are present in the changed files by file extension (`.rs` → Rust, `.py` → Python).
2. Read `~/.claude/references/README.md`, then load only the reference files that apply: `~/.claude/references/rust.md` if Rust files are present, `~/.claude/references/python.md` if Python files are present.
3. If no language-specific reference files apply to the changed files, report "No language-specific reference files apply to this change." and stop.
4. Otherwise, run the diff command from Context to read what changed.

Apply the loaded invariants to the changed files. Look for violations specific to the language — idioms, error handling patterns, type system conventions, and anti-patterns called out in the reference files.

For each issue: file:line | what's wrong | specific fix
If no language-specific issues found, report "No language-specific concerns identified."
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
