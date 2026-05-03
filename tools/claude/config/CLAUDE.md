# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

---

## Protect Your Context Window

- Your context window has a limited budget and fills up quickly
- Try to prevent that from happening by delegating as much exploration as you can to subagents
- That will prevent intermediate/irrelevant details from accumulating and optimize for relevant
  details only entering the conversation

## Explicitly Confirm You Should Act (Especially After Questions)

If the user's message contains a `?`, "can we", "should we", "what if", "why", "how does", "discuss", "propose" etc, have a discussion:

1. **Clarify** what the user is asking (if unsure)
2. **Proactively explore** the codebase and any other relevant sources using as many subagents as needed to deeply understand the subject matter
3. **ANSWER the question** with options/analysis/explanation
4. **STOP and WAIT** for explicit implementation approval to act or further discussion to reply to (returning to Step 1)
5. **DO NOT take any action with side effects** until user gives an approval phrase like "do it", "go ahead", "go for it", "yes please do that", "make those changes", "fix it", "add it"

This applies to **all side effects**, not just file edits — GitHub comments, issue state changes, PR creation, API calls, shell commands that mutate state, etc. If the action changes anything the user would need to know about, present your plan and wait. External/public side effects (e.g. posting a comment visible to others) require the same approval gate as code changes — arguably more so, since they cannot be locally reverted.

Discussion phrases like "yes", "ok", "sounds good", "that makes sense" do not necessarily indicate approval.

Explicitly confirm if the user is ready for you to implement and for the discussion to end before you act (when in doubt, assume the user hasn't approved yet).

If your thinking later leads you to modify the approved plan (e.g. want to make new design decisions), stop and discuss those rather than quietly making an executive decision.

**Open design questions void prior approval.** If implementation depends on an unresolved design choice (e.g. which name, which approach, which pattern), present the options and stop — even if you already have approval for the parent task. Prior approval does not extend through an open question; resolve it first, then implement.

**A response that asks a question must contain no side-effecting tool calls.** If you write "Agree?", "Which would you prefer?", or any other question seeking user input, that response cannot also call Edit, Write, Bash (mutating), or any other tool that changes state. Asking and acting in the same turn makes the question rhetorical and bypasses the gate.

**Receiving answers to your questions is not implementation approval.** When the user responds to a list of questions you asked, you are in "answer incorporation" mode — not implementation mode. Even if every question is now answered, your next move is to (1) answer any question they asked back, (2) present the full implementation plan, (3) stop and ask for explicit approval of that plan. A "go ahead" embedded inside a numbered answer to one of your sub-questions means "use that approach for this decision" — it is not approval to begin implementing. Decisions being complete and implementation being approved are two separate gates.

## BEFORE Implementing: Always Create a Trekker Task

When the user approves work, create a `trekker` task BEFORE reading or writing any files to ensure the plan has been captured:

```bash
trekker task create -t "..." -p 1 -d "Problem: ... Approach: ... Done when: ..."
trekker task update TREK-N -s in_progress
# THEN read files and implement
```

Always use `trekker` to manage tasks and persist the outcome of discussions with the user as a crash recovery mechanism (so the next agent can continue without repeating the discussion). For the full `trekker` workflow, see `/use-trekker`.

## Work in Small Steps

1. Make one small, thematic change (one cohesive behavior change; e.g. one new test and its refactored implementation, one new lint rule and its fixes, etc)
2. Run checks
3. Run tests
4. Manually verify the change works. Do not rely on tests alone — run the CLI, hit the endpoint, trigger the event, eyeball the output, whatever applies. The status report in step 5 must include one of:
   - **What you ran and what you observed** (e.g. "ran X, saw Y in the output")
   - **Why end-to-end execution is impossible here** and what the user should run and look for instead
     Omitting this section is not allowed. "Tests pass" is not a substitute.
5. Write a status report. **Do not commit without an explicit user signal** ("commit", "/commit", etc.) — prior approvals do not carry forward to commits, and each commit requires its own signal. (Commits that are part of an autonomous loop are approved when the user approves the run.)
6. When you receive a commit signal, commit via `/commit`. After committing, you may continue implementing the next approved task — but stop and write another status report before committing anything further.
7. Repeat for the remaining changes
8. When all changes committed → close the task:
   ```bash
   trekker comment add TREK-N -a "claude" -c "Resolution: ..."
   trekker task update TREK-N -s completed
   ```
9. After closing, check whether related open tasks need their descriptions updated — the approach may have changed, a prerequisite may now be satisfied, or the task may have become unnecessary

## Validate Every Change

- Prefer batching changes as thin vertical slices (tracer bullets) that can be validated by running the actual system, rather than batching in a single horizontal layer without integrating the new code in any runtime path
- Immediately after every commit-worthy change (and before reporting success), ask yourself: "how can I run this myself and confirm it actually works?"
- Use your ability to run the system locally to confirm what you see happening; if the relevant codepaths are missing the observability signals you need for verification, recommend adding them; if the local dev tools setup is lacking conveniences that would make local verification easier, recommend what to add; in the meantime, feel free to run relevant code paths ad hoc via any creative manual means you can think of; the point is to pile up evidence that the changes actually work and never assume that the code looking right or automated tests passing is enough
- Be creative: run the CLI, hit the endpoint, trigger the event, eyeball the output; this sort of live execution is just as important as automated testing
- If end-to-end execution is truly impossible, tell the user why and describe what they can do and what they should look for. Don't just silently skip validation.

## Issue and Ticket Writing

**NEVER create a GitHub issue, Jira task, Monday task, or Linear task without first invoking the `write-ticket-description` skill.**

## Skill Feedback

After invoking any skill, mention any friction or gaps you noticed — a misleading instruction, an ambiguity that cost time, or anything else you learned that would help a future agent. Report it clearly after completing the skill's task. Skip if execution went smoothly.

## Available CLI tools

- `tmux` - use for background jobs (`tmux new-window -n "dev-server" "npm run dev"`) instead of
  `run_in_background` or `&`. Also use to test interactive programs (TUIs, REPLs): run them in
  a named window, drive them with `tmux send-keys -t <window> "<key>" ""`, and read the screen
  with `tmux capture-pane -t <window> -p`. This is often the only way to visually verify an
  interactive program without asking the user to do it.
- `rg` - consider using instead of `grep`
- `fd` - consider using instead of `find`
- `sd` - consider using instead of `sed`

## Backwards Compatibility Probably Doesn't Matter

- Unless told otherwise, assume backwards-compatibility is unwanted
- In many cases, it adds unnecessary complexity and maintains dead code paths
