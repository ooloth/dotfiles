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


