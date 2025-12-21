## Memory

### Beads is the Single Source of Truth

**All planning lives in beads, not markdown files.** When asked "what's next?" or starting a new session:

1. Run `bd ready` to find available work
2. Run `bd list --status=in_progress` to see active work
3. Run `bd show <id>` for full context on any issue

**Do NOT duplicate plans in markdown files.** Implementation details (code snippets, design notes) go in the beads issue's `design` or `notes` fields. Delete any temporary planning files after implementation.

### Planning Workflow

1. **Clarify** - Understand the request, ask questions
2. **Explore** - Read code, gather context
3. **Plan** - Create beads epic/tasks with acceptance criteria
4. **Implement** - Work through tasks, update status as you go

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Working in Small Steps (CRITICAL - READ FIRST)

**You must NEVER commit code yourself during a session. The user commits.**

**Workflow for EVERY change:**

1. **Make one small change** - Implement one cohesive theme (behavior change across related files)
2. **Add or update tests** - If testing is relevant, add/update test cases for the behavior change
3. **Run tests** - Verify the change works and doesn't break anything
4. **STOP and report** - Describe what you changed and what tests you ran
5. **Wait** - Do not continue until user reviews and commits

**What is "one small change"?**

Good examples (one theme = one commit):

- ✅ Add aria-label to pagination nav + test that verifies it's present
- ✅ Add focus-visible styles to all interactive elements in the Likes page + visual regression test
- ✅ Add skip link to layout + add id="main" to all main elements + test both features
- ✅ Implement new validation function + comprehensive test suite for all edge cases

The key: **related changes that tell one story**. It's fine if the change touches multiple files, as long as they're part of the same logical theme.

**Never:**

- ❌ Batch UNRELATED changes (e.g., focus styles + aria-label + reduced-motion in one go)
- ❌ Commit yourself without explicit instructions to do so
- ❌ Say "this is ready to commit" and keep working
- ❌ Skip running tests

**Remember:** The user wants to review and commit each theme themselves. Stop after each one.

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

- Update beads issues with helpful findings (use `notes` or `design` fields)
- When you detect you are within 10% of your available context window before auto-compact, pause to update beads issues with all important hand-off details, including goals, non-goals, and implementation decisions already made

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
