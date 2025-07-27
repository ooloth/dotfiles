---
description: Improve type safety and type annotations
---

## Systematic Type Safety Improvement Process

### Phase 1: Type Analysis
1. **Identify missing types** - Functions without return types, untyped parameters
2. **Find type errors** - Runtime type mismatches, unsafe casts
3. **Assess type coverage** - What percentage of code is properly typed?
4. **Review type complexity** - Overly complex types, any types, type assertions

### Phase 2: Type Annotation Strategy
1. **Start with function signatures** - Parameters and return types first
2. **Add variable types** - Where type inference isn't clear
3. **Type complex data structures** - Objects, arrays, nested structures
4. **Define custom types** - Interfaces, unions, type aliases for domain concepts
5. **Generic types** - Where code works with multiple types

### Phase 3: Type Safety Improvements
- **Eliminate any types** - Replace with specific types
- **Reduce type assertions** - Use type guards instead
- **Strengthen null safety** - Handle undefined/null cases explicitly
- **Union types** - Model states that can be multiple types
- **Discriminated unions** - Type-safe state machines
- **Branded types** - Prevent mixing similar primitives (UserId vs OrderId)

### Phase 4: Type Validation
- **Type checking** - Run type checker and fix all errors
- **Runtime validation** - Add runtime checks for external data
- **Type tests** - Verify complex types work as expected
- **Documentation** - Comment complex types and their purpose

### Language-Specific Approaches:

**TypeScript:**
- Use strict mode configuration
- Prefer interfaces over types for objects
- Use const assertions for immutable data
- Implement type guards for runtime validation

**Python:**
- Use mypy for static type checking
- Add type hints to all public functions
- Use generics for reusable components
- Implement runtime validation with pydantic

**Rust:**
- Use Result<T, E> instead of panicking
- Prefer owned types over references when unclear
- Use newtypes for domain concepts
- Implement Display and Debug traits

**Go:**
- Use interfaces for behavior contracts
- Prefer composition over embedding
- Use type assertions carefully
- Implement error handling consistently

### Common Type Improvements:
- Function signatures with clear parameter and return types
- Domain-specific types instead of primitives
- Null safety with Optional/Result types
- Type guards for runtime validation
- Generic functions for reusable logic

Type improvement target: $ARGUMENTS