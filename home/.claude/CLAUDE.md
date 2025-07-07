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

When following Test-Driven Development:
- **One test case at a time** - write ONE failing test, then implement ONLY enough code to make it pass
- **Group test and implementation in the same commit** for each test case
- **Include necessary documentation updates** in the same commit (without overdocumenting)
- **Multiple tests per function are fine** - each function may need several test cases for edge cases
- **TDD cycle per commit**:
  1. **Red**: Write one failing test case
  2. **Green**: Implement minimal code to make it pass
  3. **Refactor**: Improve code design while keeping tests green
  4. Commit all changes together
- **Commit structure**:
  - Commit: "Add command line tools validation with test"
  - Commit: "Add network connectivity validation with test"  
  - Commit: "Add edge case handling for network timeouts with test"
- This makes each commit focused and easier to review (test and implementation on same screen)
- Each commit adds exactly one test case (not all tests first, then all implementation)
- The test case should determine what implementation changes belong in the commit

### Post-Implementation Code Review and Refactoring

**After all tests pass, always look for improvement opportunities in the new code:**

#### Scope Guidelines for Refactoring Within PRs

**✅ Include refactoring that improves the current PR:**
- **New code improvements** - Focus on code you just wrote for this behavior
- **Localized duplication** - Eliminate repetition within the new functions/files
- **Interface clarity** - Improve naming and design of new APIs
- **PR review clarity** - Changes that make the PR easier to understand

**❌ Defer refactoring that expands PR scope:**
- **Large-scale redesigns** - Major architectural changes to existing systems
- **Unrelated code cleanup** - Improvements to old code not touched by this PR
- **Cross-cutting changes** - Modifications that affect many existing files
- **Breaking changes** - API changes that require updating many call sites

#### Code Quality Review Checklist (for new code)
1. **Dead code elimination** - Remove any unused code you added
   - Functions or utilities that aren't called anywhere
   - Parameters that aren't used by any callers
   - Configuration options that aren't referenced
   - Helper functions added "just in case" but never used
   - **Rule**: Every function/utility must have demonstrated usage in the PR

2. **Duplication elimination** - Look for repeated patterns in your new code
   - Multiple functions defining the same variables
   - Similar validation logic within new functions
   - Repeated string constants or configuration values
   - Identical error handling patterns in new code

3. **Design improvements** - Consider better abstractions for new functionality
   - Extract common functionality within new utility libraries
   - Consolidate configuration within new modules  
   - Improve function naming and interface design for new APIs
   - Consider breaking large new functions into smaller, focused ones

4. **Maintainability enhancements** - Make the new code easier to change
   - Centralize configuration for new functionality (paths, constants, defaults)
   - Improve error messages and user feedback for new features
   - Add helpful code comments for complex new logic

#### Make It Work, Then Make It Right

**Two-phase approach within each PR:**
1. **Phase 1: Make it work** - Follow TDD to implement working functionality
2. **Phase 2: Make it right** - Review and improve the design of new code

**Refactoring commit examples (new code focus):**
- "Refactor SSH utilities to eliminate path duplication" ✅ (within new SSH module)
- "Remove unused get_ssh_public_key function" ✅ (eliminate dead code)
- "Extract common validation logic from new auth functions" ✅ (new functionality)
- "Centralize new API configuration constants" ✅ (new feature scope)
- "Improve error handling consistency across installation scripts" ❌ (too broad)

**Benefits of focused post-implementation refactoring:**
- **Better design** - Can see the full picture after implementing new behavior
- **Easier PR review** - Well-structured new code is easier to understand
- **Reduced technical debt** - Fix new code issues while they're fresh in mind
- **Future-ready** - Well-designed new APIs are easier to extend

**When to create separate refactoring PRs:**
- Large-scale architectural improvements that touch many existing files
- Breaking changes that require updating multiple existing call sites  
- Cross-cutting concerns that affect unrelated parts of the codebase
- Major redesigns that would make the current PR too complex to review

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

### Pre-commit Checks (in order)

1. **Formatting** - Run code formatters first (prettier, black, rustfmt, etc.)
2. **Linting** - Run linters after formatting
3. **Type checking** - Run type checkers
4. **Tests** - Run relevant tests last
5. **Test coverage verification** - Confirm all expected test files are running (see below)
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

**Test debugging approach:**
- Create minimal reproduction scripts when tests fail in complex environments
- Use mocking frameworks properly to isolate the code being tested
- Verify test environment setup doesn't interfere with the functionality being tested

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
- **Delete merged feature branches** immediately after PR is merged to maintain git hygiene

### PR Preparation

- Before pushing, review the full diff with `git diff main...HEAD`
- Ensure commit messages follow conventional format
- Split large changes into multiple PRs when possible
- Include context about why changes were made, not just what changed

### PR Creation Requirements

**CRITICAL: Always create PRs in draft mode for review workflows:**

1. **Default to draft mode** - Use `gh pr create --draft` when creating PRs
2. **Draft allows iteration** - User can review and request changes before marking ready
3. **Prevents premature merge** - Ensures proper review process is followed
4. **Only use non-draft PRs** when explicitly instructed or for trivial changes
5. **Mark ready when told** - User will explicitly say when to convert from draft to ready

**Example PR creation:**
```bash
gh pr create --draft --title "Feature Title" --body "$(cat <<'EOF'
[PR description using template]
EOF
)"
```

### PR Template Usage

**Always use the high-quality PR template when repositories lack good templates:**

1. **For repos without PR templates** - Use the reference template from `~/.claude/PR_TEMPLATE_REFERENCE.md`
2. **For repos with overly brief templates** (e.g., just "What" and "Why") - Enhance with the spirit of the reference template
3. **Bring the template philosophy**: Focus on What/Why/Usage/Validation/Links structure
4. **Maintain reviewer focus**: Emphasize "How to validate" as teaching tool for reviewers
5. **Include context**: Always provide related links that help reviewers understand background

**Reference template structure:**
- 💪 What: What's new/different, files changed, testing/documentation
- 🤔 Why: Problem solved, business value, timing rationale  
- 👀 Usage: How to use new functionality (optional for user-facing changes)
- 👩‍🔬 How to validate: Manual steps for reviewers to confirm changes work
- 🔗 Related links: Context that helps reviewers (docs, issues, PRs, Slack threads)

**When to apply:**
- Creating PRs in repos without templates
- Repos with minimal templates missing key sections
- Any time PR description would benefit from structured approach
- Use good judgment - don't force inappropriate structure on simple fixes

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

**For projects with separate frontend/backend deployments:**
- ✅ Backend PR: "Add user authentication API endpoints with tests and documentation"
- ✅ Frontend PR: "Add login UI components using new authentication endpoints" 
- ✅ Backend PR: "Remove deprecated login endpoints after frontend migration"
- ❌ "Add user authentication with backend API and frontend UI" (deployment complexity)

**When to split PRs:**
- **Multiple unrelated behaviors** (authentication vs database vs caching)
- **Different deployment boundaries** (frontend vs backend in systems with separate deployment pipelines)
- **Refactoring separate from new features** (clean up existing code vs add new functionality)
- **Infrastructure changes that enable multiple future features** (but include at least one usage example)

**Deployment-aware PR sequencing:**
- **Backend-first approach**: Deploy backend changes before frontend changes that depend on them
- **Graceful migrations**: When replacing functionality, deploy new approach → migrate frontend → remove old approach
- **Feature flags**: Use feature toggles when backend and frontend changes must be deployed together
- **Backward compatibility**: Ensure backend changes don't break existing frontend functionality

**Complete behavior includes:**
- ✅ Tests that validate the behavior works
- ✅ Implementation that passes the tests
- ✅ Integration/usage that demonstrates real-world value
- ✅ Documentation updates for user-facing changes
- ✅ Code comments for complex logic
- ✅ **Only code that is actually used** - no speculative "might be useful" functions

### PR Description Maintenance

**Always update the PR description after new commits** that change what the PR includes:

- After you push new commits, update the PR description with available tools
- After the user pushes commits, check what changed and update the description
- Keep the "Changes" section current with all modifications
- Update test plans if new tests were added
- Add new commits to the implementation approach if significant

### PR Commit Pushing and Description Updates

**Always commit and push changes immediately after making them:**

1. **After making any file changes** - Commit immediately, don't accumulate changes
2. **After making commits to a PR branch** - Push immediately so changes are visible in GitHub
3. **Don't batch multiple commits** before pushing - push after each commit or small group
4. **User expects to see changes in GitHub UI** when you announce commits in terminal
5. **Prevents confusion** between what's committed locally vs what's visible for review
6. **Automatic behavior** - Commit and push should be automatic, not requiring explicit user request

**CRITICAL: PRs are not complete until merged:**

- **Never consider a PR "done" or "completed" until it's actually merged**
- **Don't move to next tasks** while a PR is still open and being iterated on
- **Stay focused on current PR** until user explicitly says to move on or confirms merge
- **PR work includes** creation, iteration, addressing feedback, and final merge
- **Wait for user direction** before considering PR work finished
- **Never mark PR tasks as completed in todo lists** until the PR is actually merged
- **Don't update project roadmaps or task trackers** to show PR completion until merge is confirmed

**CRITICAL: Always update PR description after pushing commits with new functionality:**

1. **Check if new commits add functionality** not already described in the PR
2. **Update PR description immediately** after pushing if commits introduce:
   - New features or capabilities not mentioned
   - Additional test coverage or edge cases
   - Refactoring or code improvements
   - Documentation updates (like CLAUDE.md changes)
   - Bug fixes or dead code removal
   - **ANY commits, even off-topic ones** - all commits must be explained for reviewers
3. **Use `gh pr edit [number] --body "..."` or web interface** to update
4. **Don't assume changes are obvious** - explicitly document what was added
5. **Include off-topic commits transparently** - clearly separate them but don't hide them

Example workflow:
```
# When making any file changes during development
[make file changes]
git add [files]
git commit -m "descriptive commit message"
git push origin feature-branch  # ← CRITICAL: Always push immediately

# ← CRITICAL: Update PR description if commits add new functionality
gh pr edit [number] --body "$(cat <<'EOF'
[updated description with new changes]
EOF
)"
```

**This workflow should be automatic - don't wait for user to ask "commit and push":**
- When you make file changes, immediately commit and push
- When you improve documentation, immediately commit and push  
- When you fix code issues, immediately commit and push
- The user expects to see changes in GitHub without having to request it

**Handling off-topic commits in PR descriptions:**
- **Always include all commits** - even those not related to the PR's main purpose
- **Use clear section separation** - e.g., "Documentation Updates (Claude Development Process)"
- **Provide context** - explain why off-topic changes are included (e.g., "discovered during development")
- **Be transparent** - better to over-explain than leave reviewers wondering
- **Example structure**: Core functionality sections first, then clearly labeled off-topic sections

**Exception**: Only skip pushing if explicitly told not to push or if you're about to make several rapid commits in succession (then push the batch).

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
