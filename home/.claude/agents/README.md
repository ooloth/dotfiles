# Claude Code Specialized Agents

This directory contains specialized sub-agents that provide deep expertise for software development. These agents support the **streamlined approach** where main Claude handles implementation, coordination, and communication while consulting specialists for focused expertise when beneficial.

## Philosophy

### Single Source of Truth

Each agent is the definitive source for its domain expertise:

- **All workflow logic** lives in the agent system prompt
- **No duplication** of instructions across commands or other files
- **Complete workflows** from start to finish in one place
- **Coordinated behavior** through explicit agent collaboration

### Specialist Consultation Model

Specialist agents provide focused expertise when main Claude determines it would be beneficial:

- Deep domain knowledge without coordination overhead
- Clean isolation for complex analysis
- Specialized tools and workflows
- Expert perspective on specific technical domains

## Agent Architecture

### Context-Aware Expertise

All agents are **context-aware**, adapting their behavior based on whether you're:

- **Creating new code** (planning/implementation mode)
- **Reviewing existing code** (analysis/assessment mode)

This enables the same expert to help you both plan your own work and review other people's code with consistent standards and expertise.

### High-Value Specialist Agents

**`design-architect`** - Unified architecture, security, and performance expert

- **Planning Mode**: Design secure, performant architectures from the ground up
- **Review Mode**: Analyze existing code for architectural, security, and performance issues
- Triggers: architecture, design, security, authentication, performance, optimization, scaling

**`researcher`** - Technology research and best practices

- **Planning Mode**: Research technologies and best practices for informed decisions
- **Analysis Mode**: Evaluate existing implementations against current standards
- **Fast-path responses**: Immediate answers for common tool/framework questions
- Triggers: "documentation for", "how does X work", API reference, research, look up

### Support and Integration Agents

**`atomic-committer`** - Small, focused commits

**`pr-creator`** - Commit messages and PR descriptions

- Clear, informative commit messages and PR descriptions with consistent templates
- Triggers: creating commits, pushing changes, creating PRs

**`task-manager`** - Multi-PR coordination and project management

- GitHub issue tracking, roadmap coordination, epic management
- Supports main Claude with project-level organization
- Triggers: task, roadmap, multi-PR, tracking, epic

## Specialist Consultation Patterns

Main Claude coordinates with specialists through focused consultation:

**Direct Expert Access:**

- Main Claude handles implementation, coordination, and communication
- Specialists provide deep expertise without intermediary layers
- Parallel consultation when multiple domains are relevant
- Clean handoff of specific technical analysis

**Context-Aware Expertise:**

- Same specialists support both creation and review workflows
- Consistent expertise standards across different contexts
- Focused analysis without broader project coordination overhead
- Efficient specialist knowledge without context pollution

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
2. **Deep specialization** - Provide expertise main Claude can't efficiently handle
3. **Clean isolation** - Work independently without coordination overhead
4. **Clear value** - Solve specific problems that benefit from specialist focus
5. **Context efficiency** - Avoid duplicating main Claude's general capabilities

### When Modifying Existing Agents

1. **Preserve specialization** - Keep focus on unique expertise
2. **Maintain independence** - Ensure agents can work without extensive coordination
3. **Update capabilities** - Reflect current specialist knowledge
4. **Test consultation** - Verify main Claude can effectively use specialist output

## Testing Specialist Consultation

To verify specialists work correctly:

1. Test specialist expertise in isolation
2. Verify main Claude can effectively interpret specialist output
3. Ensure clean handoff without coordination overhead
4. Confirm specialists provide unique value over main Claude capabilities

## Maintenance

The streamlined specialist architecture requires:

- **Regular review** of specialist scope and unique value
- **Elimination** of any overlap with main Claude capabilities
- **Updates** to specialist expertise as domains evolve
- **Efficiency monitoring** to ensure consultation adds clear value

This approach ensures specialists provide focused expertise while main Claude handles coordination, implementation, and communication for optimal efficiency.

