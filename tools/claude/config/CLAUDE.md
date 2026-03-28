## Questions ALWAYS Require Discussion First

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
- Prefer working in thin vertical slices rather that unintegrated horizontal layer changes since those tracer bullets can be validated e2e much earlier

---

## Work in Small Steps

1. Make one small, thematic change (one cohesive behavior change; e.g. one new test and its refactored implementation)
2. Run checks
3. Run tests
4. Prove the change works with manual testing if you can
5. STOP and report what changed; NEVER commit code yourself unless explicitly asked to do so; the user always commits; commit checkpoints are the user's opportunity to review incremental changes
6. Wait for user to say "committed" or "done" (or similar) or explicitly ask you to commit
7. Repeat for the remaining changes
8. When all changes committed → `bd close <id> -r "summary"`

One change = ONE test case + the implementation that makes it pass. No batching.
