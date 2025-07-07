# Bash Migration Epic

## Current Status (July 7, 2025)

**Task**: Migrate dotfiles installation scripts from custom zsh test framework to industry-standard bash + shellcheck + bats
**Approach**: Complete 3-phase migration for better tooling, maintainability, and reliability
**Current**: Phase 1 complete (PR #13 merged), now addressing critical setup.zsh bug (PR #14)

## Migration Strategy

### Phase 1: Demonstrate Complete Migration Pattern (COMPLETED)
**Goal**: Create one complete bash + bats example to establish the migration pattern

#### ✅ PR #13: GitHub Installation Testing (MERGED)
- **Files Created**:
  - `lib/github-utils.bash` - GitHub SSH utilities (shellcheck clean)
  - `bin/install/github.bash` - Bash replacement for github.zsh
  - `test/install/test-github-utils.bats` - 14 utility function tests
  - `test/install/test-github-installation.bats` - 6 integration tests
  - `experiment/bash-testing/` - Comparison docs and examples
- **Test Results**: All 20 tests passing, shellcheck compliance verified
- **Benefits Demonstrated**: Better error catching, industry-standard tooling, cleaner syntax
- **Status**: MERGED - established complete migration pattern with 20 passing tests

### Phase 2: Systematic Script Migration (Pending)
**Goal**: Migrate remaining installation scripts one-by-one using established pattern

**Priority Order**:
1. `bin/install/ssh.bash` - Critical dependency for GitHub operations
2. `bin/install/homebrew.bash` - Foundation for all other tools
3. `bin/install/node.bash` - Programming language setup
4. Remaining scripts based on dependency analysis

**Pattern per Script**:
- Create `lib/{script}-utils.bash` with shellcheck compliance
- Create comprehensive bats test suite
- Migrate main installation script to bash
- Verify feature parity with original zsh version
- Update integration points

### Phase 3: Framework Cleanup (Pending)
**Goal**: Remove zsh test framework and update CI

**Tasks**:
- Update `.github/workflows/test-dotfiles.yml` to use bats instead of custom runner
- Remove `test/run-tests.zsh` and custom zsh test utilities
- Update documentation to reflect bash-first approach
- Archive zsh test framework with migration notes

## Key Decisions Made

### Bash + Shellcheck + Bats Stack
- **Bash**: Universal, better CI support, consistent behavior
- **Shellcheck**: Industry-standard linting, catches common errors
- **Bats**: Mature testing framework, wide adoption, good GitHub Actions support

### Migration Approach: Complete Examples First
- **Rejected**: Hybrid approach (keep scripts in zsh, tests in bash)
- **Chosen**: Full migration with complete working examples
- **Reasoning**: Cleaner long-term solution, better tooling ecosystem

### Test Coverage Standards
- **Utilities**: Comprehensive unit tests for all functions
- **Integration**: End-to-end workflow testing with mocking
- **Compliance**: All bash scripts must pass shellcheck with zero warnings
- **Behavioral Focus**: Test what code does, not implementation details

## Technical Patterns Established

### File Structure Pattern
```
lib/{component}-utils.bash          # Utility functions
bin/install/{component}.bash        # Installation script  
test/install/test-{component}-utils.bats     # Unit tests
test/install/test-{component}-installation.bats  # Integration tests
```

### Bash Script Standards
- `#!/usr/bin/env bash` shebang
- `set -euo pipefail` strict mode
- Shellcheck compliance (zero warnings)
- Function documentation with usage examples
- Proper error handling and user feedback

### Test Standards
- Comprehensive test coverage (both success and failure paths)
- Environment isolation with setup/teardown
- Mocking of external dependencies
- Clear test descriptions and assertions
- Integration tests that verify complete workflows

## Integration Points

### CI/CD Pipeline
- GitHub Actions currently uses custom zsh test runner
- **Future**: Migrate to bats with better reporting and parallelization
- **Benefit**: Standard test output format, better integration with GitHub UI

### Existing Zsh Infrastructure
- **Preserve**: Current zsh configuration and shell setup (user-facing)
- **Migrate**: Only installation and testing scripts (development tooling)
- **Benefit**: Users keep familiar shell while development gets better tools

## Discovered Issues

### Critical Setup.zsh Bug (FIXED)
**Issue**: `setup.zsh` references `$DOTFILES` files via `source` commands before the dotfiles repository is cloned
**Impact**: Setup process fails on fresh installations
**Priority**: High - affects core functionality  
**Status**: PR #14 created with fix - moved all sourcing after git clone (line 128+)
**Solution**: Basic git check before clone, comprehensive utilities after clone

### Dead Code Prevention
**Pattern**: Every function/utility must have demonstrated usage in the same PR
**Enforcement**: CLAUDE.md updated with strict guidelines
**Benefit**: Prevents speculative code that becomes maintenance burden

## Success Metrics

### Phase 1 (Current)
- ✅ 20 comprehensive tests passing
- ✅ Zero shellcheck warnings
- ✅ Feature parity with original zsh scripts
- ✅ Complete behavior bundle (utilities + tests + integration + usage)
- 🔄 User review and approval

### Phase 2 (Future)
- All installation scripts migrated to bash
- Comprehensive bats test coverage
- CI pipeline updated to use bats
- Documentation updated

### Phase 3 (Future)
- Custom zsh test framework removed
- Clean codebase with single testing approach
- Improved developer experience with standard tooling

## Development Workflow

### Current Process
1. Create utilities with shellcheck compliance
2. Write comprehensive bats tests (unit + integration)
3. Implement installation script in bash
4. Verify feature parity and test coverage
5. Create draft PR for review iteration
6. Update task documentation with progress

### Quality Gates
- All bats tests must pass
- Zero shellcheck warnings allowed
- Feature parity verification required
- Complete behavior bundle (no dead code)

## Next Steps After PR #13 Review

1. **Address Review Feedback**: Incorporate any requested changes
2. **Fix Critical Setup Bug**: Resolve $DOTFILES dependency issue  
3. **Continue Phase 1**: SSH installation script migration
4. **Plan Phase 2**: Define systematic migration order
5. **Update CI**: Begin migration to bats-based testing

---

*This epic represents a significant infrastructure improvement that will provide better development tools, more reliable testing, and easier maintenance for the dotfiles project.*