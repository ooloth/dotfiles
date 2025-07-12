---
description: Create a draft pull request from the current branch
allowed-tools: [Bash, Read, Grep, Glob]
---

Create a draft pull request from the current branch to the main branch.

**Target branch (optional):** $ARGUMENTS

**Process:**
1. Check current branch (must not be main/master)
2. Check working tree for uncommitted changes:
   - Review each change to determine if it belongs with the current PR
   - **Be cautious with temporary changes**: commented-out code, debug prints, config tweaks for testing
   - Ask user before committing anything that looks temporary or experimental
   - For legitimate changes: commit them with the PR
   - For unrelated changes: determine best approach (stash, separate commit, or leave uncommitted)
3. Ensure branch is up to date with latest changes from target branch
4. Ensure branch is pushed to remote
5. Analyze commits since branching from main to understand the changes
6. Read modified files to understand the full scope
7. Check if PR relates to existing project plans or issues and ensure they're updated:
   - Look for related GitHub issues, project roadmaps, or planning documents
   - Check if task tracking files (like `.claude/tasks/*.md`) need updates
   - Verify project documentation reflects the changes being made
8. Generate PR description:
   - **Check for existing PR template** in `.github/pull_request_template.md` or `.github/PULL_REQUEST_TEMPLATE.md`
   - **If project has PR template**: Follow it, but enhance with the spirit of the high-quality template
   - **If no project template**: Use the high-quality template structure (ONLY these sections):
     - 💪 **What**: What's new/different, direct changes to project behavior, testing/documentation status, implementation details (use present tense: "Adds", "Updates", "Removes", "Fixes")
     - 🤔 **Why**: Problem solved, business value, timing rationale
     - 👀 **Usage**: How to use new functionality (if user-facing)
     - 👩‍🔬 **How to validate**: Manual steps for reviewers to exercise the code and observe outcomes (teach reviewers how to prove the changes work by using the functionality - never tell them to run tests or checks, as CI handles that)
     - 🔗 **Related links**: External context as markdown links (only if valuable, omit if none)
   - **Append missing valuable sections** from the high-quality template if not covered by project template
   - **Focus on reviewer experience** - provide context that helps reviewers understand and validate changes
   - **"What" vs "Why" clarity**: "What" describes direct changes/impacts, "Why" explains benefits and rationale
   - **Format requirements**: Start "What" with flat bullet list of primary behavior changes/takeaways using present tense verbs (Adds, Updates, Removes, Fixes), format "Why" as flat bullet list
   - **Avoid file listings**: Don't include "New Files" sections - reviewers will see files in the PR, focus on what the PR accomplishes
   - **Link formatting**: Use markdown links for external URLs, raw URLs for GitHub PRs/issues (GitHub formats them nicely), format Related links as bullet list
   - **"Why" tone**: Make salient points about why changes help this specific project, avoid overly broad statements or overselling
   - **Reference related issues/plans** - link to GitHub issues, project plans, or task files this PR addresses

**Verb tense consistency:**
- **Always use present tense** in "What" section: "Adds", "Updates", "Removes", "Fixes", "Improves"
- **Never use past tense**: Avoid "Added", "Updated", "Removed", "Fixed"  
- **Examples**: "Adds user authentication", "Updates error handling", "Removes deprecated functions", "Fixes memory leak"
- **Rationale**: Present tense describes what the PR does when merged, not what was done during development

**Related links guidelines:**
- **ONLY include links that provide valuable context NOT already in the PR**
- **External references**: Documentation, Stack Overflow, RFCs, design docs, external issues
- **Background PRs**: Previous/related PRs that provide important context
- **DO NOT include**:
  - Files in the current PR (reviewers can already see them)
  - Generic/empty pages (issues page with no relevant issues)
  - Links that duplicate information already in PR description
  - Internal project files unless they provide critical background context
- **If no useful links exist, omit the entire Related links section** - no section is better than empty section
- **Quality over quantity** - 1-2 highly relevant links better than 5 marginally useful ones

**When to apply template:**
- Creating PRs in repos without templates
- Repos with minimal templates missing key sections
- Any time PR description would benefit from structured approach
- Use good judgment - don't force inappropriate structure on simple fixes

**Draft mode requirements:**
- **Always create PRs in draft mode** for review workflows
- **Draft allows iteration** - User can review and request changes before marking ready
- **Prevents premature merge** - Ensures proper review process is followed
- **Only use non-draft PRs** when explicitly instructed or for trivial changes

9. Create the draft PR with descriptive title and structured body

**GitHub CLI commands to use:**
- `git branch --show-current` - Get current branch
- `git fetch origin` - Get latest remote changes
- `git merge-base HEAD origin/main` - Check if up to date
- `git log main..HEAD --oneline` - See commits since branching
- `git diff main...HEAD --name-only` - See changed files
- `gh issue list` - Check for related GitHub issues
- Check for `.claude/tasks/*.md`, project roadmaps, or planning documents
- `gh pr create --draft` - Create draft PR

**If target branch is specified as argument, use that instead of main.**

**PR title format:** Use the branch name or first commit message as basis, make it descriptive and clear.