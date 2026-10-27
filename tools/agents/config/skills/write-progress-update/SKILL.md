---
name: write-progress-update
description: Draft a short Slack message summarizing progress on a work project over a period of time, gathered from Jira, GitHub and Slack. Use when the user asks for a progress update, status update or "what we did and what's next" message. Saves a Slack draft for the user to review; never sends.
---

# Write a progress update

A busy manager should get through the update in under a minute and come away knowing what is now
possible, what is coming next, and roughly what follows. Everything below serves that.

## 1. Read the request

The user names, in one line, as much of this as they know:

- **Series title**, such as "Deployment updates". It is the first line of every update in the
  series.
- **Topic**: what the update covers, such as the whole project or one part of it. Do not assume it.
  Take it from the request, or from the previous update's content, and ask when neither settles it.
- **Scope**: Jira epics, a JQL query or project, GitHub repos, and Slack channels to read.
- **Audience**: engineers, leaders, or a description.
- **Destination**: the Slack channel the update will be posted in.

Ask in one message for anything missing that you cannot find. A scope can often be filled in from
the previous updates' links (step 2).

## 2. Find the previous updates

Search Slack for messages from the user `in:` the destination channel only, newest first, using the
title's main words without quotes. Titles drift between posts ("update" or "updates", a colon), so
confirm a match by its shape: a title line followed by one or more numbered lists. Use the title as
the user gives it now, even if earlier posts worded it differently.

The user's DM to themselves is a scratchpad for drafts. Nothing in it is ever a source or a
previous update: leave it out of every search and read in this skill.

Read the last two updates in full, with their thread replies. What they or their replies reported
is already reported; match items to them by ticket key, not by title, because tickets get renamed.
The latest one's forward-looking lists (whatever they are called) are the first thing to check
progress against. The window runs from the latest update until now. If there is no previous
update, cover the last two weeks and say so.

## 3. Gather, one subagent per source

Spawn one subagent per source (Jira, GitHub, Slack) in parallel, and tell each to read the sources
itself and spawn no subagents. Tell each:

- the window, and to convert it to that source's time handling. Jira returns dates with the user's
  Jira timezone offset and JQL bounds are in that timezone; read the offset from a returned date
  inside the window, since daylight saving changes it. GitHub's `merged:` dates are UTC. Slack
  takes dates or Unix timestamps.
- to check when something actually finished (Jira `resolutiondate`, PR `mergedAt`), not its
  current status, which may have changed since. A Jira ticket resolved as Won't Do, Duplicate or
  similar did not finish; it is left out, or listed as a decision when closing it was one.
- for Jira, to request only the fields it needs (summary, status, resolution, resolutiondate,
  assignee), because wider requests overflow the response
- to look back as far as the update before the latest one, for finished work neither update
  mentioned
- for Slack: read the named channels, and also search all channels and DMs for the topic's key
  words and the names of systems in scope, since decisions and plans are often discussed in DMs
- to ignore the user's DM to themselves entirely

Each returns findings, each with:

- a link
- the date it finished (merged, closed or decided), or "open"
- the people involved, with their Slack user ID where known (an ID taken from an existing
  `<@U…>` mention counts)
- where it came from: for Slack, the channel name and whether it is public, private or a DM. When
  a message result does not say, look the channel up with `slack_search_channels`; if the type
  still cannot be confirmed, treat it as private

A source that fails to load is reported as failed, never as an empty list. A source that loads but
has nothing in the window is reported as empty.

## 4. Review candidates with the user

Group findings into a few candidate items before writing any prose. An item is something a reader
cares about, which usually spans several tickets and PRs: "the new dev deployment is ready for most
app work" rather than one line per ticket. Aim for the handful of items that matter most, not for
completeness. Order each list by how much it matters to the reader, most first, and suggest which
items to cut.

Show:

- any source that failed
- the latest update's link (or the two-week fallback)
- a numbered **Done** list: work finished and not yet reported, and decisions made
- a numbered **Next up** list: open work, and decisions still to make
- for each item: one line, its links, its finish date, who did it, and a ⚠️ on each source that is
  a DM or a private channel other than the destination. The ⚠️ marks a source, not the item
- a short **Left out** list: what you found but judged off-topic or minor, so the user can add it
  back

Ask the user to cut, merge, add, reword, and mark detail for a thread reply. Items the user adds
need no link. Unless the user keeps a ⚠️ source, the draft uses none of what came only from it. An
item with any other source stays, built from those sources alone; an item whose only sources are ⚠️
is left out by default.

## 5. Write the draft

This is the default shape, not a form to fill. Drop a section with nothing in it, and drop the
closing line when it adds nothing. Two items is fine when that is all that matters.

```
:emoji: <Series title>

:emoji: Done
1. <What is now true or possible> <link on the key words, or ([KEY](url)) at the end> _(<optional aside>)_

:emoji: Next up
1. <What will be true> ([KEY](url))

_<Optional: one sentence on what comes after that>_
```

- Reuse the header emojis from earlier updates in the series, looking further back when the latest
  ones lack a section.
- One line per item, and at most one link per item: the ticket or doc that best explains it.
- Every item makes sense to someone who does not click its link.
- Lead with what a reader can now do or will be able to do, not with the work done.
- For leaders, leave out system names. For engineers, system names are fine, but outcomes still
  lead.
- Write standard markdown: links as `[text](url)`, mentions as `<@U…>`. Mention only people whose
  Slack user ID you have, and use their name without `@` otherwise.
- The closing sentence is your guess. Say so to the user.

## 6. Save it as a Slack draft

Save the draft with `slack_send_message_draft` in the user's DM to themselves, never in the
destination channel. If a draft already exists there, tell the user and stop; do not replace it.
Tell the user where it is and that nothing was sent. Never send or schedule a message.

If the user marked detail for a thread reply, show it in the terminal and ask them to say when
they have posted the main message. Then find it: search messages from the user `in:` the
destination channel, posted after the draft was saved, whose first line is the series title. Show
the user its permalink and first line and ask them to confirm it. Save the thread reply with
`slack_send_message_draft` and that message's `thread_ts` only after they confirm. If no message or
more than one matches, ask the user for the link instead.
