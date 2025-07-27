# Claude Code Slash Commands

This directory contains slash commands that provide convenient shortcuts for common development workflows. These commands follow a **thin wrapper philosophy** - they are simple routing mechanisms to expert agents rather than containing detailed implementation instructions.

## Philosophy

### Agents-First Approach

All detailed workflow logic, processes, and expertise reside in the specialized agents located in `~/.claude/agents/`. The slash commands serve three purposes:

1. **Discovery** - Help users find the right functionality through intuitive command names
2. **Convenience** - Provide quick shortcuts without needing to remember agent names
3. **Routing** - Direct requests to the appropriate expert agent(s)

### Thin Wrapper Design

Each command:
- Contains minimal logic (just agent delegation)
- Includes comments explaining its purpose as a wrapper
- Passes arguments directly to the expert agent
- Does NOT duplicate functionality from agents

## Command Categories

### Review Commands (`/review-*`)
- `review-code` → comprehensive code review with expert consultation
- `review-security` → design-architect agent (security analysis)
- `review-performance` → design-architect agent (performance analysis)
- `review-architecture` → design-architect agent
- `review-tests` → test-designer agent (test execution and coverage)
- `review-pr` → comprehensive PR analysis with contextual research
- `review-quality` → comprehensive quality assessment with specialist consultation

### Create Commands (`/create-*`)
- `create-tests` → test-designer agent
- `create-docs` → documentation-writer agent
- `create-branch` → git-workflow agent
- `create-commit` → git-workflow agent  
- `create-pr` → git-workflow agent
- `create-feature` → software-engineer agent

### Planning and Problem-Solving
- `plan` → problem-solver agent (domain-agnostic problem analysis with intelligent expert coordination)

### Fix Commands (`/fix-*`)
- `fix-bug` → debugger agent
- `fix-performance` → design-architect agent (performance optimization)
- `fix-security` → design-architect agent (security fixes)
- `fix-tests` → test-designer agent (test fixes and coverage)
- `fix-code` → comprehensive code improvement with expert consultation

### Plan Commands
- `plan` → problem-solver agent (intelligent problem analysis and expert coordination)

## Usage

Commands can be invoked with `/command-name [arguments]`. Arguments are passed to the underlying agent as context.

Examples:
```bash
/review-code auth.py
/create-tests user-authentication
/fix-bug "TypeError in login function"
/plan "how to implement user authentication"
```

## Automatic Agent Delegation

While these commands provide convenient shortcuts, Claude Code's sub-agent system is designed to automatically delegate to appropriate agents based on user intent. The commands exist as a backup and for explicit direction when needed.

## Maintenance

When modifying commands:
1. Keep them as thin wrappers
2. All detailed instructions belong in agent system prompts
3. Include comments explaining the wrapper purpose
4. Ensure argument passing works correctly
5. Test that the target agent handles the workflow properly

For adding new commands, first ensure the underlying agent capability exists, then create a simple wrapper that routes to that agent.