---
name: draft-til
description: Drafts a TIL blog post in the user's voice and creates it in Notion with Status="Claude Draft". Contains voice guide for matching the user's writing style. Use when user approves a TIL topic and wants a draft created.
---

# Draft TIL Skill

Creates a TIL blog post draft in Notion following the user's voice and style.

## Voice Guide

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

4. **Playful asides and humor** (1-2 per post, don't overdo it)
   - "Illegal! Now you're a criminal"
   - "Oh noooo..."
   - "Really, really no vertical margins"

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

## Notion Property Mappings

**Database**: Writing
**Data Source ID**: `c296db5b-d2f1-44d4-abc6-f9a05736b143`

When creating a TIL page, set these properties:

| Property | Value |
|----------|-------|
| Title | The TIL title (direct, specific) |
| Status | "Claude Draft" |
| Type | "how-to" |
| Destination | ["blog"] |
| Description | One-line summary of what reader will learn |
| Slug | URL-friendly version of title (lowercase, hyphens) |
| Topics | Link to relevant Topics if obvious match exists |
| Research | Link to source Research items if applicable |
| Questions | Link to source Questions if applicable |

---

## Creation Process

1. **Determine format** - Ultra-short or standard based on topic complexity
2. **Write title** - Direct, specific, states what reader will learn
3. **Write content** - Follow voice guide above
4. **Generate slug** - Lowercase title with hyphens, no special chars
5. **Write description** - One sentence summarizing the takeaway
6. **Create page** using `mcp__notion__notion-create-pages`:

```json
{
  "parent": {
    "data_source_id": "c296db5b-d2f1-44d4-abc6-f9a05736b143"
  },
  "pages": [{
    "properties": {
      "Title": "Your TIL Title Here",
      "Status": "Claude Draft",
      "Type": "how-to",
      "Destination": "[\"blog\"]",
      "Description": "One-line summary here",
      "Slug": "your-til-title-here"
    },
    "content": "Your markdown content here following voice guide"
  }]
}
```

---

## Example: Ultra-Short TIL

**Title**: Tmux's version command is -V

**Content**:
```markdown
Most CLI tools use `--version` or `-v` to show their version.

Tmux uses `-V` (capital V):

```bash
tmux -V
# tmux 3.4
```

The lowercase `-v` enables verbose mode instead.
```

**Properties**:
- Status: Claude Draft
- Type: how-to
- Destination: ["blog"]
- Description: Check tmux version with -V (capital V), not -v
- Slug: tmux-version

---

## Example: Standard TIL

**Title**: The filter(Boolean) trick

**Content**:
```markdown
Here's a trick I often find helpful.

## Bad array. Very, very bad.

You have an array of whatever:

```javascript
const array = [{ stuff }, { moreStuff }, ...]
```

But hiding in that array are some unusable `null` or `undefined` values:

```javascript
const array = [{ good }, null, { great }, undefined]
```

## Looping over null data

If you try to perform actions on every item in the array, you'll run into errors:

```javascript
const newArray = array.map(item => {
  const assumption = item.thing
})

// 🚨 Error: Cannot read property "thing" of undefined.
```

Illegal! Now you're a criminal.

## The truth and only the truth

Here's my favourite way to quickly remove all empty items:

```javascript
const truthyArray = array.filter(Boolean)
// [{ good }, { great }]
```

The `filter(Boolean)` step passes each item to `Boolean()`, which coerces it to `true` or `false`. If truthy, we keep it.

Hope that helps!
```

**Properties**:
- Status: Claude Draft
- Type: how-to
- Destination: ["blog"]
- Description: How to remove empty values from an array
- Slug: javascript-filter-boolean

---

## Safety Rules

1. **Always use Status="Claude Draft"** - Never use any other status
2. **Never edit existing pages** - Only create new ones
3. **Show draft to user first** - Display content before creating page
4. **Link sources via relations** - Don't modify source pages

---

## After Creation

After successfully creating the page:

1. Display the page URL
2. Show a summary of properties set
3. Remind user they can review and edit in Notion
4. Offer to draft another or return to suggestions
