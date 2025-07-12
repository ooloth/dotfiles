---
description: Systematic code refactoring with smart scope detection
allowed-tools: [Bash, Read, Edit, MultiEdit, Write, Glob, Grep]
---

You are now in refactoring mode. Focus on improving code design while keeping tests green.

**Target:** $ARGUMENTS

**SCOPE DETECTION:**

If no arguments provided:
- **On feature branch**: Automatically assess changes since branching from main
- **On main branch**: Ask user what they'd like refactored

If arguments provided:
- **File path**: Refactor specific file (e.g., "src/auth.js")
- **Module/area**: Refactor specific functionality (e.g., "authentication module")
- **Feature**: Refactor specific behavior (e.g., "payment processing")

**REFACTORING WORKFLOW:**

1. **Assess current code**:
   - Read and understand the code to be refactored
   - Identify the scope and boundaries
   - Run tests to ensure current behavior is captured

2. **Impact assessment**:
   - **High impact**: Code changed frequently + complex logic + poor readability
   - **Medium impact**: Code changed occasionally + moderate complexity  
   - **Low impact**: Stable code + simple logic + already readable

3. **Risk assessment**:
   - **Low risk**: Well-tested code, simple changes
   - **Medium risk**: Some test coverage, moderate changes
   - **High risk**: Poor test coverage, complex changes → require characterization tests first

4. **Code smell detection**:
   - **Long functions** (>20 lines) with multiple responsibilities
   - **Deep nesting** (>3 levels) indicating complex control flow
   - **Magic numbers/strings** without named constants
   - **Feature envy** (functions accessing other objects' data excessively)
   - **Shotgun surgery** (small changes requiring edits across many files)

5. **ROI prioritization**:
   - **Immediate value**: Code being actively modified
   - **Future value**: Code likely to change soon
   - **Team value**: Code that confuses multiple developers
   - **Maintenance value**: Code with frequent bugs

6. **Context integration**:
   - Review recent commits for patterns needing improvement
   - Check PR feedback for recurring refactoring suggestions
   - Identify code that slows down current feature development

7. **Make incremental changes**:
   - One improvement at a time
   - Run tests after each change
   - Commit improvements that provide value

**CODE QUALITY CHECKLIST:**

**Dead code elimination:**
- Functions or utilities that aren't called anywhere
- Parameters that aren't used by any callers
- Configuration options that aren't referenced
- Helper functions added "just in case" but never used
- **Rule**: Every function/utility must have demonstrated usage

**Duplication elimination:**
- Multiple functions defining the same variables
- Similar validation logic within functions
- Repeated string constants or configuration values
- Identical error handling patterns

**Design improvements:**
- Extract common functionality into utility libraries
- Consolidate configuration into modules
- Improve function naming and interface design
- Break large functions into smaller, focused ones

**Maintainability enhancements:**
- Centralize configuration (paths, constants, defaults)
- Improve error messages and user feedback
- Add helpful code comments for complex logic
- Simplify conditional logic and reduce nesting

**BRANCH ANALYSIS COMMANDS:**
- `git branch --show-current` - Check current branch
- `git diff main...HEAD --name-only` - See changed files since main
- `git diff main...HEAD` - See all changes since main
- `git log main..HEAD --oneline` - See commits since branching

**REFACTORING PRINCIPLES:**
- Keep tests green throughout the process
- Make small, focused improvements
- Focus on code you recently wrote or are actively changing
- Commit improvements incrementally with clear messages
- Test behavior remains unchanged after refactoring

Focus on the specific scope. Make incremental improvements. Keep tests green.