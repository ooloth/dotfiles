---
description: Create a draft pull request from the current branch
allowed-tools: [Bash, Read, Grep, Glob]
---

Create a draft pull request from the current branch to the main branch.

**Target branch (optional):** $ARGUMENTS

**Process:**
1. Check current branch (must not be main/master)
2. Ensure branch is up to date with latest changes from target branch
3. Ensure branch is pushed to remote
4. Analyze commits since branching from main to understand the changes
5. Read modified files to understand the full scope
6. Generate PR description:
   - **Check for existing PR template** in `.github/pull_request_template.md` or `.github/PULL_REQUEST_TEMPLATE.md`
   - **If project has PR template**: Follow it, but enhance with the spirit of the high-quality template
   - **If no project template**: Use the high-quality template structure (ONLY these sections):
     - 💪 **What**: What's new/different, impact on project behavior, testing/documentation status, implementation details
     - 🤔 **Why**: Problem solved, business value, timing rationale
     - 👀 **Usage**: How to use new functionality (if user-facing)
     - 👩‍🔬 **How to validate**: Manual steps for reviewers to test changes
     - 🔗 **Related links**: External context (only if valuable, omit if none)
   - **Append missing valuable sections** from the high-quality template if not covered by project template
   - **Focus on reviewer experience** - provide context that helps reviewers understand and validate changes
7. Create the draft PR with descriptive title and structured body

**GitHub CLI commands to use:**
- `git branch --show-current` - Get current branch
- `git fetch origin` - Get latest remote changes
- `git merge-base HEAD origin/main` - Check if up to date
- `git log main..HEAD --oneline` - See commits since branching
- `git diff main...HEAD --name-only` - See changed files
- `gh pr create --draft` - Create draft PR

**If target branch is specified as argument, use that instead of main.**

**PR title format:** Use the branch name or first commit message as basis, make it descriptive and clear.