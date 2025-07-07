## Summary
Brief description of changes and why they're needed. Link to related issues if applicable.

Closes #(issue number)

## Changes
### New Functionality
- [ ] List new features or capabilities added
- [ ] Include file paths and function names for reviewers

### Integration
- [ ] Describe how new functionality integrates with existing code
- [ ] List modified files and their purpose

### Testing
- [ ] Describe test coverage added or modified
- [ ] Include test file paths and test case descriptions

### Code Quality Improvements
- [ ] List any refactoring or code improvements made
- [ ] Mention dead code removal or duplication elimination

### Documentation Updates
- [ ] List documentation files updated (README.md, CLAUDE.md, etc.)
- [ ] Mention any code comments or inline documentation added

### Off-Topic Changes (if any)
- [ ] Clearly separate any changes not directly related to the main PR purpose
- [ ] Provide context for why off-topic changes are included
- [ ] Example: "Claude development process improvements discovered during implementation"

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Code quality improvement (refactoring, dead code removal, etc.)
- [ ] Infrastructure/tooling improvement

## Test Coverage
- [ ] **All tests passing** - Verify with `./test/run-tests.zsh`
- [ ] New tests added for new functionality
- [ ] Existing tests still pass
- [ ] Integration tests included where applicable
- [ ] Edge cases covered in test suite

## Implementation Notes
- **Complete behavior bundle**: List what constitutes the complete behavior (utilities + tests + integration + usage)
- **Lines of code**: Approximate line count for context (~X lines)
- **Dependencies**: Any new dependencies or external tool requirements
- **Breaking changes**: List any changes that might affect existing workflows

## Pre-Merge Checklist
### Code Quality
- [ ] **Dead code elimination** - No unused functions or utilities included
- [ ] **Code follows established patterns** - Consistent with existing codebase style
- [ ] **Functions have demonstrated usage** - All new utilities are actually used
- [ ] **Commit granularity** - Logical, atomic commits with clear messages
- [ ] **No unrelated changes bundled** - Each commit serves a single purpose

### Testing
- [ ] **All tests pass locally** - `./test/run-tests.zsh` succeeds
- [ ] **Tests cover behavioral outcomes** - Not just implementation details
- [ ] **Test environment isolation** - Tests don't interfere with each other
- [ ] **Integration testing** - New functionality works with existing code

### Documentation
- [ ] **README.md updated** if installation/usage instructions changed
- [ ] **Code comments added** for complex logic
- [ ] **CLAUDE.md updated** if development patterns changed
- [ ] **Inline documentation** updated for modified functions

### CI/CD
- [ ] **CI checks pass** (when available)
- [ ] **No failing tests** in any environment
- [ ] **Branch is up to date** with main/target branch

### Review Readiness
- [ ] **PR description complete** - All sections filled out accurately
- [ ] **Self-review completed** - Code reviewed before requesting team review
- [ ] **Clear scope** - PR purpose and boundaries are well-defined
- [ ] **Reviewable size** - PR is focused and not too large for effective review

## Next Steps
- [ ] List any follow-up work or related PRs planned
- [ ] Mention any dependencies or blockers for future development
- [ ] Note any areas that might need additional attention in future iterations

---

**Additional Context**: Add any other context, screenshots, or information that would help reviewers understand and test the changes.

**Testing Instructions**: Provide specific steps for reviewers to test the functionality manually if applicable.