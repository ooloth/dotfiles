---
description: Review a pull request with structured feedback
allowed-tools: [Bash, WebFetch, Read, Grep, Glob, Task]
---

Review a pull request with comprehensive analysis and structured feedback.

**PR to review:** $ARGUMENTS

**PR Review Process:**

I'll use the code-reviewer agent to conduct thorough PR analysis including:

1. **PR Context Gathering** - fetch PR details, comments, and CI status
2. **Code Analysis** - review changes with expert code review methodology  
3. **Comprehensive Assessment** - quality, security, performance, testing, documentation
4. **Structured Feedback** - actionable recommendations with priority levels
5. **Final Recommendation** - APPROVE, REQUEST CHANGES, or COMMENT

**Agent Delegation:**
This command automatically uses the code-reviewer agent for expert PR review and quality assessment.

**GitHub CLI Integration:**
- Fetch PR details and status checks
- Analyze code changes and CI/CD coverage
- Provide context for comprehensive review