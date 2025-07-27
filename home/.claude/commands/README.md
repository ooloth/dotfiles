# Claude Code Slash Commands

This directory contains slash commands that provide convenient shortcuts for common development workflows. These commands follow a **streamlined approach** - they provide structured prompts that guide main Claude through expert consultation patterns.

## Philosophy

### Streamlined Implementation Approach

Main Claude handles implementation, coordination, and communication while consulting specialists when beneficial. The slash commands serve three purposes:

1. **Discovery** - Help users find the right functionality through intuitive command names
2. **Structure** - Provide clear problem analysis frameworks and consultation patterns
3. **Guidance** - Direct main Claude to consider relevant specialist perspectives

### Structured Prompt Design

Each command:
- Contains focused problem analysis frameworks
- Includes guidance on when to consult specialists
- Provides clear structure for systematic approaches
- Encourages efficient expert consultation patterns

## Command Categories

### Review Commands (`/review-*`)
- `review-code` → comprehensive quality audit across all dimensions (bugs, architecture, security, performance, tests, readability, modern patterns) with prioritized observations
- `review-pr` → structured PR review process (takes PR number, defaults to current branch)

### Create Commands (`/create-*`)
- `create-tests` → systematic test design and implementation
- `create-docs` → systematic documentation creation
- `create-branch` → git-workflow agent delegation
- `create-commit` → git-workflow agent delegation
- `create-pr` → git-workflow agent delegation

### Fix Commands (`/fix-*`)
- `fix-bug` → systematic debugging and resolution framework
- `fix-performance` → performance optimization with design-architect consultation
- `fix-security` → security fixes with design-architect consultation
- `fix-tests` → methodical test failure resolution
- `fix-architecture` → structural design improvements with design-architect consultation
- `fix-types` → type safety and annotation improvements
- `fix-quality` → general code quality enhancements

### Plan Commands
- `plan` → systematic problem analysis with specialist consultation

## Usage

Commands can be invoked with `/command-name [arguments]`. Arguments provide context for the structured analysis framework.

Examples:
```bash
/review-code auth.py
/create-tests user-authentication
/fix-bug "TypeError in login function"
/plan "how to implement user authentication"
```

## Specialist Consultation Guidance

While these commands provide structured workflows, main Claude can also consult specialists directly based on context. The commands exist to provide clear frameworks and ensure comprehensive analysis when needed.

## Maintenance

When modifying commands:
1. Keep them as structured prompts
2. Focus on problem analysis frameworks
3. Include guidance on specialist consultation
4. Ensure clear workflow structure
5. Test that the framework leads to comprehensive solutions

For adding new commands, identify common workflow patterns that benefit from structure, then create frameworks that guide systematic analysis with appropriate specialist consultation.