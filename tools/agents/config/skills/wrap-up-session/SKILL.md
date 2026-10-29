---
name: wrap-up-session
description: Answer "is this session all done?" by accounting for every action the session raised and listing what is still open. Run it in the message that starts a review session, and whenever the user asks whether the session can be closed.
---

## Account for every action

List every action that came up in the session:

- What the user asked for, including requests made in passing inside longer messages
- What you said you would do ("I'll also", "later", "next", "follow-up")
- Questions you asked that the user never answered
- Approvals the user gave that you never acted on
- Tool calls that failed or were denied and were never retried or worked around, including calls
  whose output looked fine but hid an error, such as empty output with stderr discarded
- Changes in a working tree that are not committed, and commits that are not pushed
- Drafts shown to the user and never posted

Give each one exactly one status, with its evidence:

- **Done:** the commit, `file:line` or URL that shows it
- **Deferred:** where it is recorded (a ticket, a `docs/questions/` file)
- **Dropped:** the user's words deciding that
- **Open:** none of the above. An item the user never ruled on is Open, even when they approved a
  list that left it out.

The full transcript of this session is at `~/.claude/projects/<cwd-slug>/<session-id>.jsonl` if you
need to check what was said. The slug is the starting directory with `/` and `.` replaced by `-`.
The session ID is the name of the scratchpad's parent directory. The directory names start with
`-`, so from inside `~/.claude/projects`, glob them as `./*/*.jsonl`, or tools like grep read them
as options. Messages are the records whose top-level `type` is `user` or `assistant`. A `user`
record is something the user typed only when its `message.content` is a string and it has no
`isMeta: true`. Subagent transcripts are under `<session-id>/subagents/`.

## Report

List only the Open items, one line each, saying what is left to do. Leave out everything Done,
Deferred or Dropped. If nothing is Open, say "This session can be closed now." Otherwise end with
"This session can be closed once these are dealt with", and ask each item that needs the user's
decision as a numbered question. Change nothing.
