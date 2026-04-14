---
name: validate
description: Confirm we have actually completed and completed validated what we planned to accomplish. TRIGGER whenever the user asks you to confirm a task is complete, if any implementation or validation was missed, etc.
argument-hint: '[task number or description]'
effort: high
model: opus
---

## Context

- The task (or issue, problem, ticket, etc) the user wants to discuss is what they mentioned here: $ARGUMENTS
- If they didn't provide a reference, assume they mean the changes on the current branch relative
  to the original plan you made

## Your task

### Phase 1: Understand the Problem

1. If the user did not specify what they want to discuss and you can't deduce it, ask them for that information
2. If you are unclear what the user is asking you to validate, clarify until you're quite sure
3. Once you understand the discussion topic, use as many subagents as you need to explore the
   problem definition and all relevant code paths and documentation and the changes you made
4. Proactively answer every question and follow-up question that occurs to you by exploring the
   codebase and anything else that would help you

### Phase 2: Assess the Solution for Gaps or Mistakes

1. After thoroughly understanding the problem and current solution, compare what you see to the
   ideal way to achieve the intended goal
2. Was the complete intention of the original task achieved?
3. Have all edge cases been handled?
4. Do all branches have well-designed automated tests?
5. Have you manually tested every branch and seen evidence that everything is working correctly?
