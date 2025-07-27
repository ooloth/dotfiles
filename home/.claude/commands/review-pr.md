---
description: Review a pull request with structured feedback
---

<!-- 
This command performs comprehensive PR analysis with direct expert consultation.
Covers code quality, security, performance, and architectural considerations.
Consults specialists when beneficial for thorough perspective.
-->

## Structured PR Review Process

### Phase 1: Context Research
1. **Fetch PR details** using GitHub CLI
2. **Review linked issues** for requirements and context
3. **Check epic/project context** if part of larger initiative
4. **Understand the "why"** behind the changes

### Phase 2: Code Analysis
1. **Diff review** - Understand all changes made
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

PR URL: $ARGUMENTS