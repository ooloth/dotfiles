---
description: Review a pull request with AI-assisted feedback and inline commenting.
---

## Your role

Provide thoughtful, constructive PR review that helps the author improve their code. Focus on teaching and suggesting, not dictating. Respect the author's ownership while ensuring quality.

## Usage

Provide a PR number (if in a repo directory) or full GitHub URL:

- `/review-pr 123` (when in repo directory)
- `/review-pr https://github.com/org/repo/pull/123` (from anywhere)

## Process

Fast, focused review of a single PR with no session overhead.

---

### Phase 1: Fetch PR Data

Extract org/repo/number from input and fetch:

```bash
gh pr view <number> --repo <org>/<repo> --json title,body,commits,files,url,headRefOid,reviews,comments,statusCheckRollup,author
```

```bash
gh pr diff <number> --repo <org>/<repo>
```

**For recursionpharma repos:** Check `statusCheckRollup` for failures. If CI is failing, note it for Phase 3.

**Output:** "✓ Fetched PR data"

---

### Phase 2: Understand Context

**Parse the PR data to understand:**

1. What problem does this PR solve? (from title/body)
2. Who is the author? (affects tone - see Edge Cases)
3. What files are changed?
4. **What have others already said?** (critical - avoid duplication)

**Process existing review context:**

Parse reviews and comments from the JSON:
- Extract all review comments (inline and general)
- Extract all conversation comments
- Group by file and line number
- Identify discussion themes
- Note who said what and when

**Output:** "✓ Analyzed PR context"

---

### Phase 3: Deep Review

Review the code changes across all dimensions:

**Correctness:**
- Completeness, edge cases
- Consistency with existing patterns
- Bugs, error handling
- Security (actual violations only)
- Compatibility, breaking changes
- Testing coverage

**Performance:**
- Actual inefficiencies only (not theoretical)

**Maintainability:**
- Design coherence, simplicity
- Clarity, cleanliness
- Future lens, developer experience

**What's Good:**
- Clever solutions
- Good abstractions
- Thorough testing
- Clear naming
- Thoughtful error handling

**For recursionpharma PRs with failing CI:**

Use the `inspecting-codefresh-failures` skill to investigate:

```bash
python3 ~/.claude/skills/inspecting-codefresh-failures/inspect.py <build-id>
```

Extract build IDs from `statusCheckRollup` data. Include failure analysis in review.

**Output:** "✓ Completed review analysis"

---

### Phase 4: Present Review

**Format:**

```markdown
## PR Review: [org/repo#number] "[title]"

### 📝 Existing Review Context

[If there are existing reviews/comments, show them:]

@alice reviewed 2 days ago (CHANGES_REQUESTED):
- auth.py:45-52: "Should log errors instead of swallowing"
- db.py:103: "Use parameterized queries"

@bob commented 1 day ago:
- General: "Looks good overall, just those two issues to address"

💬 Active discussions (2):
- auth.py:45-52: Error handling approach (2 comments)
- db.py:103: SQL injection fix (1 comment)

[If no existing reviews: "No prior reviews"]

---

### Summary

[1-2 sentence description of what this PR does]

---

### 👍 What's Good

- [Good pattern] in `file.ext:123-145` - [Why this is good]
- [Another strength] in `file.ext:67`

---

### Issues Found

#### 🚫 Blocking (must fix before merge)

**`auth.py:78-82`** [NEW - not mentioned in existing reviews]

```python
# auth.py:78-82
new_token = generate_refresh_token(user)
# ⚠️ No check if old token has expired
```

**Issue:** Missing token expiry validation

**Impact:** Security risk - users could refresh already-expired tokens

**Suggestion:** Add expiry check before generating new token

**Why:** Prevents potential security vulnerability where expired tokens remain valid through refresh mechanism

---

#### 💡 Should Fix (important quality issues)

**`api.py:134-156`**

```python
# api.py:134-156
def process_batch(items):
    for item in items:
        result = db.query(f"SELECT * FROM users WHERE id = {item.user_id}")
# ⚠️ SQL injection risk
```

**Issue:** SQL injection vulnerability

**Suggestion:** Could we use parameterized queries here? This would prevent SQL injection attacks.

**Why:** String interpolation in SQL queries allows malicious user input to execute arbitrary SQL

---

#### 🤔 Questions (clarify or suggest alternatives)

**`utils.py:45-52`**

**Question:** I'm curious about the caching strategy here. Have you considered using Redis instead of in-memory cache?

**Context:** In-memory cache won't work across multiple server instances. If we're planning to scale horizontally, this could be an issue.

---

#### ✨ Nit/Optional (polish)

**`models.py:89`**

**Optional:** Could rename `data` to `user_profile` for clarity

**Why:** More specific naming would make the code self-documenting

---

### Previously Identified (from existing reviews)

[If others already mentioned issues, list them here to acknowledge but not duplicate:]

- auth.py:45-52: Error handling (alice mentioned logging) - agree with alice's feedback
- db.py:103: SQL injection (alice mentioned parameterized queries) - +1 to alice's comment

---

### CI Failure Analysis (if applicable)

[Output from inspecting-codefresh-failures skill]

---

### Recommendation

**[APPROVE / REQUEST CHANGES / COMMENT]**

**Rationale:** [Why - what needs addressing or why it's good to merge]

---

### 📍 Key Areas to Review

[List 3-5 most important file:line references for quick navigation:]

- auth.py:78-82 - Missing token expiry validation (🚫 Blocking, NEW)
- api.py:134-156 - SQL injection risk (💡 Should fix)
- utils.py:45-52 - Caching strategy question (🤔)

---

### 🎬 Actions

**o** - Open PR in browser
**i** - Add inline comments (AI-assisted)
**a** - Approve via gh CLI (general comment only)
**c** - Request changes via gh CLI (general comment only)

What would you like to do?
```

Wait for user input.

---

## Action Handlers

**o - Open in browser:**

```bash
open [PR URL from fetched data]
```

Then re-show action menu.

---

**a - Approve via gh CLI:**

```bash
gh pr review <number> --repo <org>/<repo> --approve --body "<review summary from above>"
```

Success: "✅ Review posted as APPROVED"

---

**c - Request changes via gh CLI:**

```bash
gh pr review <number> --repo <org>/<repo> --request-changes --body "<review summary from above>"
```

Success: "✅ Review posted as REQUEST CHANGES"

---

**i - Interactive inline comment builder:**

### Step 1: Show locations

```
Add inline comment to which area?
1. auth.py:78-82 - Missing token expiry validation (🚫 Blocking)
2. api.py:134-156 - SQL injection risk (💡 Should fix)
3. utils.py:45-52 - Caching strategy question (🤔)

Or type file:line (e.g., "models.py:89")
>
```

### Step 2: User selects location

Parse input:
- Number → use corresponding file:line from key areas
- file:line format → use directly
- Extract file path and line number

### Step 3: AI-Assisted Comment Drafting

Show code snippet and suggest socratic, teaching-focused comments:

```
Code at auth.py:78-82:

    new_token = generate_refresh_token(user)
    # No check if old token has expired

💡 Suggested comments (or write your own):

1. "I'm curious about the token expiry validation here. What happens if a user requests a refresh with an already-expired token? Should we validate expiry before generating a new one?"

2. "How are we handling the case where old_token has expired? I'm wondering if this could be a security concern if expired tokens remain valid through the refresh mechanism."

3. "I'm wondering if we should add an expiry check here. What's the intended behavior when someone tries to refresh an already-expired token?"

Select 1-3 to use/edit, or press Enter to write custom:
>
```

**Suggestion templates by issue type:**

Use full sentences, genuine questions, collaborative tone:

- **Error handling:** "I'm curious about...", "What happens when...", "How should we handle..."
- **Security:** "I'm wondering about security here...", "What happens if a user...", "Have we thought about..."
- **SQL injection:** "I'm wondering if...", "Have we considered parameterized queries...", "What would happen if..."
- **Missing tests:** "How can we verify...", "What edge cases should we consider...", "I'm curious how this behaves when..."
- **Performance:** "I'm curious about the performance implications...", "How does this scale when...", "Have we measured..."
- **Code clarity:** "I'm finding this a bit hard to follow...", "Could we clarify...", "What's the reasoning behind..."
- **Design:** "I'm wondering if there's a simpler approach...", "Have you considered...", "What led to this design choice..."

### Step 4: User responds

If they select 1-3:
- Show that suggestion pre-filled
- They can edit or accept as-is

If they press Enter or type text:
- Use their custom comment

Store: file, line, body

### Step 5: Continue?

```
Inline comment added. Add another? (y/n)
>
```

If **y** → repeat from Step 1
If **n** → proceed to Step 6

### Step 6: Summary and review type

```
Review with 2 inline comments:
1. auth.py:78-82: "I'm curious about the token expiry validation here..."
2. api.py:134-156: "Have we considered parameterized queries to prevent SQL injection?"

Submit as: (a)pprove, (c)hange requests, or co(m)ment?
>
```

### Step 7: Submit via GitHub API

```bash
gh api repos/<org>/<repo>/pulls/<number>/reviews \
  --method POST \
  --input - <<'EOF'
{
  "body": "<review summary from Phase 4>",
  "event": "<APPROVE|REQUEST_CHANGES|COMMENT>",
  "comments": [
    {
      "path": "auth.py",
      "line": 82,
      "body": "I'm curious about the token expiry validation here..."
    },
    {
      "path": "api.py",
      "line": 156,
      "body": "Have we considered parameterized queries to prevent SQL injection?"
    }
  ]
}
EOF
```

**Mapping:**
- a → APPROVE
- c → REQUEST_CHANGES
- m → COMMENT

Success: "✅ Review posted with 2 inline comments"

---

## Edge Cases

**Large PR (>20 files):**
- Note in summary: "⚠️ Large PR - thorough review is challenging"
- Focus on highest-risk changes
- Suggest: "Consider breaking into smaller PRs for future changes"

**Junior author (check author experience):**
- Extra teaching focus
- More encouragement
- Explain patterns and practices
- Provide links to resources
- More praise for what's done well

**Hotfix/emergency PR:**
- Note: "⚠️ Hotfix - prioritizing critical issues only"
- Focus only on blocking bugs/security
- Note technical debt for follow-up
- Expedite review

**No issues found:**
- Still provide value:
  - Acknowledge what's well done (👍 section)
  - Ask clarifying questions if any (🤔)
  - Or: "LGTM - this looks solid. No issues found."

---

## Review Guidelines

**DO:**
- Show existing reviews to avoid duplication
- Use severity levels (🚫💡🤔✨👍) for clarity
- Include code snippets with file:line references
- Explain WHY, not just WHAT
- Ask questions when unsure
- Praise good patterns (👍)
- Provide AI-assisted comment suggestions
- Be specific and actionable
- Teach through socratic questions

**DON'T:**
- Dictate - the author owns this code
- Nitpick style unless it violates standards
- Point out issues in unchanged code
- Use dismissive language ("just", "obviously")
- Leave vague feedback
- Report theoretical issues (only real problems)
- Duplicate what others already said clearly
- Overwhelm with too many comments (3-5 substantive)

---

## Comment Tone

**Questions over statements:**
- ✅ "Could we add validation here?"
- ❌ "You should add validation here"

**Explain impact:**
- ✅ "This might cause X because Y"
- ❌ "This is wrong"

**Collaborative exploration:**
- ✅ "I'm curious about...", "Have you considered..."
- ❌ "Just do X", "Obviously this should be Y"

**Teach, don't correct:**
- ✅ "Parameterized queries prevent SQL injection by separating data from commands"
- ❌ "Use parameterized queries"

---

## Completion

After posting review (via a/c/i actions):
- Show success message
- Done (no session state to clean up)
