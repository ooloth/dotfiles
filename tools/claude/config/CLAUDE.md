## Questions ALWAYS Require A Discussion Before You Act

If the user's message contains a `?`, "can we", "should we", "what if", "why", "how does", "discuss", "propose" etc.:

1. **ANSWER the question** with options/analysis/explanation
2. **STOP and WAIT** for explicit implementation approval or further discussion
3. **DO NOT use Edit/Write/Bash tools** until user gives an approval phrase like "do it", "go ahead", "go for it", "yes please do that", "make those changes", "fix it", "add it"

Discussion phrases like "yes", "ok", "sounds good", "that makes sense" do not necessarily indicate approval.

After answering questions:

- Ask what action(s) to take next (don't assume)
- When in doubt: confirm the user is ready for you to implement

---

## BEFORE Implementing: Always Create a Beads Task

When the user approves work, run `bd create` BEFORE reading any files or writing code to ensure the plan has been captured:

```bash
bd create --title "..." --type task --priority P1 --design "what's broken, approved approach, success criteria"
bd update <id> --status in_progress
# THEN read files and implement
```

Always use `bd` to manage tasks and persist the outcome of discussions with the user. For the full beads workflow, see `/use-beads`.

## Validate Every Change

- Compare all assumptions about an implementation to concrete feedback immediately
- Manual testing is just as important as automated testing
- Prefer working in thin vertical slices rather than unintegrated horizontal layer changes since those tracer bullets can be validated e2e much earlier
- After every commit-worthy change, ask: "can I run this and observe it working?" If the answer is yes — do it before reporting the change is ready. Run the CLI, hit the endpoint, trigger the event, eyeball the output. If a change adds or modifies user-facing behavior and you don't exercise it end-to-end before presenting it, assume something is broken that the tests didn't catch.
- When end-to-end execution isn't possible (e.g. requires paid API keys, hardware, or third-party state you can't set up), say so explicitly and describe what you would run and what you would look for. Don't silently skip validation.
- Assume backwards-compatibility is unnecessary and would introduce unwanted complexity unless the user specifically tells you it's needed

---

## Work in Small Steps

1. Make one small, thematic change (one cohesive behavior change; e.g. one new test and its refactored implementation)
2. Run checks
3. Run tests
4. Prove the change works with manual testing if you can
5. STOP and report what changed; NEVER commit code yourself unless the user explicitly asks you to commit THIS specific change. Prior commit requests do not carry forward — each commit requires its own approval. (This applies to development workflow commits. Commands that commit as part of their designed operation — e.g. an agentic ralph loop — are approved when the user approves the run.)
6. Wait for the user to review and commit (or explicitly ask you to commit). Phrases like "committed", "done", or "commit" are your signal to proceed to the next change.
7. Repeat for the remaining changes
8. When all changes committed → `bd close <id> -r "summary"`

One change = ONE test case + the implementation that makes it pass. No batching.
