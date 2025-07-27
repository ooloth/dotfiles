---
description: Review a pull request with structured feedback
---

## Structured PR Review Process

### Phase 0: PR Identification
**Determine which PR to review:**
- **If PR number provided**: Use `gh pr view <number>` to fetch details
- **If no argument given**: Check current branch for associated PR using `gh pr view`
- **If ambiguous**: Ask user to clarify which PR to review
- **If no PR found**: Inform user and ask for PR number or URL

### Phase 1: Context Research
1. **Fetch PR details** using GitHub CLI (`gh pr view <number> --json body,commits,files`)
2. **Review linked issues** for requirements and context
3. **Check epic/project context** if part of larger initiative
4. **Understand the "why"** behind the changes

### Phase 2: Code Analysis
1. **Diff review** - Understand all changes made (`gh pr diff <number>`)
2. **Quality assessment** - Style, clarity, maintainability
3. **Bug detection** - Logic errors, edge cases
4. **Test coverage** - New tests for new functionality
5. **Documentation** - Updated docs for changed behavior

### Phase 3: Specialized Review (consult when beneficial)
- **Security implications** → design-architect for vulnerabilities
- **Performance impact** → design-architect for bottlenecks
- **Architectural changes** → design-architect for design review
- **Best practices** → researcher for framework patterns

### Phase 4: Actionable Feedback
- **Must fix**: Bugs, security issues, broken tests
- **Should fix**: Performance issues, poor patterns
- **Consider**: Style improvements, refactoring opportunities
- **Praise**: Good patterns, clever solutions, thorough testing

PR number or URL (optional - will check current branch if not provided): $ARGUMENTS