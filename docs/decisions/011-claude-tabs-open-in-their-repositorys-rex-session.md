---
number: 011
status: accepted
date: 2026-11-03
---

# 011 — Claude tabs open in their repository's Rex session

## Forced by

hub opens investigation tabs in Rex and needs short tab labels that still can't be mistaken for
another repository's tab, because hub finds an open tab by its label. The skills put every tab in
one `Workers` session, so the only way to keep two repositories' `PR 12` tabs apart there is to
name the repository in every label, which makes the sidebar hard to scan.
[#250](https://github.com/ooloth/dotfiles/issues/250),
[hub#394](https://github.com/ooloth/hub/issues/394).

## Decision

A Claude tab opened without an explicit session goes in the Rex session labelled `Workers (<repo>)`,
where `<repo>` is the last path segment of the repository's `origin` URL, without `.git`. So every
checkout and worktree of one repository shares its session, whatever its directory is called. A
directory outside any repository, a repository with no `origin`, or a URL that yields no name uses
`Workers`. `claude-tab.bash` applies the rule and prints the session it chose, and hub applies the
same rule to the GitHub name of each repository it tracks. `orchestrate-rex` keeps its session per
ticket by passing `-s`.

## Rejected

- **One `Workers` session, with the repository in every tab label.** It keeps one place to look,
  and is rejected because labels such as `hub PR 12 (alice): review-code` crowd the sidebar. It
  reverses if Rex shows sessions in a way that makes switching between them costlier than scanning
  longer labels.
- **One `Workers` session, with no repository anywhere.** It is what existed, and is rejected
  because a tool looking up a tab by label can find another repository's tab with the same number
  and use it in place of its own. It reverses only if no tool looks tabs up by label.
- **Naming the session after the checkout's directory.** It needs no remote, and is rejected because
  a checkout can carry a nickname or a suffix, such as `agency-1` for a second clone of `agency`,
  which splits one repository across sessions and names it differently from hub. It reverses if
  every clone is guaranteed to sit in a directory named after its repository.

## Risk

Two repositories with the same name under different owners share a session, and their tabs with the
same number collide there. Tabs opened before this rule stay in `Workers` until they close.

## Revisit when

Two tracked repositories share a name, or Rex gains a way to group tabs within a session.
