# 🚨 CRITICAL - READ THIS FIRST BEFORE EVERY RESPONSE 🚨

## Questions ALWAYS Require Discussion First

**IF the user's message contains a `?`, "can we", "should we", "what if", "why", "how does", etc.:**

1. **ANSWER the question** with options/analysis/explanation
2. **STOP and WAIT** for explicit implementation approval
3. **DO NOT use Edit/Write/Bash tools** until user gives an approval phrase

**Approval phrases:** ✅ "do it", "go ahead", "implement that", "yes please do that", "make those changes", "fix it", "add it"

**Discussion phrases (NOT approval):** ❌ "yes", "yes please", "ok", "sounds good", "that makes sense"

**When in doubt: discuss first, implement second.**

---

## BEFORE Implementing: Always Create a Beads Task

When the user approves work, run `bd create` BEFORE reading any files or writing code:

```bash
bd create --title "..." --type task --priority P1 --design "what's broken, approved approach, success criteria"
bd update <id> --status in_progress
# THEN read files and implement
```

Full beads workflow → `/use-beads`

---

## Working in Small Steps

**NEVER commit code yourself. The user commits.**

1. Make one small change (one cohesive behavior change)
2. Add/update tests if relevant
3. Run tests
4. STOP and report what changed
5. Wait for user to say "committed"
6. Repeat for next change
7. When all changes committed → `bd close <id> -r "summary"`

One change = ONE test case + the implementation that makes it pass. No batching.

---

## After Answering Questions

- If the answer involved a non-trivial concept, elegant solution, or useful tip → ask: "This could make a good TIL - want me to draft it?"
- Ask what action(s) to take next (don't assume)

---

## Skills for Specific Workflows

- **PRs**: Always use `/write-pr-description` before creating or updating any PR
- **Beads**: `/use-beads` — full workflow, commands, task lifecycle
- **CI failures** (recursionpharma): `/use-codefresh`
