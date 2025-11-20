## Remembering

- Plan in these phases: clarify -> explore -> plan -> document plan in a `.claude/specs/<task>.md`
- The plan phase should produce a `<task>.md` for me to review and help improve
- Keep the `<task>.md` up-to-date as things change and ensure remove any out-of-date information is removed promptly
- Assume you will need to hand off this plan to a DIFFERENT agent for implementation
- Optimize for the future agent's understanding by including all essential details and omitting everything else

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

### 3. Direct Tool Usage Last

Use Claude tools directly only for:
- Simple, one-off operations
- Tasks requiring immediate context from the conversation
- Operations where overhead of a skill/agent isn't justified

### General Context Management

- Update the `<task>.md` with any helpful findings
- When you detect you are within 10% of your available context window before auto-compact, pause to update your to-do list and the `<task>.md` with all important hand-off details, including the primary goals and non-goals of the task and any implementation decisions that have already been made

## Don't code after being asked a question

- When asked a question, think hard and respond and then prompt me for which action(s) to take next

## Pause to let me commit

- Implement changes one small theme at-a-time
- Pause after each theme is implemented (behavior + test case(s) + documentation) to let me commit myself

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
