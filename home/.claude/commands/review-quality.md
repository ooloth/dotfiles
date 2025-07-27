---
description: Comprehensive quality audit combining code, security, and performance analysis
---

## Comprehensive Quality Audit Checklist

### Phase 1: Code Quality Foundation
- **Readability**: Clear naming, consistent style, logical organization
- **Maintainability**: Proper abstractions, DRY principles, minimal complexity
- **Error Handling**: Comprehensive coverage, graceful degradation
- **Documentation**: Inline comments, API docs, README updates

### Phase 2: Security Analysis (consult design-architect for deep analysis)
- **Input Validation**: All user inputs sanitized and validated
- **Authentication/Authorization**: Proper access controls
- **Data Protection**: Sensitive data encrypted, PII handled correctly
- **Common Vulnerabilities**: SQL injection, XSS, CSRF protection

### Phase 3: Performance Review (consult design-architect for architectural impact)
- **Algorithm Efficiency**: O(n) complexity analysis
- **Resource Usage**: Memory leaks, connection pooling
- **Database Queries**: N+1 problems, missing indexes
- **Caching Strategy**: Appropriate use of caching layers

### Phase 4: Test Coverage Analysis
- **Coverage Metrics**: Line, branch, and function coverage
- **Test Quality**: Meaningful assertions, edge cases
- **Test Performance**: Execution time, flaky tests
- **Missing Scenarios**: Error paths, boundary conditions

### Phase 5: Architectural Assessment
- **Design Patterns**: Appropriate use, over-engineering check
- **Scalability**: Handles growth, bottleneck identification
- **Dependencies**: Minimal, well-maintained, secure
- **Technical Debt**: Areas needing refactoring

### Specialist Consultation:
- **design-architect**: For security vulnerabilities, performance bottlenecks, architectural concerns
- **researcher**: For best practice verification, framework-specific patterns

Target: $ARGUMENTS