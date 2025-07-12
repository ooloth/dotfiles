## Claude Code Permissions

**CRITICAL: Understand the three-tier permission system in ~/.claude/settings.json**

1. **Auto-approved commands** (in `allow` list) - Use directly, NEVER ask for permission:
   - Git operations: `git add`, `git commit`, `git push`, `git pull`, `git checkout`, `git branch`, `git stash`, `git merge`, `git cherry-pick`, `git fetch`
   - GitHub CLI: `gh pr create`, `gh pr edit`, `gh pr ready`, `gh pr view`
   - File operations: `Edit(*)`, `MultiEdit(*)`, `Write(*)`, `NotebookEdit(*)`
   - Basic bash: `cat`, `echo`, `ls`, `find`, `mkdir`, `mv`, `chmod`, `grep`, `shellcheck`, `timeout`
   - Special: `Bash(/dev/null)`

2. **Auto-denied commands** (in `deny` list) - Completely blocked, don't try to use:
   - `Bash(curl:*)` - Cannot use curl commands

3. **Ask-first commands** - Everything else requires permission request before use
   - Any bash commands not in the allow list
   - Any other tools or operations not explicitly allowed

**NEVER ask for permission for auto-approved commands** - this creates unnecessary friction and wastes time.

## Default Coding Behavior

**CRITICAL: Always consider TDD discipline before starting any coding task**

1. **Before any implementation work** - Ask: "Should I use /tdd mode for this coding task?"
2. **Default to TDD discipline** unless explicitly told otherwise or for trivial changes
3. **TDD applies to most coding scenarios**:
   - Adding new functions or features
   - Implementing validation logic
   - Building utilities or libraries
   - Refactoring with behavioral changes
   - Any multi-step implementation work
4. **Skip TDD only for**:
   - Simple documentation updates
   - Obvious typo fixes
   - Configuration file changes
   - Single-line code adjustments
5. **TDD workflow activation**:
   - Use `/tdd [task description]` command to activate strict discipline
   - Follow red-green-refactor cycle rigorously
   - Never write multiple test cases without implementing each one first
   - Commit test + implementation + docs together for each test case

**Key behavioral change**: Make TDD consideration automatic, not optional.

## Automatic Commit Workflow

### Pre-commit Checks (in order)

**CRITICAL: Always run these checks before any commit:**

1. **Formatting** - Run code formatters first (prettier, black, rustfmt, etc.)
2. **Linting** - Run linters after formatting
3. **Type checking** - Run type checkers
4. **Tests** - Run relevant tests last
5. **Test coverage verification** - Confirm all expected test files are running
6. **All tests must pass** - **CRITICAL**: Fix any failing tests immediately, do not commit/push with failing tests
7. **Final review** - Check `git diff --staged` to review what will be committed
8. **Security check** - Verify no sensitive information (keys, tokens, passwords) is included

### Test Requirements

**All tests must pass before any commit or push:**

1. **Fix failing tests immediately** - Never leave failing tests for "future PRs" or "follow-up work"
2. **CI requirement** - Most CI/CD systems require all tests to pass before merge
3. **Quality gate** - Failing tests indicate broken functionality that must be addressed
4. **No exceptions** - Even if failure seems minor or unrelated, investigate and fix

**When tests fail:**
- **Investigate the root cause** - Don't just change the test, understand why it's failing
- **Fix the implementation or test** - Address the actual issue, whether in code or test logic
- **Verify the fix** - Run the full test suite to ensure no regressions
- **Document complex fixes** - If the fix was non-obvious, add comments explaining the solution

### When Pre-commit Checks Fail

- **Formatting failures**: Auto-fix and stage the formatted changes, then retry commit
- **Linting failures**: Fix the issues, stage the fixes, then retry commit
- **Type checking failures**: Fix type errors, stage the fixes, then retry commit
- **Test failures**: Fix failing tests, stage the fixes, then retry commit
- If any check fails twice, report the issue and ask for guidance
- Always include auto-fixes in the same commit when possible

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
- **Separate commits even for the same file type** - configuration changes, documentation updates, and code changes should be separate commits even if they modify similar file types
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

For detailed TDD workflow enforcement, use the `/tdd` command.

Key principles when following Test-Driven Development:
- One test case at a time with minimal implementation
- Group test + implementation + docs in same commit
- Follow red-green-refactor cycle rigorously
- For legacy code: characterization test → refactor → unit tests → TDD
- Use `/tdd [task]` command for strict behavioral enforcement

See `/tdd` command for complete rules and legacy code guidance.

### TDD with Legacy Code

When modifying hard-to-test existing code, use the `/tdd` command which includes specialized legacy code workflow guidance.

Key approach: characterization test → refactor → unit tests → TDD for new behavior.

See `/tdd` command for complete legacy code workflow, assessment guidance, and commit sequence examples.

### Post-Implementation Code Review and Refactoring

**After all tests pass, always consider refactoring opportunities in new code.**

**Key principles:**
- Focus refactoring on code you just wrote for this behavior
- Eliminate dead code and duplication within new functionality
- Make design improvements before finalizing PR
- Use `/refactor` command for systematic refactoring workflow

**Scope guidelines:**
- **✅ Include refactoring that improves the current PR** (new code, localized improvements)
- **❌ Defer refactoring that expands PR scope** (large-scale redesigns, unrelated cleanup)

**Two-phase approach:**
1. **Make it work** - Follow TDD to implement working functionality
2. **Make it right** - Use `/refactor` to systematically improve design

See `/refactor` command for detailed code quality checklist and improvement techniques.

### Examples of Good Commit Granularity
- ✅ "Add input validation with test"
- ✅ "Add database connectivity validation with test"
- ✅ "Add edge case test for connection timeout handling"
- ✅ "Add API version validation with test"
- ✅ "Add test for unsupported API version error message"
- ✅ "Add dry-run mode flag parsing with test"
- ✅ "Add integration test for service prerequisite validation"
- ✅ "Update CLAUDE.md with refactoring guidelines"
- ✅ "Update Claude permissions for development commands"
- ❌ "Add all prerequisite validation tests and implementation" (too broad - multiple test cases)
- ❌ "Implement multiple validation functions" (unrelated changes)
- ❌ "Add tests and fix bugs" (unrelated changes)
- ❌ "Update CLAUDE.md and settings.json" (unrelated changes - different purposes)

### Testing Philosophy

**Always test behavior, not implementation details:**

#### ✅ Good: Test Behavior
- Test that applications exit with error when prerequisites fail
- Test that validation returns success when requirements are met
- Test that dry-run mode logs actions without executing them
- Test that configuration parsing sets the correct values

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
```
# ❌ Brittle implementation test
if search_for_function_name("validate_prerequisites", setup_file):
    assert_true("setup should call specific function")

# ✅ Robust behavioral test  
exit_code = run_setup_with_failed_prerequisites()
assert_not_equals(0, exit_code, "setup should exit when prerequisites fail")
```


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
- **Delete merged feature branches** immediately after PR is merged to maintain git hygiene

### Post-Merge Workflow

**CRITICAL: Always execute these steps immediately after merging any PR:**

1. **Switch to main branch** - `git checkout main` (or `master`/`trunk` depending on repository)
2. **Pull latest changes** - `git pull` or `git pull origin main` 
3. **Delete merged feature branch** - `git branch -d feature-branch-name` (use `-D` if needed)
4. **Automatic execution** - These steps should be automatic after every merge, not requiring user request

**This workflow ensures:**
- Local repository stays current with merged changes
- Merged feature branches are cleaned up immediately
- Ready to start new work from updated main branch
- Prevents branch pollution and confusion

### PR Preparation

- Before pushing, review the full diff with `git diff main...HEAD`
- Ensure commit messages follow conventional format
- Split large changes into multiple PRs when possible
- Include context about why changes were made, not just what changed

### PR Size and Focus Guidelines

**Each PR should be a complete bundle of one new behavior:**

1. **Complete functionality** - Include tests, implementation, and actual usage together
2. **Avoid dead code** - Don't add functions/utilities without demonstrating their use
3. **Include documentation updates** - Update code comments, READMEs, CLAUDE.md as needed
4. **One responsibility per PR** - Each PR should do exactly one thing, but do it completely

**Size guidelines:**
- **Target < 100 lines** when possible for easy review
- **Accept larger PRs (200-400+ lines)** when needed for completeness
- **Better to have one complete 300-line PR** than three 100-line PRs with dead code
- **Size is secondary to completeness and logical boundaries**

**Examples of complete behavior bundles:**
- ✅ "Add Homebrew detection with tests and integration into installation script"
- ✅ "Add API validation with tests, error messages, and documentation"
- ✅ "Add database migration with rollback functionality and admin tools"
- ❌ "Add Homebrew detection utility" (missing actual usage)
- ❌ "Add authentication tests" (missing implementation and integration)

**When to split PRs:**
- **Multiple unrelated behaviors** (authentication vs database vs caching)
- **Different deployment boundaries** (frontend vs backend in systems with separate deployment pipelines)
- **Refactoring separate from new features** (clean up existing code vs add new functionality)
- **Infrastructure changes that enable multiple future features** (but include at least one usage example)

### PR Creation Requirements

For detailed PR creation workflow, use the `/pr-draft` command.

Key principles:
- Always create PRs in draft mode for review workflows
- Use structured PR templates for clear communication
- Focus on complete functionality bundles (see sizing guidelines above)

See `/pr-draft` command for complete workflow and template guidelines.

### PR Workflow Requirements

**CRITICAL commit and push behavior:**
- Commit and push changes immediately after making them
- Update PR description after pushing commits with new functionality
- Never consider PRs "done" until actually merged
- Stay focused on current PR until user confirms completion

**Key principles:**
- User expects to see changes in GitHub UI immediately
- All commits must be explained in PR descriptions
- Include off-topic commits transparently
- Wait for user direction before considering PR work finished

See `/pr-draft` and `/pr-review` commands for detailed workflow guidance.


### Multi-PR Task Management

**CRITICAL: Always maintain task roadmap files throughout development**

For tasks involving multiple PRs, create and maintain a roadmap file:

1. **Create task roadmap file** in `.claude/tasks/YYYY-MM-DD-task-name.md`
2. **Update throughout development** with progress, learnings, and context
3. **Update after EVERY significant change**:
   - After creating/merging PRs
   - After discovering new issues or requirements
   - After making important technical decisions
   - After user feedback or direction changes
   - **Never let task files become stale** - they are critical handoff documentation
4. **Include essential information** for future Claudes taking over:
   - Completed PRs with key outcomes
   - Current PR status and next steps
   - Important decisions made and why
   - Technical patterns established
   - Any gotchas or lessons learned
   - Critical issues discovered during development
5. **When moving files**: If git doesn't detect as a move (due to content changes), explicitly stage both the new file creation AND the old file deletion in the same commit

**Task file maintenance is NOT optional** - these files are essential for:
- Continuity when conversations end mid-task
- Context for future development sessions
- Preventing repeated mistakes and decisions
- Maintaining project momentum across multiple sessions

Example task file structure:
```markdown
# 2025-07-06-feature-improvements.md

## Progress
- ✅ PR 1: Testing Foundation
- ✅ PR 2: Service Authentication  
- 🔄 PR 3: Error Handling (in review)

## Key Decisions
- Using behavioral tests instead of implementation tests
- Async approach for better performance

## Next Steps
- PR 4: Individual Service Testing
- Need to integrate retry mechanism into API client
```

### Infrastructure-First PR Guidelines

When creating PRs that add new functions/utilities before they're used:

1. **Add TODO comments** in the code indicating where the function will be used:
   ```
   # TODO: Use in PR 7 (Error Recovery) for graceful failure handling
   function handle_error() {
       ...
   }
   ```

2. **Include usage preview** in PR description showing how the code will be used:
   ```markdown
   ## Usage Preview
   This validation functionality will be used in future PRs to:
   - PR 7: Wrap all service calls with `validate_input`
   - PR 8: Add validation summaries for user feedback
   ```

3. **Mark dead code clearly** so reviewers understand it's intentional:
   - Use descriptive function names that indicate future purpose
   - Add comments explaining the intended use case
   - Reference the roadmap/plan if one exists

### Test Coverage Verification

**Always verify that all expected test files are running** when running the test suite:

1. **Compare manual count vs test runner output**:
   - Count test files manually using appropriate commands for the project
   - Compare with test runner output (usually shows "Found X test(s)" or similar)
   - Numbers should match for complete coverage

2. **Check for missing test directories**:
   - Verify test runner scans all expected test directories
   - Ensure no test locations are being excluded unintentionally

3. **Common test runner issues to watch for**:
   - Test files missing required permissions or attributes
   - Test files not matching expected naming patterns or conventions
   - Directories not being scanned recursively when they should be
   - Test runner configuration excluding certain paths or file types
   - Build artifacts or temporary files interfering with test discovery

4. **When test count doesn't match expectations**:
   - Run the test suite and note how many tests it reports finding
   - Manually count test files using project-appropriate commands
   - Check if specific test directories or files are being excluded
   - Verify file naming conventions and required attributes
   - Fix any discrepancies before proceeding

**This prevents regressions where test files exist but aren't being executed.**

For project-specific commands and examples, see the project's CLAUDE.md file.

When pre-commit checks fail, I'll fix the issues, stage the fixes, and automatically retry the commit to keep the workflow smooth.

### Commit Message Format

Use clear, descriptive commit messages without promotional footers:
- Focus on what changed and why
- Use conventional commit format when applicable  
- Do NOT include "Generated with Claude Code" or co-author lines
- Keep messages concise and professional

## Project Documentation Guidelines

### README.md vs CLAUDE.md

For projects with both README.md and CLAUDE.md files:

**README.md should contain:**
- General project information that benefits all users
- Installation and setup instructions
- Usage examples and documentation
- Troubleshooting guides
- Contributing guidelines
- Any information multiple people would find useful

**Project-level CLAUDE.md should:**
- Reference README.md for general information: "For installation instructions, see [README.md](README.md)"
- Only contain Claude-specific guidance and notes
- Focus on development workflow, file structure, and Claude-specific considerations
- Be kept minimal and accurate - verify file paths and commands exist before referencing them
- Evolve as the project changes (e.g., update test suite information when tests are added)

### Personal CLAUDE.md Maintenance

**When updating your personal CLAUDE.md:**

1. **Always phrase updates universally** - avoid language-specific, framework-specific, or project-specific examples
2. **Use generic examples** that apply across programming languages and project types
3. **Test universal applicability** - ask yourself "Would this apply to a Python web app? A Rust CLI? A JavaScript frontend?"
4. **Replace specific tools with categories** (e.g., "npm" → "package manager", "setup.zsh" → "main script")

### Project CLAUDE.md Maintenance

**Consider updating the project CLAUDE.md when:**

1. **Learning something that would help future Claudes** working on this specific project
2. **Making changes that invalidate existing project documentation** (new test commands, file moves, etc.)
3. **Discovering project-specific patterns or gotchas** that aren't obvious from the code
4. **Adding new tools, frameworks, or workflows** specific to this project

**Periodic project CLAUDE.md review (before each PR):**

1. **Check for inaccuracies** - verify file paths, commands, and examples still work
2. **Look for important omissions** - what would have helped you that isn't documented?
3. **Update outdated information** - remove references to deleted files or changed workflows
4. **Add new learnings** - document any project-specific insights discovered during development


### File Path Verification (Universal)

**Always verify file paths exist before referencing them in any documentation:**

1. **Use directory listing commands** to check actual file names before referencing them
2. **Don't assume file naming conventions** - check what files actually exist
3. **Verify correct directories** - files might be in different locations than expected
4. **Test file paths** before committing documentation that references them
5. **Common mistake**: Assuming numbered prefixes or specific naming patterns without verification

This prevents documentation that references non-existent files, which creates confusion and reduces trust in the documentation.
