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

### Phase 0: Team Context

Before reviewing, gather context to calibrate your review:

**Ask user:**
```
Quick context:
1. Time-sensitive? (release/hotfix/normal)
2. Author experience? (junior/mid/senior/unknown)
>
```

**How this affects review:**
- **Hotfix**: Focus only on blocking bugs/security, note other issues for follow-up
- **Junior author**: More teaching, more encouragement, explain patterns
- **Senior author**: Trust their judgment more, ask "why" questions to learn from them

Wait for user response before proceeding.

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
2. Who is the author?
3. What files are changed?
4. **What have others already said?** (critical - avoid duplication)

**Skip non-reviewable files:**
- package-lock.json, *.lock, yarn.lock, Gemfile.lock
- Generated code (*.generated.*, *_pb2.py, etc.)
- Test snapshots (__snapshots__/*)
- Vendored dependencies (vendor/, node_modules/ if committed)
- Binary files

**Process existing review context:**

Parse reviews and comments from the JSON:
- Extract all review comments (inline and general)
- Extract all conversation comments
- Group by file and line number
- Note resolved vs unresolved discussions
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

**Volume control:**
- Focus on **3-5 most impactful issues**
- If there are 10+ issues, group related ones or suggest "broader refactor needed"
- Don't overwhelm with every minor issue

**Balanced feedback ratio:**
- Aim for **at least 1:1 positive to negative comments**
- For every issue raised, find something to praise
- Makes reviews collaborative, not adversarial

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
- auth.py:45-52: Error handling approach (2 comments, unresolved)
- db.py:103: SQL injection fix (1 comment, resolved)

[If no existing reviews: "No prior reviews"]

---

### Summary

[1-2 sentence description of what this PR does]

[If applicable: "⚠️ Large PR (X files) - thorough review is challenging. Consider breaking into smaller PRs for future changes."]

[If hotfix: "⚠️ Hotfix - prioritizing critical issues only"]

---

### 👍 What's Good

- **Thorough test coverage** in `test_auth.py:120-156` - covers happy path and 4 edge cases
- **Clear naming** in `auth.py:67-89` - `rotate_refresh_token` is self-documenting
- **Good error handling** in `api.py:234` - provides helpful error messages for debugging

---

### Issues Found

#### 🚫 Blocking (must fix before merge)

**Severity criteria:** Bug that breaks prod, security hole, data loss, breaks existing behavior

**`auth.py:78-82`** [NEW - not mentioned in existing reviews]

```python
# auth.py:78-82
new_token = generate_refresh_token(user)
# ⚠️ No check if old token has expired
```

**Issue:** Missing token expiry validation

**Impact:** If a user passes an already-expired token, the system still issues a new refresh token. This allows indefinite session extension even after tokens expire. Example: user's token expires at noon, they can still refresh at 1pm.

**Suggested fix:**
```python
# Before
new_token = generate_refresh_token(user)

# After
if not is_token_valid(old_token):
    raise InvalidTokenError("Cannot refresh expired token")
new_token = generate_refresh_token(user)

# Why
This enforces the token expiry policy and prevents security bypass
```

---

#### 💡 Should Fix (important quality issues)

**Severity criteria:** Missing tests, unclear code, tech debt that will bite us soon

**`api.py:134-156`**

```python
# api.py:134-156
def process_batch(items):
    for item in items:
        result = db.query(f"SELECT * FROM users WHERE id = {item.user_id}")
# ⚠️ SQL injection risk
```

**Issue:** SQL injection vulnerability

**Impact:** If `item.user_id` comes from untrusted input, attacker could inject SQL. Example: if user_id is `"1; DROP TABLE users; --"`, this executes the DROP command.

**Suggested fix:**
```python
# Before
result = db.query(f"SELECT * FROM users WHERE id = {item.user_id}")

# After
result = db.query("SELECT * FROM users WHERE id = ?", [item.user_id])

# Why
Parameterized queries treat user input as data, not executable SQL commands
```

---

#### 🤔 Questions (clarify or suggest alternatives)

**Severity criteria:** Clarify intent, suggest alternative approaches

**`utils.py:45-52`**

```python
# utils.py:45-52
cache = {}  # In-memory cache

def get_user(user_id):
    if user_id in cache:
        return cache[user_id]
    user = db.fetch_user(user_id)
    cache[user_id] = user
    return user
```

**Question:** I'm curious about the caching strategy here. If we deploy multiple server instances, each will have its own in-memory cache. This could lead to stale data issues. Have you considered Redis or another shared cache?

**Context:** This works fine for now with a single server. If we scale horizontally in the future, we'd need shared cache. Not blocking, but worth considering for follow-up.

---

#### ✨ Nit/Optional (polish)

**Severity criteria:** Style, naming, minor improvements

**`models.py:89`**

**Optional:** Could rename `data` to `user_profile` for clarity

**Why:** More specific naming would make the code self-documenting

---

### Previously Identified (from existing reviews)

[If others already mentioned issues, acknowledge them here to avoid duplication:]

- auth.py:45-52: Error handling (alice mentioned logging) - ✅ agree with alice's feedback
- db.py:103: SQL injection (alice mentioned parameterized queries) - ✅ this has been resolved in latest commit

---

### CI Failure Analysis (if applicable)

[Output from inspecting-codefresh-failures skill]

---

### Recommendation

**[APPROVE / REQUEST CHANGES / COMMENT]**

**Rationale:** [Why - what needs addressing or why it's good to merge]

Example: "Request changes - the token expiry bypass (🚫) is a security issue that should be fixed before merge. The SQL injection issue (💡) should also be addressed. Caching question (🤔) can be a follow-up."

---

### Summary for Author

[Fast-track for good PRs: If zero blocking issues, lead with this:]
✅ **LGTM - Ship it!** No blocking issues found. Optional improvements below.

[For PRs needing changes:]

🔧 **Please address before merge:**
1. auth.py:78-82 - Add token expiry validation (prevents security bypass)
2. api.py:134-156 - Use parameterized queries (prevents SQL injection)

💡 **Consider for follow-up:**
- utils.py:45-52 - Shared cache solution for horizontal scaling (works fine now)
- models.py:89 - Rename `data` to `user_profile` (minor clarity improvement)

[Acknowledge constraints where applicable:]
"The in-memory cache works perfectly for current scale. When we hit multi-instance deployment, we can migrate to Redis."

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

Show code snippet and suggest **contextual, specific** comments based on actual analysis:

```
Code at auth.py:78-82:

    new_token = generate_refresh_token(user)
    # No check if old token has expired

💡 Suggested comments (or write your own):

1. "I noticed we're generating a new token without validating the old one's expiry. What happens if a user refreshes with an already-expired token? This could allow session extension beyond the intended timeout. Should we add an expiry check before generating the new token?"

2. "I'm wondering about the token refresh flow here. If old_token has expired, should we still issue a new one? I'm concerned this could bypass the expiry policy. Could we validate that old_token is still valid before proceeding?"

3. "Quick security question: what prevents a user from continually refreshing an expired token? Without an expiry check here, it seems like tokens could be refreshed indefinitely. Have you considered adding validation before generating the new token?"

Select 1-3 to use/edit, or press Enter to write custom:
>
```

**How to generate suggestions:**

DON'T just use templates. Instead:
1. **Analyze the specific issue** - what's actually wrong?
2. **Describe concrete impact** - what breaks? Show example if helpful
3. **Ask genuine questions** - what's the intent? What are constraints?
4. **Suggest specific solution** - not vague, but actionable
5. **Explain why** - teach the reasoning

**Templates by issue type** (use as starting points, customize to actual code):

- **Error handling:** "I'm curious why [specific exception] is caught but not logged here. What happens when [specific scenario]? Could this make debugging harder in production?"

- **Security:** "I noticed [specific vulnerability]. If a user [attack scenario], this could [impact]. Have we considered [specific mitigation]?"

- **SQL injection:** "I see we're using string interpolation for the query. If user_id contains `'; DROP TABLE users; --'`, what would happen? Could we use parameterized queries here?"

- **Missing tests:** "How can we verify [specific behavior]? I'm thinking about edge cases like [example]. Should we add test coverage for these scenarios?"

- **Performance:** "I'm noticing this loops through all items for each request. At 1000 items, that's O(n²). Have we measured the impact? Could we use [specific optimization]?"

- **Code clarity:** "I'm finding the flow through these three functions a bit hard to follow. The data transforms from X → Y → Z but it's not clear why. Could we add comments or simplify the pipeline?"

- **Design:** "I see this duplicates logic from [other file]. Have you considered extracting to [specific utility]? Or is there a reason they need to stay separate?"

**Key: Make suggestions specific to THIS code, not generic advice.**

### Step 4: User responds

If they select 1-3:
- Show that suggestion pre-filled
- They can edit or accept as-is

If they press Enter or type text:
- Use their custom comment

Store: file, line, body

**Important: Line number accuracy**
- Use the ending line number from the range for `line` field
- Example: For range 78-82, use `"line": 82`
- The `path` should be relative to repo root (not full path)

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
1. auth.py:78-82: "I noticed we're generating a new token without validating..."
2. api.py:134-156: "I see we're using string interpolation for the query..."

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
      "body": "I noticed we're generating a new token without validating..."
    },
    {
      "path": "api.py",
      "line": 156,
      "body": "I see we're using string interpolation for the query..."
    }
  ]
}
EOF
```

**Mapping:**
- a → APPROVE
- c → REQUEST_CHANGES
- m → COMMENT

**Error handling:**
If gh api fails:
- Show error message
- Suggest: "You can post these comments manually in the browser (action 'o')"
- List the comments that would have been posted

Success: "✅ Review posted with 2 inline comments"

---

## Severity Criteria (Explicit Examples)

**🚫 Blocking (must fix before merge):**
- Bug that breaks production: "Function returns None when it should return list, will crash caller"
- Security hole: "SQL injection allows arbitrary code execution"
- Data loss: "Delete operation has no confirmation, user could lose all data"
- Breaks existing behavior: "Changes API response format, will break all clients"
- Breaking changes without migration: "Renames database column without migration script"

**💡 Should Fix (important quality issues):**
- Missing tests: "New function has no test coverage, could break silently"
- Unclear code: "This 50-line function does 5 things, hard to understand"
- Tech debt that will bite us: "This N+1 query works now but will timeout at 1000 users"
- Inconsistent patterns: "Uses fetch() everywhere else but axios here, creates confusion"

**🤔 Question (clarify or suggest alternatives):**
- Clarify intent: "What's the reasoning behind caching at this layer vs the DB layer?"
- Suggest alternatives: "Have you considered using existing utility X instead of reimplementing?"
- Understand constraints: "Is there a reason we can't use the standard library for this?"

**✨ Nit/Optional (polish):**
- Style: "Could format this with Prettier" (only if team uses Prettier)
- Naming: "Consider renaming `data` to `userProfile`"
- Minor improvements: "Could extract this magic number to a constant"

**👍 Praise (no threshold - praise liberally):**
- Good design: "Smart use of caching here to avoid repeated DB hits"
- Clever solution: "Nice! Using Set instead of Array makes the lookup O(1)"
- Thorough testing: "Great test coverage - you covered all 4 edge cases"
- Clear code: "This function is very readable, clear separation of concerns"

---

## Edge Cases

**Large PR (>20 files):**
- Note in summary: "⚠️ Large PR (X files) - thorough review is challenging"
- Focus on highest-risk changes
- Suggest: "Consider breaking into smaller PRs for future changes"

**Junior author (from Phase 0):**
- Extra teaching focus
- More encouragement
- Explain patterns and practices
- Provide links to resources
- More praise for what's done well
- Frame as learning opportunity: "Here's a pattern you might not have seen..."

**Senior author (from Phase 0):**
- Trust their judgment
- Ask "why" questions to learn from them
- Less explaining, more collaborative discussion
- Assume they know tradeoffs, ask about reasoning

**Hotfix/emergency PR (from Phase 0):**
- Note: "⚠️ Hotfix - prioritizing critical issues only"
- Focus only on blocking bugs/security
- Note technical debt for follow-up: "This works for the hotfix. Could we file a ticket to refactor X?"
- Expedite review - be concise

**No issues found:**
- Still provide value:
  - Acknowledge what's well done (👍 section)
  - Ask clarifying questions if curious (🤔)
  - Or: "✅ LGTM - this looks solid. No issues found. Well done on the test coverage!"

**Good-enough for now:**
- Acknowledge constraints: "This works perfectly for current scale. When we hit 10k users, we might need to optimize X."
- Don't require perfect when good is sufficient
- Suggest follow-up for future: "Could we create a ticket to investigate Y when we have more time?"

---

## Review Guidelines

**DO:**
- Show existing reviews to avoid duplication
- Use severity levels (🚫💡🤔✨👍) with explicit criteria
- Include code snippets with file:line references
- Show before/after suggestions with code
- Explain concrete impact with examples ("If user passes X, then Y happens")
- Explain WHY, not just WHAT
- Ask questions when unsure
- Maintain at least 1:1 positive to negative ratio
- Provide AI-assisted comment suggestions based on actual analysis
- Be specific and actionable
- Teach through socratic questions
- Acknowledge constraints and "good enough for now"
- Distinguish "fix before merge" from "follow-up ticket"
- Skip non-reviewable files (lock files, generated code, snapshots)
- Fast-track good PRs: "LGTM - Ship it!"

**DON'T:**
- Dictate - the author owns this code
- Nitpick style unless it violates team standards
- Point out issues in unchanged code
- Use dismissive language ("just", "obviously")
- Leave vague feedback
- Report theoretical issues (only real problems)
- Duplicate what others already said clearly
- Overwhelm with too many comments (3-5 substantive max)
- Use generic template comments (customize to actual code)
- Review lock files, generated code, test snapshots, vendored dependencies
- Make author feel bad - be encouraging

---

## Comment Tone

**Questions over statements:**
- ✅ "Could we add validation here?"
- ❌ "You should add validation here"

**Explain concrete impact:**
- ✅ "If user passes `'; DROP TABLE users; --'`, this executes it and deletes all data"
- ❌ "This has a SQL injection risk"

**Show before/after:**
- ✅ Include code suggestion with explanation
- ❌ Just point out what's wrong without solution

**Collaborative exploration:**
- ✅ "I'm curious about the reasoning here...", "Have you considered...", "What led to this approach?"
- ❌ "Just do X", "Obviously this should be Y"

**Teach, don't correct:**
- ✅ "Parameterized queries prevent SQL injection by treating user input as data, not executable commands. The DB driver escapes special characters."
- ❌ "Use parameterized queries"

**Acknowledge constraints:**
- ✅ "This works great for current scale. If we grow to 10k users, we might need caching."
- ❌ "This won't scale"

**Distinguish blocking from follow-up:**
- ✅ "This security issue should be fixed before merge. The performance optimization could be a follow-up ticket."
- ❌ Everything treated equally urgent

---

## Completion

After posting review (via a/c/i actions):
- Show success message
- Done (no session state to clean up)
