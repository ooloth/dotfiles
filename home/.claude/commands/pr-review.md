---
description: Review a pull request with structured feedback
allowed-tools: [Bash, WebFetch, Read, Grep, Glob]
---

You are helping review a pull request. Please provide a thorough, structured review.

**PR to review:** $ARGUMENTS

**Review process:**
1. Fetch the PR details using GitHub CLI
2. Check existing review comments and status checks
3. If checks are failing, examine failure details and suggest fixes
4. Analyze what CI/CD checks are configured and warn if important checks appear to be missing
5. Analyze the code changes in the diff
6. Read modified files to understand context beyond the diff
7. Identify missing changes that should have been made:
   - **Missing Logic**: Related code that should be updated but wasn't
   - **Missing Documentation**: Code comments explaining "why" (especially for non-obvious decisions), README updates, API docs that need updating
   - **Missing Tests**: Test cases that should exist for the new functionality
8. Provide structured feedback covering:
   - **Code Quality**: Logic, readability, maintainability
   - **Security**: Potential vulnerabilities or security concerns  
   - **Performance**: Efficiency and optimization opportunities
   - **Testing**: Test coverage and quality
   - **Documentation**: Code comments (focus on "why" explanations for critical logic), documentation updates
   - **Architecture**: Design decisions and patterns
   - **Dependencies**: New dependencies and their appropriateness
   - **CI/CD Coverage**: Missing checks that should be configured for this type of change
   - **Completeness**: What's missing that should have been included

**For each area, provide:**
- ✅ What looks good
- ⚠️ Areas for improvement  
- 🔴 Critical issues (if any)

**End with an overall recommendation:** APPROVE, REQUEST CHANGES, or COMMENT.

**If no PR number/URL is provided:** Find the PR for the current branch. If on main branch, list open PRs and ask which one to review.

Use these GitHub CLI commands:
- `gh pr view` - Get PR details, reviews, and status checks
- `gh pr diff` - Get code changes
- `gh pr checks` - Get detailed check status and failure logs
- `gh run view` - Get workflow run details if checks are failing
- Check `.github/workflows/` to understand what CI/CD checks are configured