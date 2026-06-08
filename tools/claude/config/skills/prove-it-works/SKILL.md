---
name: prove-it-works
description: Write a step-by-step QA plan that both you and humans can execute to capture evidence that a code path works as intended. TRIGGER when a user asks you to write a QA plan or prove a change works.
argument-hint: 'Scope to check (e.g. "current branch", "the /login endpoint", "the retry logic in src/queue.ts") [optional]'
---

Scope: $ARGUMENTS (if empty, assume the current change).

What did you assume would work but haven't actually watched run? Don't answer with a plan —
go run it. Use the real entry point, real inputs, real output. Not tests. The thing itself.

What do you observe? What's still unobserved? What would a skeptic demand you prove that you
can't yet show evidence for?

Once you've run it: could any of the gaps you found be closed with a permanent integration test?

---

❌ "The tests pass and the logic looks correct."
✅ "I ran `npm run dev`, navigated to /settings, toggled the feature, and saw the config update in the network response."
