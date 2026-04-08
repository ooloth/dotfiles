## Explicitly Confirm You Should Act (Especially After Questions)

If the user's message contains a `?`, "can we", "should we", "what if", "why", "how does", "discuss", "propose" etc, have a discussion:

1. **Clarify** what the user is asking (if unsure)
2. **Proactively explore** the codebase and any other relevant sources using as many subagents as needed to deeply understand the subject matter
3. **ANSWER the question** with options/analysis/explanation
4. **STOP and WAIT** for explicit implementation approval to act or further discussion to reply to (returning to Step 1)
5. **DO NOT use Edit/Write/Bash tools** until user gives an approval phrase like "do it", "go ahead", "go for it", "yes please do that", "make those changes", "fix it", "add it"

Discussion phrases like "yes", "ok", "sounds good", "that makes sense" do not necessarily indicate approval.

Explicitly confirm if the user is ready for you to implement and for the discussion to end before you act (when in doubt, assume the user hasn't approved yet).

If your thinking later leads you to modify the approved plan (e.g. want to make new design decisions), stop and discuss those rather than quietly making an executive decision.

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
4. Prove the change works with manual testing if you can
5. STOP and report what changed; NEVER commit code yourself unless the user explicitly asks you to commit THIS specific change. Prior commit requests do not carry forward — each commit requires its own approval. (This applies to development workflow commits. Commands that commit as part of their designed operation — e.g. an agentic ralph loop — are approved when the user approves the run.)
6. Wait for the user to review and commit (or explicitly ask you to commit). Phrases like "committed", "done", or "commit" are your signal to proceed to the next change.
7. Repeat for the remaining changes
8. When all changes committed → close the task:
   ```bash
   trekker comment add TREK-N -a "claude" -c "Resolution: ..."
   trekker task update TREK-N -s completed
   ```
9. After closing, check whether related open tasks need their descriptions updated — the approach may have changed, a prerequisite may now be satisfied, or the task may have become unnecessary

## Validate Every Change

- Prefer batching changes as thin vertical slices (tracer bullets) that can be validated e2e, rather than batching in a single horizontal layer without integrating the new code in any runtime path
- Immediately after every commit-worthy change (and before reporting success), ask yourself: "how can I run this myself and confirm it actually works?"
- Use your ability to do local e2e runs to confirm what you see happening; if the relevant codepaths are missing the observability signals you need for verification, recommend adding them; if the local dev tools setup is lacking conveniences that would make local verification easier, recommend what to add; in the meantime, feel free to run relevant code paths ad hoc via any creative manual means you can think of; the point is to pile up evidence that the changes actually work and never assume that the code looking right or automated tests passing is enough
- Be creative: run the CLI, hit the endpoint, trigger the event, eyeball the output; this sort of manually smoke testing is just as important as automated testing
- If end-to-end execution is truly impossible, tell the user why and describe what they can do and what they should look for. Don't just silently skip validation.

## Use Rust equivalents of UNIX tools

- Use `rg` instead of `grep`
- Use `fd` instead of `find`
- Use `sd` instead of `sed`

## Backwards Compatibility Probably Doesn't Matter

- Unless told otherwise, assume backwards-compatibility is unwanted
- In many cases, it merely adds unnecessary complexity by maintaining dead code paths and logic for choosing them
