---
description: Systematic bug investigation and resolution
---

## Systematic Debugging Process

### Phase 0: Planning & Strategy Assessment

**Before diving into debugging, confirm approach:**

- **Have you planned your debugging strategy?** If not, start here:
  1. **Quick assessment** - Is this a simple fix or complex investigation?
  2. **Consider alternatives**:
     - Direct fix (if cause is obvious)
     - Systematic debugging (for complex/mysterious issues)
     - Rollback/revert (if recent change caused it)
     - Ask for help (if completely unfamiliar domain)
  3. **Choose optimal approach** based on complexity and time constraints
  4. **Set time boundaries** - How long to investigate before seeking help?

### Phase 1: Systematic Investigation

1. **Understand expected behavior** - What should happen?
2. **Reproduce consistently** - Minimal steps to trigger issue
3. **Gather information** - Error messages, stack traces, environment
   - **For recursionpharma repos with CI failures**: Use the `inspect-codefresh-failure` skill to analyze Codefresh build logs and identify environment differences
4. **Form hypotheses** - Ranked list of potential causes
5. **Test systematically** - Verify/eliminate hypotheses methodically
6. **Implement solution** - Address root cause, not just symptoms

### Error Analysis Patterns:

- Parse error messages for key information
- Trace stack traces to exact failure points
- Distinguish symptoms from root causes
- Check environmental factors (versions, configs)
- For CI failures (recursionpharma): Use the `inspect-codefresh-failure` skill

Bug description: $ARGUMENTS

