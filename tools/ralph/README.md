# Ralph Loop

Autonomous AI coding loop that ships features while you sleep.

Based on the [ralph technique](https://ghuntley.com/ralph/) by Geoffrey Huntley, with enhancements from [Ryan Carson's implementation](https://x.com/ryancarson/article/2008548371712135632).

## How It Works

A bash loop that:
1. Pipes a prompt into Claude
2. Claude picks next task from prd.json
3. Claude implements it
4. Claude runs verification (tests, types, lint)
5. Claude self-reviews against acceptance criteria
6. Claude commits if passing
7. Claude marks task done
8. Loop repeats until complete

Memory persists only through:
- Git commits
- `.ralph/progress.txt` (learnings)
- `.ralph/prd.json` (task status)

## Installation

```bash
cd tools/ralph
./install.sh
```

This creates a symlink at `~/.local/bin/ralph` pointing to `ralph.sh`.

### How the Symlink Approach Works

1. **Script location**: `tools/ralph/ralph.sh` (in your dotfiles)
2. **Symlink location**: `~/.local/bin/ralph` (in your PATH)
3. **When you run `ralph`**: shell looks in PATH, finds symlink, executes actual script

**Why symlink instead of copying?**
- Edits to `tools/ralph/ralph.sh` are immediately active (no re-install)
- Single source of truth in your dotfiles repo
- Can commit changes and sync across machines

**Why `~/.local/bin`?**
- Standard Unix convention for user-installed executables
- Doesn't require sudo (unlike `/usr/local/bin`)
- Already in PATH on most systems (or easy to add)

## Usage

### 1. Create .ralph/ Directory

In your project, create `.ralph/` with 4 files:

```bash
.ralph/
├── config.json      # Project verification commands
├── prompt.md        # Instructions for each Claude iteration
├── prd.json         # Tasks with acceptance criteria
└── progress.txt     # Learnings accumulate
```

See "File Structure" below for details.

### 2. Run Ralph

```bash
cd /path/to/your/project
ralph

# Or specify max iterations (default: 50)
ralph 25
```

### 3. Monitor Progress

```bash
# Watch task status
cat .ralph/prd.json | jq '.userStories[] | {id, title, passes}'

# See learnings
cat .ralph/progress.txt

# Recent commits
git log --oneline -10
```

### 4. Cleanup

After feature ships and PR merges:
```bash
rm -rf .ralph/
```

## File Structure

### config.json

Project-level verification commands (reused across features):

```json
{
  "verification": {
    "tests": "bun test",
    "types": "tsc --noEmit",
    "lint": "eslint .",
    "build": "bun run build"
  },
  "codebaseContext": "See CLAUDE.md and git log for patterns",
  "branchPrefix": "ralph/"
}
```

### prompt.md

Instructions for each Claude iteration:

```markdown
# Ralph Instructions

## Your Job Each Iteration

1. **Read context:**
   - `git log --oneline -10` (what's been done)
   - `.ralph/prd.json` (tasks and status)
   - `.ralph/progress.txt` (learnings from prior iterations)

2. **Pick next task:**
   - Highest priority where `passes: false`

3. **Implement:**
   - Make the changes
   - Write/update tests

4. **Self-review:**
   - Read your changes: `git diff`
   - Does it meet ALL acceptance criteria?
   - Any edge cases missed?
   - Test coverage complete?

5. **Verify:**
   - Run all checks from `.ralph/config.json`
   - All must pass

6. **Commit:**
   - If all checks pass: `git commit -m "feat(US-XXX): [description]"`
   - Update prd.json: `"passes": true`
   - Append learnings to progress.txt
   - Exit with: `<promise>NEXT</promise>`

7. **If stuck:**
   - Add notes to prd.json
   - Exit with code 1 (stops loop)

8. **If all tasks done:**
   - Exit with: `<promise>COMPLETE</promise>`

## Feature Goal
[Your feature description]

## Self-Review Checklist
- [ ] Meets ALL acceptance criteria
- [ ] Tests comprehensive (happy path + edge cases)
- [ ] All verification commands pass
- [ ] No shortcuts or placeholders
- [ ] Follows patterns in CLAUDE.md
```

### prd.json

Tasks with acceptance criteria:

```json
{
  "branchName": "ralph/add-login",
  "userStories": [
    {
      "id": "US-001",
      "type": "feature",
      "title": "Add login form component",
      "acceptanceCriteria": [
        "Email/password fields render",
        "Validates email format",
        "Shows error on invalid input",
        "Tests cover happy path + validation"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

### progress.txt

Initialized with project context, then Ralph appends after each iteration:

```markdown
# Ralph Progress Log
Started: 2025-01-15

## Codebase Patterns
- Migrations: Use IF NOT EXISTS
- React: useRef<Timeout | null>(null)

## Key Files
- db/schema.ts
- app/auth/actions.ts

---

## 2025-01-15 - US-001
- Implemented login form component
- Files changed: app/login/page.tsx, app/login/form.test.tsx
- **Learnings:**
  - Form validation uses Zod schema
  - Tests require mocking auth server action

---
```

## When NOT to Use

- Exploratory work (unclear requirements)
- Major refactors without clear acceptance criteria
- Security-critical code requiring human review
- Work requiring frequent human judgment calls

## Future Enhancements

- `/prd` command to generate .ralph/ files via interview
- Adversarial review pattern (separate reviewer iterations)
- Parallel feature support (subdirectories per feature)
- Browser testing integration

## Uninstallation

```bash
cd tools/ralph
./uninstall.sh

# Or manually:
rm ~/.local/bin/ralph
```
