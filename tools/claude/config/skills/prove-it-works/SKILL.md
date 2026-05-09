---
name: prove-it-works
description: Provide convincing evidence that the code actually achieves its intended outcomes and does what it is expected to do runtime across all logical branches and edge cases. TRIGGER whenever the user asks you to prove, demonstrate, or provide hard evidence that code works as expected at runtime.
argument-hint: '[scope]'
effort: high
model: opus
---

## Context

- The scope of the codebase the user wants to discuss is what they mentioned here: $ARGUMENTS
- If they didn't mention anything, assume they meant the changes on this branch
- If you're not sure exactly what the user wants you to prove works, as them

## Your task

### Phase 1: Understand the code's intent and invariants

1. Read `~/.claude/references/README.md` and the reference files relevant to this code's domain
   to identify which invariants apply (correctness, security, data integrity, type design, etc.).
2. Use as many subagents as you need to explore all relevant code paths and documentation that could
   help you understand the intended behaviour of the code in question, the local and system-level
   invariants that apply to its behaviour (and especially its side effects), and the observable
   outputs available to validate that behaviour from the outbox in while treating the system's
   implementation as a black box
2. Proactively answer every question and follow-up question that occurs to you by exploring the
   codebase and anything else that would help you
3. Wait for all subagents to return their results
4. Ensure you understand the results you have received and are equipped to make a plan for how to
   run the code in question like it runs in production and record definitive proof (e.g. screen
   recordings, screenshots, etc) convincingly proving the extent to which the code's behaviour does
   and does not currently match its intended behaviour and does and does not currently uphold all
   required invariants;
5. Once you understand the code, its intended behaviour, the applicable invariants, and what proof
   you will provide in the HTML slide deck you will share after your testing, this phase is done

### Phase 2: Present your validation plan

1. Clearly summarize your understanding of the code's expected behaviour (in all cases), the local
   and system level invariants that apply to it, and what evidence you intend to embed in an HTML
   slide deck as part of your report that will prove that each claim you make is true
1. **Hard constraint on evidence sources:** Every piece of evidence must come from running the real
   system — the actual process, the actual database, the actual log output. Specifically:
   - **Automated tests do not count** — not as proof, not even as a component of proof. Their
     pass/fail result tells you nothing about whether the code works at runtime.
   - **No mocking, no test fixtures, no `pytest`** — only the system running as it runs in
     production: real process, real DB, real I/O, real log lines.
   - For each claim, state concretely: what command you will run, what process output or DB query
     result you will capture, and how that output proves the claim.
   - If you find yourself reaching for a test file to prove something, stop and ask: "how would I
     observe this behaviour if I had no test suite at all?" That is the question to answer.
1. If starting by emitting additional observability signals would improve your ability to provide
   evidence of current behaviour, propose those changes (they will likely be gratefully approved)
1. Wait for the user's response
1. Apply any feedback and wait for explicit approval before you move to the next phase

### Phase 3: Run all code paths and collect evidence

1. Execute your testing plan using as many subagents as you need
2. Wait for all subagents to return their results
3. Ensure every code path has been executed
4. Ensure every intended behaviour has been validated with hard evidence backing up every claim
5. Ensure every property/invariant has been validated with hard evidence backing up every claim
6. Ensure all evidence of the system's observable behaviour and adherence to its required
   properties/invariants is convincing (e.g. a screen recording, screenshot, etc) and not a
   baseless claim or reference to automated testing results (which do NOT count as validation)
7. When all observable behaviour and invariants have been checked and all evidence has been
   collected, this phase is done

### Phase 4: Present your findings

1. Present your prioritized findings to the user, ensuring a summary table is included near the end
   of your response for clarity and each intended behaviour and invariant is treated as its own
   category
2. Generate a self-contained HTML slide deck of the prioritized findings:
   - `mkdir -p .outputs/<yyyy-mm-dd>/<branch>`
   - Write the report to `.agents/<date>/<branch>/validation-findings.html` — use clean, minimal styling,
     one slide per category plus a summary/title slide, and keyboard arrow-key and click navigation
     between slides
   - `open .agents/<date>/<branch>/validation-findings.html`
3. Recommend a next action and wait for the user's response
