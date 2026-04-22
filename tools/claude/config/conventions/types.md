# Types

## Ideal state

- Prefer domain-specific types over primitive types — they produce safer and more expressively self-documented code
- Use types to enforce invariants and make invalid states unrepresentable
- Function signatures should be as expressive as the domain they model

## Common failure modes

- Missing type annotations
- Overly broad types (`Any`, untyped dicts) that provide no safety or documentation value
- Primitive types (`str`, `int`, `bool`) used where a domain-specific type would express intent more clearly
- Types that allow invalid states to be represented (e.g. mutually exclusive boolean flags instead of a union)
