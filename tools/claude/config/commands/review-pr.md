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

### Phase 0: Team Context (Optional)

**Ask user:**
```
Quick context (or press Enter for defaults):
1. Time-sensitive? (release/hotfix/normal) [default: normal]
2. Author experience? (junior/mid/senior/unknown) [default: unknown]
>
```

**If user presses Enter without input:** Use defaults (normal, unknown)

**How this affects review:**
- **Hotfix**: Focus only on blocking bugs/security, note other issues for follow-up
- **Junior author**: More teaching, more encouragement, explain patterns
- **Senior author**: Trust their judgment more, ask "why" questions to learn from them

Proceed to Phase 1.

---

### Phase 1: Fetch PR Data

Extract org/repo/number from input and fetch **in parallel**:

```bash
gh pr view <number> --repo <org>/<repo> --json title,body,commits,files,url,headRefOid,reviews,comments,statusCheckRollup,author &
gh pr diff <number> --repo <org>/<repo> &
wait
```

**For recursionpharma repos:** Check `statusCheckRollup` for failures. If CI is failing, note it for Phase 3.

**Output:** "✓ Fetched PR data"

---

### Phase 2: Understand Author's Intent FIRST

**Before diving into code, read and understand:**

1. **PR title and description/body**
   - What problem is this solving?
   - What approach did author choose?
   - What tradeoffs or design choices did they explain?
   - Are there stated areas of uncertainty or "I'm not sure about X"?
   - Is this part of a series? (Part 1 of 3, Depends on #123, WIP, Draft)
   - Are there explicitly incomplete parts? (Tests coming in part 2, etc.)

2. **Respect stated decisions**
   - Don't question choices author already explained
   - Focus on unstated assumptions or unexplained areas
   - If you disagree with explained choice, ask "why" to understand reasoning

**Output:** "✓ Read PR description - [1-sentence summary of author's goal]"

---

### Phase 3: Analyze Existing Context

**Parse the PR data to understand:**

1. Who is the author?
2. What files are changed?
3. **What have others already said?** (critical - avoid duplication)
4. **What did author respond?** (critical - don't repeat resolved concerns)

**Skip non-reviewable files:**
- package-lock.json, *.lock, yarn.lock, Gemfile.lock
- Generated code (*.generated.*, *_pb2.py, etc.)
- Test snapshots (__snapshots__/*)
- Vendored dependencies (vendor/, node_modules/ if committed)
- Binary files
- **Formatting-only changes** (detect hunks that are whitespace/style only)

**Process existing review context:**

Parse reviews and comments from the JSON:
- Extract all review comments (inline and general)
- Extract all conversation comments
- Group by file and line number
- **Parse review → author response → fix sequence**
  - Did author respond to concern?
  - Was it addressed in later commit?
  - Is discussion resolved or still active?
- **Learn team standards from existing reviews:**
  - What do other reviewers mark as blocking vs non-blocking?
  - What issues do they consistently flag?
  - What do they let through?
- Note who said what and when

**Output:** "✓ Analyzed existing context - [X] prior reviews, [Y] active discussions"

---

### Phase 4: Read Full Files for Context

**IMPORTANT:** Don't review diffs in isolation. Read full changed files to understand context.

For each changed file (excluding skipped files):
```bash
gh pr view <number> --repo <org>/<repo> --json files
# Extract file paths
# For each file:
curl -L "https://raw.githubusercontent.com/<org>/<repo>/<headRefOid>/<file_path>"
```

**Why:** Diff shows changes but not surrounding code. Need full context to:
- Verify suggestions match existing patterns in this file
- Ensure "weird code" isn't actually consistent with file conventions
- Understand if change fits file's architecture

**Show progress for visibility:**
```
Analyzing changed files:
✓ auth.py (1/8)
✓ api.py (2/8)
✓ utils.py (3/8)
...
```

**Output after all files:** "✓ Read all changed files ([X] files)"

---

### Phase 5: Understand Existing Patterns

**REQUIRED before suggesting alternatives:**

Read **2-3 similar/related unchanged files** to understand how this codebase solves similar problems:

1. Find similar patterns: How does existing code handle authentication/caching/error handling/etc?
2. What utilities exist? (Don't suggest reinventing the wheel)
3. What conventions are used? (naming, architecture, testing patterns)

**Must output what you found:**
```
✓ Reviewed existing patterns:
- Error handling: utils/errors.py uses custom exception classes with error codes
- Testing: All API functions have corresponding test_*.py with parametrized tests
- Authentication: Existing pattern in auth/session.py uses JWT with Redis cache
```

**Use this to ground all suggestions in actual codebase patterns.**

**Output:** "✓ Analyzed existing codebase patterns ([X] similar files reviewed)"

---

### Phase 6: Deep Review

Review the code changes across all dimensions:

**Correctness:**
- Completeness, edge cases
- Consistency with existing patterns (from Phase 5)
- Bugs, error handling
- Security (actual violations only)
- Compatibility, breaking changes
- Testing coverage - **specify exact test cases needed**:
  - Not: "Add tests"
  - Better: "Add tests for: expired token, malformed token, missing token, token with wrong signature"

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

**Show progress:**
```
Deep review in progress:
✓ Correctness (1/4)
✓ Performance (2/4)
✓ Maintainability (3/4)
✓ What's good (4/4)
```

**Output:** "✓ Completed review analysis"

---

### Phase 7: Present Review

**Format:**

```markdown
## PR Review: [org/repo#number] "[title]"

### 📝 Existing Review Context

[If there are existing reviews/comments, show them with resolution status:]

@alice reviewed 2 days ago (CHANGES_REQUESTED):
- auth.py:45-52: "Should log errors instead of swallowing"
  → Author responded: "Good catch, will fix"
  → ✅ Fixed in commit abc1234
- db.py:103: "Use parameterized queries"
  → Author responded: "Actually this is internal-only, safe from injection"
  → ❌ Not addressed, still a concern

@bob commented 1 day ago:
- General: "Looks good overall, just those two issues to address"

💬 Active discussions (1):
- auth.py:45-52: Error handling approach (resolved)

🎯 Team standards learned:
- This team blocks on: security issues, missing tests, breaking changes
- This team allows as follow-up: performance optimizations, refactoring

[If no existing reviews: "No prior reviews"]

---

### Summary

[1-2 sentence description of what this PR does]

**Author's stated goal:** [from PR description]

[If part of series: "⚠️ Part 1 of 3 - tests coming in part 2"]

[If applicable: "⚠️ Large PR (X files) - thorough review is challenging. Consider breaking into smaller PRs for future changes."]

[If hotfix: "⚠️ Hotfix - prioritizing critical issues only"]

---

### 👍 What's Good

- **Thorough test coverage** in `test_auth.py:120-156` - covers happy path and 4 edge cases (expired, malformed, missing, wrong signature)
- **Clear naming** in `auth.py:67-89` - `rotate_refresh_token` is self-documenting
- **Good error handling** in `api.py:234` - provides helpful error messages for debugging
- **Follows existing pattern** in `utils/cache.py` - consistent with how we cache user data elsewhere

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

# Test cases to add
test_refresh_with_expired_token()  # Should raise InvalidTokenError
test_refresh_with_valid_token()    # Should succeed
test_refresh_with_malformed_token() # Should raise validation error
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
Parameterized queries treat user input as data, not executable SQL commands. The DB driver escapes special characters.

# Test cases to add
test_batch_with_injection_attempt()  # user_id = "1; DROP TABLE users; --"
test_batch_with_special_chars()      # user_id = "'; SELECT * FROM passwords; --"
```

**Note:** This follows the existing pattern in `api/users.py:45-67` where we use parameterized queries for all user input.

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

**Alternative approach:** I see we use Redis for session caching in `auth/session.py:23-45`. Could we use the same approach here for consistency?

---

#### ✨ Nit/Optional (polish)

**Severity criteria:** Style, naming, minor improvements

**`models.py:89`**

**Optional:** Could rename `data` to `user_profile` for clarity

**Why:** More specific naming would make the code self-documenting. Existing code in `models/user.py` uses `user_profile` for similar data.

---

### Previously Identified (from existing reviews)

[If others already mentioned issues, acknowledge them with resolution status:]

- ✅ auth.py:45-52: Error handling (alice mentioned logging) - Fixed in commit abc1234
- ❌ db.py:103: SQL injection (alice mentioned parameterized queries) - Author says internal-only, but I still think we should fix (see my comment above)

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
   - Suggested fix: Check `is_token_valid(old_token)` before refresh
   - Test cases: expired token, malformed token, valid token
2. api.py:134-156 - Use parameterized queries (prevents SQL injection)
   - Suggested fix: Use `query("... WHERE id = ?", [user_id])`
   - Test cases: injection attempt, special characters

💡 **Consider for follow-up:**
- utils.py:45-52 - Shared cache solution for horizontal scaling (works fine now, becomes issue at multi-instance deployment)
- models.py:89 - Rename `data` to `user_profile` (minor clarity improvement, matches existing convention)

[Acknowledge constraints where applicable:]
"The in-memory cache works perfectly for current scale. When we hit multi-instance deployment, we can migrate to Redis (already using it for sessions)."

---

### 📍 Key Areas to Review

[List 3-5 most important file:line references for quick navigation:]

- auth.py:78-82 - Missing token expiry validation (🚫 Blocking, NEW)
- api.py:134-156 - SQL injection risk (💡 Should fix)
- utils.py:45-52 - Caching strategy question (🤔)

---

### 🎬 Actions

**o** - Open PR in browser
**i** - Add inline comments (AI-assisted, one at a time)
**b** - Bulk post all blocking/should-fix issues as inline comments
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

**b - Bulk post inline comments:**

### Step 1: Show what will be posted

```
Bulk post inline comments for:

🚫 Blocking issues:
1. auth.py:78-82 - Missing token expiry validation

💡 Should fix issues:
2. api.py:134-156 - SQL injection risk

This will create 2 inline comments with AI-generated suggestions.

Proceed? (y/n)
>
```

### Step 2: If yes, generate and submit

For each issue, generate contextual comment (same quality as interactive mode):

```bash
gh api repos/<org>/<repo>/pulls/<number>/reviews \
  --method POST \
  --input - <<'EOF'
{
  "body": "<review summary from Phase 7>",
  "event": "REQUEST_CHANGES",
  "comments": [
    {
      "path": "auth.py",
      "line": 82,
      "body": "I noticed we're generating a new token without validating the old one's expiry. If a user passes an already-expired token, the system still issues a new refresh token, allowing indefinite session extension. Example: user's token expires at noon, they can still refresh at 1pm.\n\nSuggested fix:\n```python\nif not is_token_valid(old_token):\n    raise InvalidTokenError(\"Cannot refresh expired token\")\nnew_token = generate_refresh_token(user)\n```\n\nThis enforces the token expiry policy and prevents security bypass.\n\nTest cases to add:\n- test_refresh_with_expired_token() - should raise InvalidTokenError\n- test_refresh_with_valid_token() - should succeed\n- test_refresh_with_malformed_token() - should raise validation error"
    },
    {
      "path": "api.py",
      "line": 156,
      "body": "I see we're using string interpolation for the SQL query. If item.user_id contains `'; DROP TABLE users; --'`, this would execute the DROP command.\n\nSuggested fix:\n```python\nresult = db.query(\"SELECT * FROM users WHERE id = ?\", [item.user_id])\n```\n\nParameterized queries treat user input as data, not executable SQL. The DB driver escapes special characters.\n\nThis follows the existing pattern in api/users.py:45-67.\n\nTest cases to add:\n- test_batch_with_injection_attempt() - user_id = \"1; DROP TABLE users; --\"\n- test_batch_with_special_chars() - user_id = \"'; SELECT * FROM passwords; --\""
    }
  ]
}
EOF
```

Success: "✅ Review posted with 2 inline comments (REQUEST CHANGES)"

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

1. "I noticed we're generating a new token without validating the old one's expiry. What happens if a user refreshes with an already-expired token? This could allow session extension beyond the intended timeout. Should we add an expiry check before generating the new token?

Suggested fix:
```python
if not is_token_valid(old_token):
    raise InvalidTokenError('Cannot refresh expired token')
new_token = generate_refresh_token(user)
```

Test cases to add:
- test_refresh_with_expired_token() - should raise InvalidTokenError
- test_refresh_with_valid_token() - should succeed"

2. "I'm wondering about the token refresh flow here. If old_token has expired, should we still issue a new one? I'm concerned this could bypass the expiry policy.

The impact: user's token expires at noon, they can still refresh at 1pm and continue indefinitely.

Could we validate that old_token is still valid before proceeding?

Test cases needed:
- Expired token scenario
- Malformed token scenario
- Valid token scenario"

3. "Quick security question: what prevents a user from continually refreshing an expired token? Without an expiry check here, it seems like tokens could be refreshed indefinitely.

Example attack: User's session expires, but they keep calling refresh_token() every hour to stay logged in forever.

Have you considered adding `is_token_valid(old_token)` validation before generating the new token?

Suggested tests:
- test_refresh_with_expired_token()
- test_refresh_with_valid_token()
- test_refresh_with_malformed_token()"

Select 1-3 to use/edit, or press Enter to write custom:
>
```

**How to generate suggestions:**

DON'T just use templates. Instead:
1. **Analyze the specific issue** - what's actually wrong?
2. **Describe concrete impact** - what breaks? Show example if helpful
3. **Ask genuine questions** - what's the intent? What are constraints?
4. **Suggest specific solution with code** - not vague, but actionable
5. **Explain why** - teach the reasoning
6. **Provide specific test cases** - exact scenarios to test

**Templates by issue type** (use as starting points, customize to actual code):

- **Error handling:** "I'm curious why [specific exception] is caught but not logged here. What happens when [specific scenario]? Could this make debugging harder in production? Suggested fix: [code]. Test: [specific case]"

- **Security:** "I noticed [specific vulnerability]. If a user [attack scenario], this could [impact]. Have we considered [specific mitigation]? Example: [concrete attack]. Fix: [code]. Tests: [cases]"

- **SQL injection:** "I see we're using string interpolation for the query. If user_id contains `'; DROP TABLE users; --'`, this would execute the DROP command. Could we use parameterized queries? Fix: [code]. Tests: [injection scenarios]"

- **Missing tests:** "How can we verify [specific behavior]? I'm thinking about edge cases like [example]. Should we add test coverage for: [list specific test cases]"

- **Performance:** "I'm noticing this loops through all items for each request. At 1000 items, that's O(n²). Have we measured the impact? Could we use [specific optimization]? Example: [concrete numbers]. Fix: [code]"

- **Code clarity:** "I'm finding the flow through these three functions a bit hard to follow. The data transforms from X → Y → Z but it's not clear why. Could we add comments or simplify? Suggestion: [specific refactor]"

- **Design:** "I see this duplicates logic from [other file]. Have you considered extracting to [specific utility]? Or is there a reason they need to stay separate? Note: We use similar pattern in [existing code]"

**Key: Make suggestions specific to THIS code, include code fixes and exact test cases.**

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
  "body": "<review summary from Phase 7>",
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
- Read PR description FIRST to understand author's intent and design choices
- Read full changed files for context, not just diffs
- Enforce reading 2-3 similar files to ground suggestions in existing patterns
- Show existing reviews with resolution status (what was addressed vs still open)
- Learn team standards from existing reviews (what they block on)
- Skip formatting-only changes and non-reviewable files
- Use severity levels (🚫💡🤔✨👍) with explicit criteria
- Include code snippets with file:line references
- Show before/after suggestions with code
- Provide specific test cases (exact scenarios to test)
- Explain concrete impact with examples ("If user passes X, then Y happens")
- Explain WHY, not just WHAT
- Ask questions when unsure
- Maintain at least 1:1 positive to negative ratio
- Provide AI-assisted comment suggestions with code + why + tests
- Be specific and actionable
- Teach through socratic questions
- Acknowledge constraints and "good enough for now"
- Distinguish "fix before merge" from "follow-up ticket"
- Fast-track good PRs: "LGTM - Ship it!"
- Show progress for visibility during long reviews

**DON'T:**
- Dictate - the author owns this code
- Question choices author already explained in PR description
- Nitpick style unless it violates team standards
- Point out issues in unchanged code
- Use dismissive language ("just", "obviously")
- Leave vague feedback
- Report theoretical issues (only real problems)
- Repeat concerns that were already addressed
- Duplicate what others already said clearly
- Overwhelm with too many comments (3-5 substantive max)
- Use generic template comments (customize to actual code)
- Review lock files, generated code, test snapshots, vendored dependencies, formatting-only changes
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

**Include specific test cases:**
- ✅ "Test cases: expired token, malformed token, valid token"
- ❌ "Add tests"

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

**Reference existing patterns:**
- ✅ "This follows the pattern in auth/session.py where we use Redis for caching"
- ❌ Suggest new patterns without checking what exists

---

## Completion

After posting review (via a/b/c/i actions):
- Show success message
- Done (no session state to clean up)
