## Git Workflow

### Commit Strategy

- Create logical, atomic commits that can be reviewed independently
- Each commit should represent a single conceptual change
- Commit related changes together (e.g., function + tests + documentation)
- Separate refactoring commits from feature commits
- Use descriptive commit messages that explain the "why" not just the "what"

### Development Commit Frequency

- **Commit early and often** during feature development
- Make a commit after completing each logical unit of work:
  - Adding a single function with its test
  - Implementing one specific feature or validation
  - Adding documentation for a single component
  - Fixing one specific issue or bug
- **Never bundle unrelated changes** in a single commit
- **One behavior per commit** - each commit should implement exactly one piece of functionality
- Prefer 10-20 micro-commits over 3-5 larger commits for a feature
- Each commit should leave the codebase in a working state

### Documentation Updates

Include necessary documentation updates in the same commit as the code change:

- **Update code comments** when changing function behavior or adding parameters
- **Update README.md** if adding new setup steps, dependencies, or usage instructions
- **Update existing examples** that would be invalidated by the change
- **Skip excessive documentation** that would quickly become outdated
- **Focus on user-facing changes** that affect how people use the code

Examples:
- ✅ Adding a new CLI flag? Update README.md usage examples in the same commit
- ✅ Changing function parameters? Update the function's comment block
- ✅ Adding a new dependency? Update installation instructions
- ❌ Don't document internal implementation details that change frequently
- ❌ Don't add verbose explanations for self-documenting code

### TDD Commit Strategy

When following Test-Driven Development:
- **Group test and implementation in the same commit** for each feature
- **One test per commit** - exactly one test and its corresponding implementation
- **One validation/function per commit**:
  - Commit: "Add command line tools validation with test"
  - Commit: "Add network connectivity validation with test"
  - Commit: "Add macOS version validation with test"
- This makes each commit focused and easier to review (test and implementation on same screen)
- Each commit contains exactly one testable behavior
- Single test should be the determining factor for what belongs in a commit

### Examples of Good Commit Granularity
- ✅ "Add command line tools validation with test"
- ✅ "Add network connectivity validation with test"
- ✅ "Add macOS version validation with test"
- ✅ "Add dry-run mode flag parsing with test"
- ✅ "Add integration test for setup.zsh prerequisite validation"
- ❌ "Add all prerequisite validation tests and implementation" (too broad)
- ❌ "Implement multiple validation functions" (unrelated changes)
- ❌ "Add tests and fix bugs" (unrelated changes)

### Testing Philosophy

**Always test behavior, not implementation details:**

#### ✅ Good: Test Behavior
- Test that setup.zsh exits with error when prerequisites fail
- Test that validation returns success when requirements are met
- Test that dry-run mode logs actions without executing them
- Test that flag parsing sets the correct environment variables

#### ❌ Bad: Test Implementation Details
- Test that specific function names exist in files
- Test that files contain specific text patterns
- Test internal variable names or private functions
- Test file structure or import statements

#### Why This Matters
- **Maintainable**: Behavioral tests survive refactoring, renaming, and code reorganization
- **Meaningful**: Tests verify actual user-facing functionality rather than code structure
- **Robust**: Less likely to break when implementation changes but behavior stays the same
- **Focused**: Tests tell you what the code should do, not how it should do it

#### Examples
```bash
# ❌ Brittle implementation test
if grep -q "run_prerequisite_validation" "$setup_file"; then
    assert_true "true" "setup.zsh should call specific function"
fi

# ✅ Robust behavioral test  
setup_exit_code=$(run_setup_with_failed_prerequisites)
assert_not_equals "0" "$setup_exit_code" "setup.zsh should exit when prerequisites fail"
```

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

### PR Description Maintenance

**Always update the PR description after new commits** that change what the PR includes:

- After you push new commits, update the PR description with `gh pr edit`
- After the user pushes commits, check what changed and update the description
- Keep the "Changes" section current with all modifications
- Update test plans if new tests were added
- Add new commits to the implementation approach if significant

Example workflow:
```bash
# After adding a new feature to the PR
git push origin feature-branch
gh pr edit PR_NUMBER --body "updated description..."

# Or when user says they pushed changes
gh pr view PR_NUMBER  # Check current state
gh pr edit PR_NUMBER --body "updated description..."
```

### Infrastructure-First PR Guidelines

When creating PRs that add new functions/utilities before they're used:

1. **Add TODO comments** in the code indicating where the function will be used:
   ```bash
   # TODO: Use in PR 7 (Error Recovery) for graceful failure handling
   function handle_installation_error() {
       ...
   }
   ```

2. **Include usage preview** in PR description showing how the code will be used:
   ```markdown
   ## Usage Preview
   This dry-run functionality will be used in future PRs to:
   - PR 7: Wrap all installation commands with `dry_run_execute`
   - PR 8: Add dry-run summaries showing what would be installed
   ```

3. **Mark dead code clearly** so reviewers understand it's intentional:
   - Use descriptive function names that indicate future purpose
   - Add comments explaining the intended use case
   - Reference the roadmap/plan if one exists

When pre-commit checks fail, I'll fix the issues, stage the fixes, and automatically retry the commit to keep the workflow smooth.
