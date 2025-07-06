## Git Workflow

### Commit Strategy

- Create logical, atomic commits that can be reviewed independently
- Each commit should represent a single conceptual change
- Commit related changes together (e.g., function + tests + documentation)
- Separate refactoring commits from feature commits
- Use descriptive commit messages that explain the "why" not just the "what"

### Pre-commit Checks (in order)

1. **Formatting** - Run code formatters first (prettier, black, rustfmt, etc.)
2. **Linting** - Run linters after formatting
3. **Type checking** - Run type checkers
4. **Tests** - Run relevant tests last
5. **Final review** - Check `git diff --staged` to review what will be committed
6. **Security check** - Verify no sensitive information (keys, tokens, passwords) is included

### When Pre-commit Checks Fail

- **Formatting failures**: Auto-fix and stage the formatted changes, then retry commit
- **Linting failures**: Fix the issues, stage the fixes, then retry commit
- **Type checking failures**: Fix type errors, stage the fixes, then retry commit
- **Test failures**: Fix failing tests, stage the fixes, then retry commit
- If any check fails twice, report the issue and ask for guidance
- Always include auto-fixes in the same commit when possible

### Multi-commit Guidelines

- When asked to commit multiple changes, organize them logically:
  1. Setup/configuration changes first
  2. Core functionality changes
  3. Tests and documentation last
- Each commit should leave the codebase in a working state
- Prefer merge commits over rebasing to preserve commit history

### Branch Management

- Create descriptive branch names (feature/add-metrics, fix/memory-leak, etc.)
- Keep branches focused on a single feature or fix
- Use merge commits to integrate branches (avoid rebasing)

### PR Preparation

- Before pushing, review the full diff with `git diff main...HEAD`
- Ensure commit messages follow conventional format
- Split large changes into multiple PRs when possible
- Include context about why changes were made, not just what changed

When pre-commit checks fail, I'll fix the issues, stage the fixes, and automatically retry the commit to keep the workflow smooth.
