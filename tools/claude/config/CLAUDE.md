## Memory

- Plan in these phases: clarify -> explore -> plan -> document
- Use `beads` for tracking epics and child tasks
- The plan phase should produce a `beads` task or epic

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**

- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

## Pause to let me review each step

- Implement changes one small theme at-a-time
- Pause after each theme is implemented (behavior + test case(s) + documentation) to let me commit myself

## Managing your context window

- You do best thinking when you have less in your context rather than more
- Minimize your context usage by choosing the right approach for each task:

### 1. Skills First (Highest Priority)

Use skills (`tools/claude/config/skills/`) for token-heavy operations:

- **When**: Heavy data processing, filtering, caching opportunities
- **Why**: Process data in code (Python/bash), return only filtered summaries
- **Token savings**: 80-98% reduction vs processing via Claude tools
- **Examples**: `fetching-github-prs-to-review`, `inspecting-codefresh-failures`

Skills should:

- Filter data in code before returning to Claude
- Return formatted summaries, not raw data
- Cache intermediate results to avoid redundant processing
- Use type hints for reliability
- Sanitize sensitive data before output

#### Creating New Skills

When creating skills, ALWAYS use the `/create-skill` command or reference the template:

- **Template location**: `tools/claude/config/skills/@template/`
- **Complete guidance**: See `@template/README.md` for all best practices
- **Naming convention**: gerund + noun (e.g., `fetching-github-prs-to-review`, `analyzing-python-code`)
- **Examples**: See existing skills in `tools/claude/config/skills/`

The template includes:

- SKILL.md structure with workflow patterns
- Example Python script with all best practices
- Anti-patterns to avoid
- Development process guidance

### 2. Agents Second

Use agents (`tools/claude/config/agents`) for complex exploration:

- **When**: Tasks requiring multiple tool calls, exploration, or investigation
- **Why**: Agents can autonomously explore and make decisions
- **Examples**: `atomic-committer`, `pr-creator`, ephemeral `Explore`/`Plan` agents
- **Ensure**: Agents know exactly what to report back and what details to include

#### Domain Ownership Principle

**Specialized agents own their domains:**

- If an agent exists for a service/domain (Notion, browser testing, etc.), **always delegate to it**
- Even if you have direct access to the underlying tools (MCP servers, skills, etc.)
- The specialized agent knows domain-specific patterns, best practices, and workflows
- **Simple tasks still benefit from consistent delegation** - it's about domain ownership, not task complexity
- Never bypass a domain agent just because the task seems straightforward

**Decision tree:**

1. What domain is this task? (Notion, browser testing, GitHub, etc.)
2. Is there a specialized agent for it? → **Use that agent**
3. (Never reach: Use tools directly)

#### MCP Server Usage via Specialized Agents

**Configuration Strategy:**

- **Project scope** (`.mcp.json`): e.g. `next-devtools` only (frequently used servers only, auto-enabled)
- **User scope** (`~/.claude.json`): `playwright`, `notion` (less frequently used servers, disabled by default)

**Workflow for on-demand MCP servers:**

When browser automation is needed:

1. User runs: `/mcp enable playwright`
2. Delegate to `playwright-agent` for the work
3. Optionally disable: `/mcp disable playwright`

When Notion operations are needed:

1. User runs: `/mcp enable notion`
2. Delegate to `notion-agent` for the work
3. Optionally disable: `/mcp disable notion`

**IMPORTANT**: Never use MCP servers directly in main conversation. Always delegate to specialized agents:

- **Browser automation**: `playwright-agent`
  - Testing pages, verifying rendering, capturing screenshots
  - Inspecting console errors, monitoring network requests

- **Next.js diagnostics**: `nextjs-agent`
  - Checking dev server status, inspecting routes
  - Diagnosing compilation/runtime errors
  - Querying Next.js documentation

- **Notion operations**: `notion-agent`
  - Searching/fetching Notion content
  - Creating/updating pages and databases
  - Managing workspace structure

These agents process MCP data in their own context and return concise summaries, keeping the main conversation lightweight.

### 3. Direct Tool Usage Last

Use Claude tools directly only for:

- Simple, one-off operations
- Tasks requiring immediate context from the conversation
- Operations where overhead of a skill/agent isn't justified

### General Context Management

- Update the `<task>.md` with any helpful findings
- When you detect you are within 10% of your available context window before auto-compact, pause to update your to-do list and the `<task>.md` with all important hand-off details, including the primary goals and non-goals of the task and any implementation decisions that have already been made

## After answering questions

- When asked a question, think hard and respond
- If the answer involved explaining a non-trivial concept with code examples, or an elegant solution to common problem, or an otherwise appealing tip/trick, ask: "This could make a good TIL - want me to draft it?"
- Then prompt for which action(s) to take next

## Pull Requests

- **Always use the `writing-pr-descriptions` skill** when creating or updating PRs
- The skill contains my voice guide, rules, and anti-patterns
- Never draft PR descriptions without it - even for "simple" PRs

## CI System Information

### Recursion Pharma Organization

- **CI System**: Codefresh
- **CLI**: `codefresh` (installed via Homebrew)

#### Inspecting CI Failures

When you see a CI failure in a recursionpharma PR, **use the `inspecting-codefresh-failures` skill** to analyze it.

The skill will:

- Extract build IDs from PR status checks
- Fetch build logs from Codefresh
- Identify specific errors with file:line references
- Provide root cause analysis
- Return a formatted report ready to include in reviews

**Always investigate CI failures** - include specific error details in your review (not just "CI is failing"). Distinguish between errors introduced by the PR vs pre-existing issues.

## Python Preferences

- Prefer `from __future__ import annotations` over `from typing import TYPE_CHECKING`
