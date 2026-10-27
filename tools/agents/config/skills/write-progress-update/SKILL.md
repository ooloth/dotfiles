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
- **Destination**: the Slack channel the update will be posted in.

Ask in one message for anything missing that you cannot find. A scope can often be filled in from
the previous updates' links (step 2).

## 2. Find the previous updates

Search Slack for messages from the user `in:` the destination channel only, newest first, using the
title's main words without quotes. Titles drift between posts ("update" or "updates", a colon), so
confirm a match by its shape: a title line followed by one or more numbered lists. Use the title as
the user gives it now, even if earlier posts worded it differently.

The user's DM to themselves is a scratchpad for drafts. Nothing in it is ever a source or a
previous update. Add `-in:<@U…>`, with the user's own Slack user ID, to the filters of every Slack
search in this skill, which excludes that DM from the results.

Read the last two updates in full, with their thread replies. What they or their replies reported
is already reported; match items to them by ticket key, not by title, because tickets get renamed.
The latest one's forward-looking lists (whatever they are called) are the first thing to check
progress against. The window runs from the latest update until now. If there is no previous
update, cover the last two weeks and say so.

## 3. Gather, one subagent per source

Spawn one subagent per source (Jira, GitHub, Slack) in parallel, and tell each to read the sources
itself and spawn no subagents. Tell each:

- the window, and to convert it to that source's time handling. JQL bounds are in the user's Jira
  timezone, which can differ from their local one: read the offset on the returned dates that fall
  inside the window (daylight saving changes it), and re-run with corrected bounds if the first
  query used the wrong ones. GitHub's `merged:` dates are UTC. Slack takes dates or Unix
  timestamps.
- to check when something actually finished (Jira `resolutiondate`, PR `mergedAt`), not its
  current status, which may have changed since. Work open at the window's end has no resolution
  or one dated after the end. A Jira ticket closed as Won't Do, Duplicate or similar did not
  finish, whichever of `status` or `resolution` says so (some projects record it only in the
  status); it is left out, or listed as a decision when closing it was one.
- that a decision counts from when it was made (the Slack message, or the merged PR that records
  it), not from when its ticket closed
- for Jira, to request only the fields it needs (summary, status, resolution, resolutiondate,
  assignee). Even then a large result is saved to a file instead of returned; read that file
  rather than re-querying in smaller pieces
- to look back as far as the update before the latest one, for finished work neither update
  mentioned
- for Slack: read the named channels, and also search all channels and DMs for the topic's key
  words and the names of systems in scope, since decisions and plans are often discussed in DMs
- to add `-in:<@U…>` with the user's Slack user ID to every Slack search, and to ignore the user's
  DM to themselves entirely

Each returns findings, each with:

- a link
- the date it finished (merged, closed or decided), or "open"
- the people involved, with their Slack user ID where known. An ID taken from an existing `<@U…>`
  mention counts, and so does matching a PR or ticket author to a Slack user by name with
  `slack_search_users`
- where it came from: for Slack, the channel name, or who the DM is with

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
- for each item: one line, its links, its finish date and who did it
- a short **Left out** list: what you found but judged off-topic or minor, so the user can add it
  back

A DM or private channel is a source like any other, and an item that came only from one is kept
or cut on how much it matters, like every other item. Leave out DMs that matched a search but have
nothing to do with the update.

The Done and Next up lists stand alone. No item refers to an earlier update's items by number or
says which of them it finishes; the previous update's lists are only for finding progress.

Ask the user to cut, merge, add, reword, and mark detail for a thread reply. Items the user adds
need no link.

## 5. Write the draft

This is the default shape, not a form to fill. Drop a section with nothing in it, and drop the
closing line when it adds nothing. Two items is fine when that is all that matters.

```
:emoji: **<Series title>**

:emoji: **Done**
1. **<What is now true or possible, opening words>** <rest of the line> <link on the key words, or ([KEY](url)) at the end> _(<optional aside>)_

:emoji: **Next up**
1. **<What will be true, opening words>** <rest of the line> ([KEY](url))

_<One sentence on the roadmap after Next up, pointing to the thread reply if there is one>_
```

- Reuse the header emojis and formatting, such as bold, from earlier updates in the series. Match
  sections by meaning (a "What remains" list is Next up), prefer the most recent, and look further
  back when the latest ones lack a section.
- One line per item, and at most one link per item: the ticket or doc that best explains it.
- The opening words of each item are bold: the first few words of the line itself, or a label
  such as "This week:", so a reader skimming the bold gets the gist. The bold is never a separate
  title that the rest of the line repeats. A decision's lead is "Decided with <@U…>:".
- Every item makes sense to someone who does not click its link.
- Lead with what a reader can now do or will be able to do, not with the work done.
- When the work adds up to something bigger than any one item, such as a milestone the previous
  update was working towards, make that the first Done item.
- An aside holds one short fact the reader needs, or is left out.
- Say it the way you would say it to a colleague. Write to inform a junior teammate, not to impress
  a leader: the test is whether a reader got through it quickly and understood the facts. Ticket
  titles are often written as formal claims ("An internal user is an admin exactly when…"); never
  copy one, and say what it means plainly.
- A decision reads "Decided with <@U…>: <what was decided>", naming who decided it.
- A PR is a fine link when no ticket covers the item.
- Every update is written in the same plain voice, whoever is in the channel. Name a system when
  its name is the clearest way to say what changed, and let the outcome lead.
- Write standard markdown: links as `[text](url)`, mentions as `<@U…>`. Mention only people whose
  Slack user ID you have, and use their name without `@` otherwise.
- Next up covers about the next week. The closing line below it then sums up, in one sentence,
  the rest of the roadmap after that week, from the user's plan when there is one and otherwise as
  your guess, which you tell the user. When a thread reply holds the full plan, the closing
  sentence also points to it ("_After that, PROD runs the app by about Nov 20; the full plan is in
  the :thread:_").
- A thread reply follows the same formatting: bold headings, numbered lists rather than bullets,
  and a link on every ticket key it names. The one-link limit applies only to the main message.

## 6. Save it as a Slack draft

Save the draft with `slack_send_message_draft` in the user's DM to themselves, never in the
destination channel. Slack keeps one draft per channel, and the tool cannot replace or delete
one. If a draft already exists there, ask the user to delete it and save once they say they have;
when the user asks for a revision, say this before they need to. Tell the user where the draft is
and that nothing was sent. Never send or schedule a message.

If the user marked detail for a thread reply, show it in the terminal and ask them to say when
they have posted the main message. Then find it: look for messages from the user in the
destination channel and in their DM to themselves, where users often post first to see how it
renders, posted after the draft was saved, whose first line is the series title. Read the DM with
`slack_read_channel`; this is the one use of that DM, and it is not a source. When the match is in
the DM, remind the user that a thread draft saved there does not move with the message. Show
the user its permalink and first line and ask them to confirm it. Save the thread reply with
`slack_send_message_draft` and that message's `thread_ts` only after they confirm. If no message or
more than one matches, ask the user for the link instead.
