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

## CI System Information

### Recursion Pharma Organization

- **CI System**: Codefresh
- **CLI**: `codefresh` (installed via Homebrew)
- **When to use**: When reviewing PRs from `recursionpharma/*` repos with failing CI

#### Inspecting Codefresh CI Failures

When you see a CI failure in a recursionpharma PR:

1. **Get PR status data** with `statusCheckRollup` field:
   ```bash
   gh pr view <number> --repo recursionpharma/<repo> --json statusCheckRollup
   ```

2. **Extract build ID** from the Codefresh URL in `targetUrl` or `detailsUrl`:
   - Format: `https://g.codefresh.io/build/{build-id}`
   - Example: `67c7469b3275b6f1b9f96f69`

3. **Get build details**:
   ```bash
   codefresh get builds <build-id> -o json
   ```

4. **Get full logs**:
   ```bash
   codefresh logs <build-id>
   ```

5. **Search for errors** (most useful):
   ```bash
   codefresh logs <build-id> | grep -B 10 -A 20 -i "error\|fail\|found.*errors"
   ```

#### When to investigate CI failures

- **ALWAYS** investigate CI failures in recursionpharma PRs during code review
- Include specific error details in your review (not just "CI is failing")
- Quote actual error messages with file:line references when available
- Explain root cause and whether it's related to PR changes or pre-existing issues

**Example**: When reviewing PR recursionpharma/phenomics-potency-prediction#2, I found the CI failed due to Ruff linting errors (10 total): undefined `random_seed` variables in `utils.py:331,333,365,367,369`, a 3373-character line in `parallel-curvefit.py:233`, and bare `except` clauses. These were pre-existing code quality issues exposed by the infrastructure change (switching from Nexus to Google Artifact Registry).
