---
description: Comprehensive code quality audit across all dimensions
---

## Comprehensive Code Quality Audit

### Phase 0: Scope Assessment
**Determine audit scope:**
- **Specific file/function**: Focus on targeted analysis
- **Module/package**: Broader architectural review
- **Full codebase**: Comprehensive quality assessment
- **Recent changes**: Focus on modified code

### Phase 1: Multi-Dimensional Analysis

#### 🐛 **Bug Detection & Correctness**
- Logic errors and edge cases
- Null pointer/undefined reference risks
- Off-by-one errors, boundary conditions
- Race conditions and concurrency issues
- Error handling gaps and exception safety

#### 🏗️ **Architecture & Design**
- Code organization and structure
- Design patterns (appropriate usage)
- Coupling and cohesion
- Single responsibility principle
- Separation of concerns

#### 🔒 **Security Review**
- Input validation and sanitization
- Authentication/authorization checks
- Sensitive data exposure
- SQL injection, XSS, CSRF vulnerabilities
- Dependency security (known vulnerabilities)

#### ⚡ **Performance Analysis**
- Algorithm efficiency (O(n) complexity)
- Database queries (N+1 problems, indexing)
- Memory usage patterns
- Caching opportunities
- Resource management

#### 🧪 **Testing Assessment**
- Test coverage completeness
- Test quality and assertions
- Missing edge cases
- Test maintainability
- Integration vs unit test balance

#### 📖 **Readability & Maintainability**
- Naming conventions and clarity
- Code comments and documentation
- Complex expressions and logic
- Code duplication (DRY violations)
- Magic numbers and constants

#### 🆕 **Modern Language Usage**
- Current language features and idioms
- Deprecated patterns and functions
- Type safety improvements
- Framework best practices
- Linting and formatting compliance

### Phase 2: Prioritized Observations Menu

**Output format:**
```
🚨 CRITICAL (Fix Immediately)
- [Issue description] in [location] because [impact]

⚠️ HIGH PRIORITY (Address Soon)  
- [Issue description] in [location] because [impact]

💡 MEDIUM PRIORITY (Consider Improving)
- [Issue description] in [location] because [benefit]

✨ LOW PRIORITY (Nice to Have)
- [Issue description] in [location] because [enhancement]

🎉 POSITIVE OBSERVATIONS
- [Good pattern] in [location] - keep this approach
```

### Phase 3: Specialist Consultation (when beneficial)
- **design-architect**: Complex architectural issues, system-wide security
- **researcher**: Modern best practices, framework-specific patterns

### Phase 4: Actionable Recommendations
**For each observation, provide:**
- Clear description of the issue
- Why it matters (impact/risk)
- Specific fix recommendation
- Priority level for addressing

Code audit target: $ARGUMENTS