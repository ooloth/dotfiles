# Always Use Test-Driven Development

For all work that involves modifying code:

1. Write a list of the test scenarios you want to cover
2. Turn exactly one item on the list into an actual, concrete, runnable test
3. Change the code to make the test (& all previous tests) pass (adding items to the list as you discover them)
4. Optionally refactor to improve the implementation design
5. Pause to let me review and commit
6. Until the list is empty, go back to #2

## Rules - CRITICAL

**BLOCKING RULE: ALWAYS run tests in the FOREGROUND.**

- ❌ NEVER use `Task` tool for tests
- ❌ NEVER use `run_in_background=true` on Bash for tests
- ❌ NEVER delegate test execution to any agent
- ✅ ALWAYS use direct `Bash` tool calls in foreground

**Why:** Background execution is 10-50x slower due to polling overhead. Direct foreground execution gives immediate results.

**Examples:**

```bash
# ✅ CORRECT - Direct foreground
python -m pytest tests/path/to/test.py::test_name -xvs

# ❌ WRONG - Background task (never use run_in_background parameter for pytest)
```
