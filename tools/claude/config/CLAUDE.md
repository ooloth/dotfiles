# 🚨 CRITICAL - READ THIS FIRST BEFORE EVERY RESPONSE 🚨

## Questions ALWAYS Require Discussion First

**IF the user's message contains ANY of these:**
- A question mark `?`
- Words like: "can we", "should we", "what if", "could we", "would it", "are we"
- Requests for explanation: "why", "how does", "what's the"
- Requests for analysis: "do we", "are there"

**THEN you MUST:**
1. **ANSWER the question** with options/analysis/explanation
2. **STOP and WAIT** for explicit implementation approval
3. **DO NOT use Edit/Write/Bash tools** until user says "do it", "go ahead", "implement", "yes please do that", "make those changes"

**Approval phrases (OK to implement):**
- ✅ "do it", "go ahead", "implement that", "yes please do that", "make those changes", "fix it", "add it"

**Discussion phrases (NOT approval - keep discussing):**
- ❌ "yes", "yes please", "ok", "sounds good", "that makes sense", "correct", "right"

**When in doubt: ALWAYS discuss first, implement second.**

**Example:**
- User: "Can we reduce the number of args we pass to fetchItunesItems?"
- You: [Propose solution with options] then STOP
- User: "yes please" ❌ This means "yes I agree with your analysis" NOT "implement it"
- User: "yes please do that" ✅ This means implement

---

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

### When to Create Beads Issues (vs TodoWrite)

**ALWAYS use beads for:**

- Work that involves making decisions about what to do/skip (e.g., PR review assessment, optimization results)
- Any multi-item work where you need to record WHY you're addressing/skipping each item
- Work that could survive an auto-compact (beads persists; TodoWrite doesn't)
- Assessments with categories (must fix, should fix, won't fix)

**TodoWrite is only for:**

- Simple task tracking within a single beads issue (breaking down implementation steps)
- Ephemeral notes that don't need to persist beyond the current work item

**CRITICAL: When assessing multiple items (PR feedback, optimization results, bug lists):**

```bash
# DO THIS FIRST - before implementing anything:
bd create --title "Address PR review feedback" \
  --type task --priority P1 \
  --design "Assessment:

MUST FIX:
- Item 1 (reason)
- Item 2 (reason)

SHOULD FIX:
- Item 3 (reason)

WON'T FIX:
- Item 4 (reason we're skipping)

Each fix = one commit per 'Working in Small Steps'"

# Then work through items, updating notes as you go:
bd update <id> --notes "Item 1: Discovered X during implementation"
```

**This applies even if you're within your context window** - auto-compact can happen anytime.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

## BEFORE Implementing: Always Create Beads Task (BLOCKING RULE)

**STOP. Read this BEFORE touching any code.**

When the user approves work ("yes", "do it", "go ahead", "please fix"):

### Mandatory Workflow

```
1. ❌ Do NOT read files
2. ❌ Do NOT start implementing
3. ✅ CREATE BEADS TASK FIRST with `bd create`
4. ✅ Capture: what's broken, approved approach, what success looks like
5. ✅ THEN read files and implement
```

**Why this is blocking**: Auto-compact or disconnection can happen anytime. Without a beads task, the next Claude has no context about what you were doing or why.

### Examples

**WRONG** ❌

```
user: "Yes please fix the Pushover notifications"
assistant: *Immediately reads .github/workflows/ci.yml and starts implementing*
```

**RIGHT** ✅

```
user: "Yes please fix the Pushover notifications"
assistant: "Creating beads task first to ensure persistence..."
assistant: *Runs `bd create --title "Fix Pushover notifications..." --type task`*
assistant: *Sets status to in_progress*
assistant: *THEN reads files and implements*
```

### Applies To

**ALL implementation work, no exceptions:**

- Bug fixes (even "quick" ones)
- Feature additions
- Refactoring
- CI/workflow changes
- Configuration updates
- Documentation that involves code

**If you find yourself about to read a code file to implement something**, stop and create the beads task first.

## Before Making Changes

Check the user's last message before using Edit, Write, or Bash:

- Has `?` → Answer the question, present options, wait for decision
- Feedback about your behavior → Acknowledge, wait for instruction
- Explicit command ("do it", "fix X", "committed") → Proceed

Examples:

- "Would it be simpler to...?" → Answer, present options, wait
- "You should have asked first" → Acknowledge, wait for instruction
- "Please fix the build" → Proceed with fix

## Working in Small Steps (CRITICAL - READ FIRST)

**You must NEVER commit code yourself during a session. The user commits.**

**Workflow for EVERY change:**

1. **Make one small change** - Implement one cohesive theme (behavior change across related files)
2. **Add or update tests** - If testing is relevant, add/update test cases for the behavior change
3. **Run tests** - Verify the change works and doesn't break anything
4. **STOP and report** - Describe what you changed and what tests you ran
5. **Wait for user to say "committed"** - Do not continue or close beads tasks until user confirms
6. **Repeat steps 1-5** - If the beads task needs more themes/commits, continue with the next logical change
7. **When beads task is fully complete** - Close it with `bd close <id> -r "summary of all work"`

**What is "one small change"?**

Good examples (one theme = one commit):

- ✅ Add aria-label to pagination nav + test that verifies it's present
- ✅ Add focus-visible styles to all interactive elements in the Likes page + visual regression test
- ✅ Add skip link to layout + add id="main" to all main elements + test both features
- ✅ Implement new validation function + comprehensive test suite for all edge cases

The key: **related changes that tell one story**. It's fine if the change touches multiple files, as long as they're part of the same logical theme.

**This workflow applies to ALL types of work:**

- ✅ New feature implementation
- ✅ PR review fixes (each individual fix = one theme)
- ✅ Optimization findings (each optimization = one theme)
- ✅ Refactoring tasks (each refactor = one theme)
- ✅ Bug fixes (each bug = one theme)
- ✅ Any other multi-step work

**Even if the user says "fix them all" or "implement all of these"**, you must stop after EACH individual theme for review and commit.

<example>
user: "Add error handling to the API functions"
assistant: *Creates todo list with all API functions that need error handling*
assistant: *Adds error handling to notion/getPosts.ts + tests*
assistant: "Added error handling to getPosts function. Tests pass. Ready to commit."
assistant: *STOPS and waits for user to say "committed"*
❌ Does NOT continue to the next API function
</example>

**Before starting multi-step work:**

If you're about to implement 2+ themes (whether from beads, optimization, PR reviews, or any other source):

1. **Create beads tasks** - One task per theme, or one parent task with the plan in `design` field
2. **Why:** If disconnected, next Claude needs the approved plan
3. **Then** proceed with "Working in Small Steps" workflow

**One beads task may need many commits:**

- A single beads task might result in 1 commit or 25 commits, depending on how many distinct themes emerge
- Stop after EACH theme for user to review and commit
- Only close beads task when ALL themes for that task are done and committed

**Never:**

- ❌ Batch multiple themes together (e.g., theme 1 + theme 2 + theme 3 in one go)
- ❌ Batch UNRELATED changes (e.g., focus styles + aria-label + reduced-motion in one go)
- ❌ Continue to the next theme without waiting for user to say "committed"
- ❌ Commit yourself without explicit instructions to do so
- ❌ Say "this is ready to commit" and keep working
- ❌ Skip running tests
- ❌ Close beads tasks before the user says they've committed
- ❌ Move to the next task without user explicitly telling you to

**Remember:** The user wants to review and commit each theme themselves. Stop after each one. ONE theme = ONE stop.

## Beads Task Management

**Beads is the single source of truth. All task details must be captured in beads, not ephemeral todo lists.**

**Why:** If the session gets disconnected, the next Claude needs the full context.

**Workflow:**

1. User tells you to work on a beads task
2. You mark it `in_progress` with `bd update <id> --status in_progress`
3. You implement changes as multiple themes/commits (following "Working in Small Steps" above)
4. After each theme: STOP, report, wait for user to say "committed"
5. Repeat until all themes for the task are done
6. **When user confirms final commit:** Close task with `bd close <id> -r "summary of all work"`
7. **Offer next options:** Run `bd ready` and `bd list --label <current-label> --status open` to show what's available, then present 2-3 options with brief context

**After closing a task, ALWAYS present options:**

```
Task complete! What would you like to do next?

1. Continue with [current area] tasks on this branch:
   - META-xyz: [Brief description]
   - META-abc: [Brief description]

2. Switch to a different area:
   - See all ready tasks: `bd ready`
   - [List any deferred tasks if relevant]

3. Something else?
```

**Capturing context in beads:**

- Use `bd update <id> --notes "..."` to add implementation details discovered during work
- Use `bd update <id> --design "..."` for code snippets, architectural decisions
- Update task description if you discover the scope was different than expected
- Don't rely on ephemeral TodoWrite for anything that needs to persist - use beads
- If you're within 10% of context limit, capture ALL important decisions in beads before auto-compact

## Managing your context window

- You do best thinking when you have less in your context rather than more
- Minimize your context usage by choosing the right approach for each task:

### 0. Use Beads to Survive Auto-Compact (Do This First!)

**Before starting ANY multi-item work, capture decisions in beads:**

- **Decision matrices**: When assessing what to do/skip (PR reviews, optimization, bugs)
- **Multi-step plans**: Break down into beads tasks BEFORE implementing
- **Important discoveries**: Use `bd update <id> --notes` as you work
- **Why we're doing X**: Capture rationale in `--design` field so next Claude understands

**Remember:** TodoWrite is ephemeral; beads persists across auto-compact and session boundaries.

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

When you answer a question or complete an assessment:

- If the answer involved explaining a non-trivial concept with code examples, or an elegant solution to common problem, or an otherwise appealing tip/trick, ask: "This could make a good TIL - want me to draft it?"
- Ask what action(s) to take next (don't assume)

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
