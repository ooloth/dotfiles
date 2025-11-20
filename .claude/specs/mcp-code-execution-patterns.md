# MCP Code Execution Patterns - Implementation Plan

## Goal

Apply recommendations from Anthropic's "Code Execution with MCP" article to improve context efficiency, token usage, and code execution patterns in this dotfiles repository's Claude Code setup.

## Sources

1. https://www.anthropic.com/engineering/code-execution-with-mcp
2. https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices

## Key Insights from MCP Code Execution Article

1. **Context Efficiency**: Filter data in code before passing to model (98.7% token reduction possible)
2. **Security**: Implement deterministic security rules for data flow
3. **Architecture**: Use code execution to process heavy operations, return only summaries
4. **Caching**: Maintain intermediate results in execution environment
5. **Typed Interfaces**: Use typed interfaces for tool interactions

## Key Insights from Claude Docs Best Practices

### Conciseness
- Be extremely concise in documentation
- Challenge each piece of information: "Does Claude really need this explanation?"
- Assume Claude is already very intelligent
- Minimize token usage in context window

### Naming Conventions
- **Use gerund form** (verb + -ing): `fetching-prs`, `analyzing-spreadsheets`, `inspecting-failures`
- Avoid vague names like `helper` or `utils`

### Description Guidelines
- Write in third person
- Be specific about functionality
- Include key terms and usage contexts
- **Maximum 1024 characters**

### Progressive Disclosure
- **Keep main SKILL.md under 500 lines**
- Use reference files that Claude loads on-demand
- Organize content hierarchically
- Create clear navigation between files

### Workflow Patterns
Two recommended patterns:

**1. Checklist Workflow:**
```markdown
1. [ ] Step 1: Do X
2. [ ] Step 2: Validate X
3. [ ] Step 3: Do Y
```

**2. Conditional Workflows:**
```markdown
If X exists:
  - Do A
Else:
  - Do B
```

### Validation Strategy
- Use **"plan-validate-execute" pattern**
- Create intermediate output files
- Implement verbose validation scripts
- Make errors specific and actionable

### Anti-Patterns to Avoid
- ❌ Windows-style file paths
- ❌ Too many options (causes decision paralysis)
- ❌ Assuming package installations
- ❌ Time-sensitive information
- ❌ File references more than one level deep from SKILL.md

### Development Process
1. Complete task without Skill first
2. Identify reusable patterns
3. Create initial Skill
4. Test with different Claude models
5. Gather team feedback
6. Continuously iterate

## Current State

**Strengths:**
- Already using skill pattern with `fetching-github-prs-to-review` (exemplifies article's approach)
- Good security deny rules in `settings.json`
- Agent-based delegation for complex tasks

**Gaps:**
- Missing environment variable security rules ✅ Fixed
- No skill template to guide future skill creation ✅ Fixed (needs enhancement)
- CLAUDE.md emphasizes agents over skills for context management ✅ Fixed
- Some skills lack caching patterns
- Token-heavy commands could be converted to skills
- Skills not following gerund naming convention
- Template missing workflow patterns and anti-patterns
- Template missing plan-validate-execute pattern

## Implementation Themes

### Theme 1: Environment Variable Security Rules ✅
**Files**: `tools/claude/config/settings.json`

Add deterministic security rules to deny patterns that could leak secrets:
- `Bash(:*AWS_SECRET:*)`
- `Bash(:*GH_TOKEN:*)`
- `Bash(:*ANTHROPIC_API_KEY:*)`
- `Bash(export :*_TOKEN=:*)`
- `Bash(export :*_KEY=:*)`
- `Bash(export :*_SECRET=:*)`

### Theme 2: Skill Template ✅
**Files**: `tools/claude/config/skills/@template/`

Create a reference template showing best practices:
- SKILL.md with workflow patterns and structure
- Example Python script with:
  - Type hints
  - Data filtering before output
  - Caching patterns
  - Error handling
  - Comments explaining the pattern

### Theme 3: Context Management Strategy Update ✅
**Files**: `tools/claude/config/CLAUDE.md`

Update "Managing your context window" section to prioritize:
1. Skills (code-based processing) - first choice
2. Agents (complex exploration) - second choice
3. Direct tool usage - last resort

Add guidance on:
- When to create a skill vs use an agent
- Skill design principles (filter in code, cache results, return summaries)
- Type hints and error handling expectations

### Theme 4: Enhance Template with Claude Docs Best Practices
**Files**: `tools/claude/config/skills/@template/`

**4a. Update SKILL.md:**
- Add checklist workflow example
- Add conditional workflow example
- Document 500-line limit and progressive disclosure
- Add reference to plan-validate-execute pattern

**4b. Update README.md:**
- Add naming conventions (gerund form)
- Add description character limit (1024)
- Add anti-patterns section
- Add development process
- Add workflow pattern examples
- Document progressive disclosure guidance

**4c. Update example_skill.py:**
- Add plan-validate-execute pattern example
- Add validation function demonstrating the pattern
- Add comments explaining when to use each pattern

### Theme 5: Rename Skills to Follow Naming Convention
**Files**: `tools/claude/config/skills/*/`, various references

Rename skills to use gerund + noun form:
- `fetch-prs-to-review` → `fetching-github-prs-to-review`
- `inspect-codefresh-failure` → `inspecting-codefresh-failures`

Update all references:
- `tools/claude/config/CLAUDE.md`
- `.claude/specs/mcp-code-execution-patterns.md`
- Any command files that reference these skills
- Template README.md examples

### Theme 6: Enhanced Caching for Existing Skills
**Files**: `tools/claude/config/skills/*/`

Review and enhance caching in:
- `fetching-github-prs-to-review`: Already good, document as example
- `inspecting-codefresh-failures`: Add caching for build logs by build_id
- Future skills: Apply caching template

## Non-Goals

- Converting all commands to skills (some need Claude's reasoning)
- Removing agent delegation (still valuable for exploration)
- Over-engineering skills with unnecessary abstraction

## Success Criteria

- [x] Security rules prevent common secret exposure patterns
- [x] Template exists showing MCP best practices (needs enhancement)
- [x] CLAUDE.md clearly guides skill-first approach
- [ ] Template incorporates all Claude docs best practices
- [ ] Template demonstrates workflow patterns (checklist, conditional)
- [ ] Template demonstrates plan-validate-execute pattern
- [ ] Template documents anti-patterns and naming conventions
- [ ] All skills follow gerund naming convention
- [ ] Existing skills demonstrate caching patterns
- [ ] Pattern is reusable for future skill creation

## Hand-off Notes

Each theme should be implemented and committed separately to maintain atomic commits.
