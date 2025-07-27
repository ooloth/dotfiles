# Claude Code Specialized Agents

This directory contains specialized sub-agents that implement expert workflows for software development. These agents embody the **agents-first philosophy** where all detailed instructions, processes, and expertise reside in agent system prompts rather than being scattered across commands or manual processes.

## Philosophy

### Single Source of Truth

Each agent is the definitive source for its domain expertise:
- **All workflow logic** lives in the agent system prompt
- **No duplication** of instructions across commands or other files  
- **Complete workflows** from start to finish in one place
- **Coordinated behavior** through explicit agent collaboration

### Proactive Automatic Delegation

Agents are designed to be automatically invoked by Claude Code based on user intent:
- Descriptions use "Use PROACTIVELY to..." phrasing for automatic triggering
- Trigger keywords are explicitly listed for pattern matching
- Examples in system prompts guide Claude on when to delegate
- "MUST BE USED" language ensures critical workflows aren't missed

## Agent Architecture

### Core Development Agents

**`software-engineer`** - Feature implementation and refactoring coordinator
- Implements features with architecture and testing coordination
- Collaborates with design-architect, test-designer, git-workflow agents
- Triggers: implement, add feature, create function, refactor, write code

**`code-reviewer`** - Code quality and security analysis
- Comprehensive code reviews with prioritized recommendations
- Collaborates with security-auditor, performance-optimizer, data-analyst
- Triggers: implemented, added, created, written, refactored, modified, finished

**`design-architect`** - Architecture decisions and patterns
- Design pattern evaluation and architectural guidance
- Consults researcher for best practices
- Triggers: "how should I", "what's the best way", architecture, design, pattern

### Specialized Domain Agents

**`debugger`** - Error analysis and troubleshooting
- Systematic debugging methodology and root cause analysis
- Consults data-analyst for data issues, researcher for framework problems
- Triggers: error, bug, crash, not working, broken, fails, exception, debug

**`security-auditor`** - Security vulnerability assessment
- OWASP compliance, authentication, input validation, data protection
- Consults researcher for security best practices
- Triggers: security, authentication, authorization, vulnerability, login, user input

**`performance-optimizer`** - Performance analysis and optimization
- Algorithmic complexity, memory usage, caching, scaling analysis
- Consults data-analyst for data performance
- Triggers: slow, performance, optimize, speed up, latency, memory usage, bottleneck

**`test-designer`** - Test strategy and comprehensive coverage
- Test planning, edge case identification, behavioral testing
- Consults researcher for testing frameworks
- Triggers: test, testing, coverage, TDD, test cases, "how should I test"

**`test-runner`** - Test execution and verification
- Test suite execution, coverage verification, failure analysis
- Triggers: test, coverage, testing, run tests

### Support and Integration Agents

**`git-workflow`** - Version control and GitHub operations
- Complete Git workflows: commits, branches, PRs, merges, post-merge cleanup
- MANDATORY for ALL git operations - never perform git operations manually
- Triggers: commit, branch, merge, push, pull, "merge pr", checkout, rebase, gh commands

**`researcher`** - Documentation and best practices investigation
- API research, framework documentation, best practices lookup
- Supports other agents with external knowledge
- Triggers: "documentation for", "how does X work", API reference, research, look up, find examples

**`data-analyst`** - Data processing and database optimization
- DataFrame operations, SQL optimization, data pipeline performance
- Supports performance-optimizer and debugger for data issues
- Triggers: dataframe, pandas, data processing, slow query, big data, SQL optimization

**`pr-writer`** - Commit messages and PR descriptions
- Clear, informative commit messages and PR descriptions
- Works with git-workflow agent
- Triggers: creating commits, pushing changes, creating PRs

**`doc-maintainer`** - Documentation maintenance
- README updates, API documentation maintenance
- Triggers: documentation, README, docs, after code changes affecting usage

**`documentation-writer`** - Comprehensive technical documentation
- New feature documentation, usage guides, API references
- Triggers: after creating features, APIs, libraries

**`task-manager`** - Multi-PR coordination and project management
- GitHub issue tracking, roadmap coordination, epic management
- Triggers: task, roadmap, multi-PR, tracking, epic

## Agent Collaboration

Agents explicitly coordinate through documented collaboration patterns:

- **software-engineer** coordinates with design-architect, test-designer, git-workflow
- **code-reviewer** collaborates with security-auditor, performance-optimizer, data-analyst  
- **debugger** consults data-analyst for data issues, researcher for framework problems
- **All agents** can delegate to researcher for external knowledge needs

## Agent Metadata

Each agent includes:
- **Name**: Unique identifier for delegation
- **Description**: Proactive triggers and use cases for automatic delegation
- **System Prompt**: Complete workflow instructions and processes
- **Usage Examples**: Guidance for when Claude should delegate
- **Collaboration**: Which other agents to coordinate with

## Best Practices

### When Creating New Agents
1. **Single responsibility** - Focus on one domain of expertise
2. **Complete workflows** - Include everything needed from start to finish
3. **Proactive language** - Use "Use PROACTIVELY to..." patterns
4. **Clear triggers** - List specific keywords that should invoke the agent
5. **Collaboration plans** - Define which other agents to work with
6. **Examples** - Include usage examples in the system prompt

### When Modifying Existing Agents
1. **Preserve completeness** - Keep workflows self-contained
2. **Update triggers** - Ensure description matches capabilities
3. **Maintain collaboration** - Update coordination patterns if needed
4. **Test delegation** - Verify automatic delegation still works

## Testing Agent Behavior

To verify agents work correctly:
1. Use trigger keywords in conversations
2. Check that Claude automatically delegates to appropriate agents
3. Verify agents coordinate properly with each other
4. Ensure slash commands route to agents correctly

## Maintenance

The agents-first architecture requires:
- **Regular review** of agent descriptions for optimal auto-delegation
- **Consolidation** of any duplicated logic back into agents
- **Updates** to trigger keywords as patterns evolve
- **Collaboration updates** when new agents are added

This approach ensures expertise stays centralized, reduces duplication, and provides consistent, high-quality development workflows.