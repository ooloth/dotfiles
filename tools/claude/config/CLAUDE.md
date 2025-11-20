## Remembering

- Plan in these phases: clarify -> explore -> plan -> document plan in a `.claude/specs/<task>.md`
- The plan phase should produce a `<task>.md` for me to review and help improve
- Keep the `<task>.md` up-to-date as things change and ensure remove any out-of-date information is removed promptly
- Assume you will need to hand off this plan to a DIFFERENT agent for implementation
- Optimize for the future agent's understanding by including all essential details and omitting everything else

## Managing your context window

- You do best thinking when you have less in your context rather than more
- Minimize your context usage by delegating tasks that are straight-forward to describe and report back about but may require lots of exploration to complete to my custom agents (`tools/claude/config/agents`) or ephemeral Task agents you create
- Ensure any agents you delegate to know exactly what you want them to report back, and what details to include
- Update the `<task>.md` with any helpful findings
- When you detect you are within 10% of your available context window before auto-compact, pause to update your to-do list and the `<task>.md` with all important hand-off details, including the primary goals and non-goals of the task and any implementation decisions that have already been made

## Don't code after being asked a question

- When asked a question, think hard and respond and then prompt me for which action(s) to take next

## Pause to let me commit

- Implement changes one small theme at-a-time
- Pause after each theme is implemented (behavior + test case(s) + documentation) to let me commit myself

## TIL Suggestions

When you help solve a non-trivial problem or explain something in detail, consider if it would make a good TIL blog post. Look for:

- Gotchas or surprising behavior
- Elegant solutions to common problems
- Things worth documenting for future reference

Suggest naturally: "This could make a good TIL - want me to draft it?"

To scan for TIL opportunities or draft posts, use the `/suggest-tils` command.

## CI System Information

### Recursion Pharma Organization

- **CI System**: Codefresh
- **CLI**: `codefresh` (installed via Homebrew)

#### Inspecting CI Failures

When you see a CI failure in a recursionpharma PR, **use the `inspect-codefresh-failure` skill** to analyze it.

The skill will:
- Extract build IDs from PR status checks
- Fetch build logs from Codefresh
- Identify specific errors with file:line references
- Provide root cause analysis
- Return a formatted report ready to include in reviews

**Always investigate CI failures** - include specific error details in your review (not just "CI is failing"). Distinguish between errors introduced by the PR vs pre-existing issues.
