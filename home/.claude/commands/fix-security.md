---
description: Identify and resolve security vulnerabilities
---

## Systematic Security Remediation Process

### Phase 1: Vulnerability Assessment
1. **Identify the threat** - What's the attack vector?
2. **Assess impact** - What could an attacker do?
3. **Determine scope** - Where else might this exist?
4. **Set priority** - Critical, High, Medium, Low

### Phase 2: Common Vulnerability Checks
- **Input validation** - SQL injection, XSS, command injection
- **Authentication** - Weak auth, session management
- **Authorization** - Privilege escalation, IDOR
- **Data exposure** - Sensitive data in logs, responses
- **Cryptography** - Weak algorithms, poor key management
- **Dependencies** - Known vulnerable packages

### Phase 3: Fix Implementation
1. **Immediate mitigation** - Quick fix to block exploit
2. **Root cause fix** - Address underlying issue
3. **Defense in depth** - Add multiple layers
4. **Validate fix** - Test the remediation
5. **Check for similar issues** - Systematic review

### Phase 4: Prevention Strategy
- **Security headers** - CSP, HSTS, X-Frame-Options
- **Input sanitization** - Whitelist validation
- **Output encoding** - Context-aware escaping
- **Secure defaults** - Fail closed, least privilege
- **Security tests** - Add tests for the vulnerability
- **Code review** - Security-focused review process

### When to consult specialists:
- **design-architect**: For architectural security patterns, threat modeling
- **researcher**: For security best practices, OWASP guidelines

### Security Principles:
- Never trust user input
- Validate on the server side
- Use parameterized queries
- Implement proper access controls
- Keep dependencies updated
- Log security events (not sensitive data)
- Use established crypto libraries

Security issue: $ARGUMENTS