# Documentation

## Scope

Documentation includes code comments, docs files, diagrams, and any other text or visuals that explain the system — not just source code files.

## Ideal state

### Code comments

- Comment the "why" generously for future maintainers — hidden constraints, subtle invariants, workarounds for specific bugs, behaviour that would surprise a reader
- Minimize comments that paraphrase the "what" — achieve that goal instead by making the code itself more explicit and self-documenting

## Common failure modes

- Comments that describe what the code does rather than why (the code already says what)
- Stale comments that no longer match the code they annotate
- Missing "why" explanations for non-obvious decisions, constraints, or workarounds
- Inconsistent documentation patterns across the codebase — note what convention might be worth defining
