---
description: Improve code architecture and design patterns
---

## Systematic Architecture Improvement Process

### Phase 0: Planning & Strategy Assessment
**Before making architectural changes, confirm approach:**
- **Have you planned your refactoring strategy?** If not, start here:
  1. **Quick assessment** - Is this a small refactor or major restructuring?
  2. **Consider alternatives**:
     - Incremental refactoring (safe, gradual improvement)
     - Big bang refactor (complete restructure - high risk)
     - Extract service/module (isolate problematic code)
     - Rewrite component (when refactoring is harder than starting over)
     - Leave as-is (if working and low-maintenance)
  3. **Choose optimal approach** based on:
     - Risk tolerance (production impact)
     - Time available 
     - Team familiarity with the code
     - Existing test coverage
  4. **Plan migration strategy** - How to deploy changes safely?

### Phase 1: Structural Analysis
1. **Identify design issues** - Tight coupling, complex dependencies, unclear boundaries
2. **Assess complexity** - Cyclomatic complexity, deep nesting, large functions/classes
3. **Find architectural smells** - God objects, feature envy, inappropriate intimacy
4. **Evaluate patterns** - Overused, misused, or missing design patterns

### Phase 2: Design Strategy
1. **Extract methods/classes** - Break down monolithic components
2. **Improve module boundaries** - Clear separation of concerns
3. **Reduce coupling** - Dependency injection, interfaces, event-driven patterns
4. **Apply appropriate patterns** - Factory, Strategy, Observer, etc. (where they add clarity)
5. **Establish clear abstractions** - Hide implementation details, expose clean interfaces

### Phase 3: Structural Refactoring
- **Single Responsibility Principle** - Each class/function has one reason to change
- **Open/Closed Principle** - Open for extension, closed for modification
- **Dependency Inversion** - Depend on abstractions, not concretions
- **Interface Segregation** - Many specific interfaces > one general interface
- **Composition over inheritance** - Favor object composition

### Phase 4: Architecture Validation
- **Design review** - Ensure patterns solve actual problems
- **Testability** - Can components be easily unit tested?
- **Maintainability** - Clear structure for future changes
- **Scalability** - Design handles growth gracefully

### When to consult specialists:
- **design-architect**: Complex architectural decisions, system-wide patterns
- **researcher**: Best practices for specific frameworks/languages

### Common Architectural Improvements:
- Extract service classes from controllers
- Implement repository pattern for data access
- Add command/query separation (CQRS)
- Create facade for complex subsystems
- Use adapter pattern for external integrations
- Implement observer pattern for loose coupling

Architecture target: $ARGUMENTS