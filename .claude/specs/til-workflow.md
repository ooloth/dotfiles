# TIL Workflow Spec

This spec documents a workflow for Claude to suggest and draft TIL-style blog posts based on conversations, git history, and Notion content.

## Goals

- Enable Claude to organically suggest TIL topics during conversations
- Provide explicit commands to scan for TIL opportunities
- Draft TILs in the user's voice with proper Notion formatting
- Keep Claude's drafts clearly separated from user's content

## Non-Goals

- Auto-publishing (user always reviews and publishes)
- Editing existing user content (Claude only creates new pages)
- Complex multi-part blog posts (TILs only)

---

## Architecture

### Skills (in `~/.claude/skills/`)

```
skills/
  scanning-git-for-tils/
    SKILL.md
    scan_git.py
  scanning-notion-for-tils/
    SKILL.md
    scan_notion.py
  drafting-til/
    SKILL.md              # Voice guide, format rules, property mappings
```

### Commands (in `~/.claude/commands/`)

```
commands/
  suggest-tils.md         # Orchestrates the full workflow
```

### Database Changes

Add "Claude Draft" status to Writing database (Status property).

### CLAUDE.md Addition

Add organic trigger hint to global CLAUDE.md.

---

## Writing Database Schema

**Database URL**: `https://www.notion.so/eb0cbc7a4fe4495499bd94c1bf861469`
**Data Source ID**: `c296db5b-d2f1-44d4-abc6-f9a05736b143`

### Key Properties for TIL Creation

| Property    | Type         | TIL Value                          |
| ----------- | ------------ | ---------------------------------- |
| Title       | title        | The TIL title                      |
| Status      | status       | "Claude Draft" (new status to add) |
| Type        | select       | "how-to"                           |
| Destination | multi_select | ["blog"]                           |
| Description | text         | One-line summary                   |
| Slug        | text         | URL-friendly version of title      |
| Topics      | relation     | Link to relevant Topics            |
| Research    | relation     | Link to source Research items      |
| Questions   | relation     | Link to source Questions           |

### Status Options (existing)

- New, Researching, Drafting, Editing, Publishing, Published, Paused, Migrated to content repo, Archived

**Add**: "Claude Draft" (in to_do group, distinct color like orange)

---

## Voice Guide

### Source Material Analyzed

1. **Notion post**: "The filter(Boolean) trick" - ~500 words, detailed how-to
2. **Website post**: "Ignoring files you've already committed" - ~150 words
3. **Website post**: "A '!' prefix makes any Tailwind CSS class important" - ~50 words

### Two TIL Formats

**Ultra-short (50-150 words)**

- Single tip with one code example
- Minimal explanation
- Best for simple gotchas or quick references

**Standard (300-500 words)**

- Problem → bad solution → good solution structure
- Multiple code examples
- More explanation and personality
- Best for concepts that need unpacking

### Voice Characteristics

1. **Direct titles** - State exactly what the reader will learn
   - Good: "The filter(Boolean) trick"
   - Good: "A '!' prefix makes any Tailwind CSS class important"
   - Bad: "Understanding Array Methods in JavaScript"

2. **Problem-first opening** - Start with the issue
   - "If you try to `.gitignore` files _after_ committing them, you'll notice it doesn't work"
   - "You have an array... But hiding in that array are some unusable null or undefined values"

3. **Conversational tone**
   - Use "you" to address reader directly
   - Contractions are fine
   - Second person throughout

4. **Playful asides and humor**
   - "Illegal! Now you're a criminal"
   - "Oh noooo..."
   - "Really, really no vertical margins"
   - Don't overdo it - one or two per post

5. **Code examples always included**
   - Show the problem code
   - Show the solution code
   - Inline comments can have personality

6. **No fluff**
   - Get to the point quickly
   - Short paragraphs
   - Scannable structure

7. **Helpful signoff** (optional)
   - "Hope that helps!"

### What NOT to Do

- Don't be formal or academic
- Don't over-explain obvious things
- Don't use passive voice
- Don't add unnecessary caveats
- Don't start with "In this post, I'll show you..."

---

## Skill Specifications

### scanning-git-for-tils

**Purpose**: Analyze recent git commits for TIL-worthy patterns

**Description** (for SKILL.md):

```
Scans git history for commits that might make good TIL blog posts.
Looks for bug fixes, configuration changes, gotchas, and interesting
solutions. Returns a formatted list of suggestions with commit context.
Use when user asks for TIL ideas from their recent work.
```

**What to look for**:

- Commits with "fix" that solved a non-obvious problem
- Configuration changes (dotfiles, CI, tooling)
- Dependency updates that required code changes
- Commits with detailed messages explaining "why"
- Patterns that repeat (user keeps solving same problem)

**Output format**:

```
📝 TIL Opportunities from Git History (last 30 days):

1. **Git: Ignoring already-tracked files**
   - Commit: abc123 "fix: properly ignore .env after initial commit"
   - Pattern: Removed cached files, updated .gitignore
   - TIL angle: Common gotcha - .gitignore doesn't affect tracked files

2. **Zsh: Fixing slow shell startup**
   - Commits: def456, ghi789 (related)
   - Pattern: Lazy-loaded nvm, deferred compinit
   - TIL angle: Diagnose and fix slow shell initialization
```

### scanning-notion-for-tils

**Purpose**: Find unpublished Writing items ready for TIL treatment

**Description** (for SKILL.md):

```
Searches the Notion Writing database for unpublished items that could
become TIL posts. Prioritizes items with Status=New or Drafting,
Type=how-to, and recent activity. Returns suggestions with context.
Use when user wants to review their backlog for TIL opportunities.
```

**Search criteria**:

- Status: New, Researching, or Drafting
- Type: how-to (preferred) or reference
- Has linked Research or Questions (indicates depth)
- Sorted by Last edited (recent activity)

**Output format**:

```
📝 TIL Opportunities from Notion Backlog:

1. **"Make TS understand Array.filter by using type predicates"**
   - Status: Drafting | Last edited: 2 months ago
   - Has: 2 Research links, 1 Question
   - TIL angle: Type predicates let TS narrow filtered arrays

2. **"How to filter a JS array with async/await"**
   - Status: New | Last edited: 1 year ago
   - Has: 1 Research link
   - TIL angle: filter() doesn't await - need Promise.all pattern
```

### drafting-til

**Purpose**: Create a TIL draft in Notion with proper voice and formatting

**Description** (for SKILL.md):

```
Drafts a TIL blog post in the user's voice and creates it in Notion
with Status="Claude Draft". Uses the voice guide for tone and format.
Includes proper property mappings for the Writing database.
Use when user approves a TIL suggestion and wants a draft created.
```

**SKILL.md should include**:

- Complete voice guide (from above)
- Property mappings
- Example TIL structures (ultra-short and standard)
- Instructions for using Notion MCP tools

**Creation process**:

1. Determine appropriate length (ultra-short vs standard)
2. Write title (direct, specific)
3. Write content following voice guide
4. Generate slug from title
5. Write one-line description
6. Create page with properties:
   - Status: "Claude Draft"
   - Type: "how-to"
   - Destination: ["blog"]
   - Topics: (link if obvious match)
   - Research/Questions: (link to sources)

---

## Command Specification

### /suggest-tils

**Purpose**: Orchestrate the full TIL suggestion and drafting workflow

**Workflow**:

```
Phase 1: Source Selection
─────────────────────────
Which sources to scan?
1. Git history (last 30 days)
2. Notion backlog
3. Both
>
```

```
Phase 2: Scan Results
─────────────────────
[Invoke appropriate skill(s)]
[Display combined suggestions]

Select a topic to draft (number), or 'q' to quit:
>
```

```
Phase 3: Draft Creation
───────────────────────
[Invoke drafting-til skill with selected topic]
[Show preview of created page]

✅ Draft created: "Your TIL Title"
   Status: Claude Draft
   URL: https://www.notion.so/...

Actions:
o - Open in Notion
e - Edit properties
n - Draft another
q - Done
>
```

**State management**: Use TodoWrite to track workflow phase

---

## CLAUDE.md Addition

Add to global `~/.claude/CLAUDE.md` (symlinked from `tools/claude/config/CLAUDE.md`):

```markdown
## TIL Suggestions

When you help solve a non-trivial problem or explain something in detail,
consider if it would make a good TIL blog post. Look for:

- Gotchas or surprising behavior
- Elegant solutions to common problems
- Things worth documenting for future reference

Suggest naturally: "This could make a good TIL - want me to draft it?"

To scan for TIL opportunities or draft posts, use the `/suggest-tils` command.
```

---

## Implementation Order

1. **Add "Claude Draft" status** to Writing database
   - Use `mcp__notion__notion-update-database` to add status option

2. **Create drafting-til skill** first (other skills depend on understanding the output format)
   - `~/.claude/skills/drafting-til/SKILL.md`

3. **Create scanning-git-for-tils skill**
   - `~/.claude/skills/scanning-git-for-tils/SKILL.md`
   - `~/.claude/skills/scanning-git-for-tils/scan_git.py`

4. **Create scanning-notion-for-tils skill**
   - `~/.claude/skills/scanning-notion-for-tils/SKILL.md`
   - `~/.claude/skills/scanning-notion-for-tils/scan_notion.py`

5. **Create /suggest-tils command**
   - `~/.claude/commands/suggest-tils.md`

6. **Add CLAUDE.md hint**
   - Update `tools/claude/config/CLAUDE.md`

---

## Safety Rules

These rules prevent Claude from making unwanted edits:

1. **Never edit existing pages** unless explicitly asked
2. **Always use Status="Claude Draft"** for new pages
3. **Show content before creating** - user approves the draft text
4. **Link sources via relations** - don't modify source pages
5. **User publishes** - Claude never changes Status to Published

---

## Testing the Workflow

After implementation, test with:

1. `/suggest-tils` → select "Git history" → verify scan results
2. `/suggest-tils` → select "Notion backlog" → verify scan results
3. Select a suggestion → verify draft created with correct properties
4. Check Writing database filtered by Status="Claude Draft"
5. Organic test: Solve a problem, see if Claude suggests TIL

---

## Future Enhancements (Out of Scope)

- Browser history scanning
- Slack conversation scanning
- Automatic topic detection/linking
- Draft quality scoring
- Publishing workflow automation
