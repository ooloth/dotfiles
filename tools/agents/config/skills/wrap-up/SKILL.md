---
name: wrap-up
description: End a session by confirming every action it mentioned was dealt with, then finding what in the codebase and the backlog would mislead the next agent. Reports both and fixes only what the user approves.
effort: high
model: opus
---

## Order of work

The wait is set by the slowest subagent, so start both passes first, then account for the actions
while they run:

1. Run `wrap-up-codebase` on what this session changed, passing its cold reader this extra
   question: "What would you do next in this repo, and what told you to?" It launches its fresh
   subagent and cold reader, and returns its sorted list.
2. Run `wrap-up-backlog` on what this session changed and decided, at the same time.
3. While they run, do Step 1 and the repo's own checks (from CONTRIBUTING or its equivalent).

Both passes only find and sort. Nothing they return is applied until the user approves it.

## Step 1: Account for every action

Account for every action as the `wrap-up-session` skill's first section describes.

## Step 2: Report and stop

Send one message with:

1. **The cold read** from `wrap-up-codebase`: what it would do next, the signal it followed, and
   whether that passes. It passes only if it picks the right next thing for the right reason,
   because the signal it followed is the one the next agent will follow. When it names a procedure,
   such as a skill to run, grade where that procedure would lead. When the right next step is
   written nowhere a fresh agent would look, that is a finding.
2. **The ledger:** a table of every action from Step 1, with its status and evidence.
3. **The codebase findings:** the fixes, each with its location, what misleads and the exact edit,
   then the asks with their lettered options. Lead with whatever would actively mislead.
4. **The backlog findings:** the fixes, each with the ticket, the action and its exact wording,
   then the asks with their lettered options.
5. **Dismissed findings** from both passes, each with the reason.
6. **Out-of-scope problems noticed,** listed briefly and not fixed.

Then stop and wait.

## Step 3: Apply what the user approves

Make the approved codebase fixes in the working tree, then name each file you changed and say what
the change does. Do not commit, post, or close anything. Each of those needs its own signal from the
user. A ticket change is posted only after the user approves its exact wording.
