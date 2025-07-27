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
- `review-code` → code-reviewer agent
- `review-security` → security-auditor agent  
- `review-performance` → performance-optimizer agent
- `review-architecture` → design-architect agent
- `review-tests` → test-runner agent
- `review-pr` → code-reviewer agent (for PR analysis)
- `review-quality` → multiple agents (comprehensive audit)

### Create Commands (`/create-*`)
- `create-tests` → test-designer agent
- `create-docs` → documentation-writer agent
- `create-branch` → git-workflow agent
- `create-commit` → git-workflow agent  
- `create-pr` → git-workflow agent
- `create-feature` → software-engineer agent

### Fix Commands (`/fix-*`)
- `fix-bug` → debugger agent
- `fix-performance` → performance-optimizer agent
- `fix-security` → security-auditor agent
- `fix-tests` → test-runner + test-designer agents
- `fix-code` → design-architect + code-reviewer agents

### Plan Commands (`/plan-*`)
- `plan-feature` → design-architect agent
- `plan-refactor` → design-architect agent

## Usage

Commands can be invoked with `/command-name [arguments]`. Arguments are passed to the underlying agent as context.

Examples:
```bash
/review-code auth.py
/create-tests user-authentication
/fix-bug "TypeError in login function"
/plan-feature "notification system"
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