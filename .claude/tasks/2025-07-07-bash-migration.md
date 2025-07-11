# Bash Migration Epic

## Current Status (July 7, 2025)

**Task**: Migrate dotfiles installation infrastructure from custom zsh to industry-standard bash + shellcheck + bats
**Approach**: Enhanced 3-phase migration with setup.bash at the center for maximum tooling leverage
**Current**: Phase 1 enhanced scope - migrating setup.bash + core scripts + shared utilities

## Migration Strategy

### Phase 1: Setup + Core Infrastructure Migration (IN PROGRESS - Enhanced Scope)
**Goal**: Migrate setup.bash + core installation scripts + shared utilities for maximum tooling leverage

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

### Phase 2: Remaining Script Migration (Pending)
**Goal**: Migrate remaining installation scripts using established three-tier architecture

**Enhanced Priority Order**:
1. `setup.bash` - Main entry point with shared utility integration
2. `bin/lib/*.bash` - All utility libraries (machine-detection, prerequisite-validation, etc.)
3. `bin/install/homebrew.bash` - Final core script with shared utility extraction
4. Remaining scripts based on dependency analysis

**Three-Tier Architecture Pattern**:
1. **Core utilities (bash)**: `lib/*-utils.bash` - Pure logic, shellcheck compliant, fully tested
2. **Setup orchestration (bash)**: `setup.bash` - Calls utilities directly, professional tooling
3. **Interactive tools (zsh)**: `bin/update/*.zsh` - Thin wrappers, rich user experience

### Phase 3: Framework Cleanup and CI Enhancement (Pending)
**Goal**: Remove zsh test framework, update CI, and add shellcheck validation

**Tasks**:
- Update `.github/workflows/test-dotfiles.yml` to use bats instead of custom runner
- Add shellcheck step to CI pipeline for all bash scripts
- Configure shellcheck with appropriate exclusions (e.g., SC1091 for sourced files)
- Remove `test/run-tests.zsh` and custom zsh test utilities
- Update documentation to reflect bash-first approach
- Archive zsh test framework with migration notes

## Key Decisions Made

### Enhanced Architecture: Bash Infrastructure + Zsh User Experience
- **setup.bash**: Main entry point for maximum tooling leverage (shellcheck + bats)
- **lib/*-utils.bash**: Shared logic for code reuse between setup and updates
- **bin/update/*.zsh**: Interactive tools stay zsh for rich user shell experience
- **Reasoning**: Best of both worlds - professional development tools + user-friendly shell

### Bash + Shellcheck + Bats Stack for Infrastructure
- **Bash**: Universal, better CI support, consistent behavior, fresh machine friendly
- **Shellcheck**: Industry-standard linting, catches common errors, enforces best practices
- **Bats**: Mature testing framework, wide adoption, good GitHub Actions support

### Migration Approach: Setup.bash as Forcing Function
- **Rejected**: Incremental script-by-script migration without setup changes
- **Chosen**: setup.bash + core scripts + shared utilities as complete system
- **Reasoning**: Forces architectural consistency, enables code sharing, validates entire approach

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

### Shellcheck CI Configuration (Planned)
```yaml
# .github/workflows/shellcheck.yml
- name: Run ShellCheck
  uses: ludeeus/action-shellcheck@master
  with:
    scandir: '.'
    check_together: 'yes'
    ignore_paths: 'test/install/lib'  # Mock scripts
    severity: 'error'
    format: 'gcc'
```

**Shellcheck Standards**:
- All bash scripts must pass with zero warnings
- Use inline directives sparingly (prefer fixing the issue)
- Document any necessary exclusions (e.g., SC1091 for sourced files)
- Configure `.shellcheckrc` for project-wide settings if needed

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
- **Future**: Add shellcheck validation step for all bash scripts
- **Benefits**: 
  - Standard test output format, better integration with GitHub UI
  - Automated code quality enforcement via shellcheck
  - Catch shell scripting issues before merge

### Code Sharing Strategy
- **Extract to utilities**: Shared logic between setup and update scripts goes to `lib/*-utils.bash`
- **Three-tier reuse**: Core utilities (bash) + Setup orchestration (bash) + Interactive wrappers (zsh)
- **Maximum leverage**: Shellcheck + bats testing for all shared business logic
- **Example**: `lib/homebrew-utils.bash` used by both `setup.bash` and `bin/update/homebrew.zsh`

### Enhanced Migration Boundary
- **→ Bash infrastructure**: setup.bash, bin/install/*.bash, bin/lib/*.bash, shared utilities
- **← Zsh user experience**: config/zsh/*, bin/update/*.zsh, interactive aliases/functions
- **Benefit**: Maximum tooling leverage while preserving rich user shell experience

## Discovered Issues

### Critical Setup.zsh Bug (FIXED)
**Issue**: `setup.zsh` references `$DOTFILES` files via `source` commands before the dotfiles repository is cloned
**Impact**: Setup process fails on fresh installations
**Priority**: High - affects core functionality  
**Status**: PR #14 MERGED - fixed dependency ordering issue
**Solution**: Basic git check before clone, comprehensive utilities after clone (line 128+)

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
- Zero shellcheck warnings allowed (enforced in CI)
- Feature parity verification required
- Complete behavior bundle (no dead code)
- CI shellcheck validation must pass

## Current Work

### 🔄 PR #15: SSH Installation Testing (Draft)
- **Files Created**:
  - `lib/ssh-utils.bash` - SSH utilities with comprehensive functionality
  - `bin/install/ssh.bash` - Bash replacement for ssh.zsh
  - `test/install/test-ssh-utils.bats` - 14 utility function tests
  - `test/install/test-ssh-installation.bats` - 7 integration tests
- **Test Results**: All 21 tests passing, shellcheck compliance verified
- **Improvements**: Better macOS version detection for ssh-add keychain flag
- **Status**: Draft PR created, ready for review

## Next Steps (Enhanced Architecture)

1. **Complete PR #15**: SSH installation migration (current work)
2. **Extract shared utilities**: Create `lib/homebrew-utils.bash`, `lib/npm-utils.bash`, `lib/symlink-utils.bash`
3. **Migrate utility libraries**: `bin/lib/*.zsh` → `bin/lib/*.bash` (machine-detection, prerequisite-validation, etc.)
4. **Create setup.bash**: Main entry point using shared utilities and bash install scripts
5. **Update bin/update/*.zsh**: Thin wrappers around shared utilities for interactive use
6. **Migrate CI workflow**: Custom zsh runner → bats with comprehensive test coverage
7. **Architectural validation**: Verify three-tier system meets all requirements

## Enhanced Development Workflow

**Setup.bash-centered approach**:
1. **Extract shared logic** to utilities during each script migration
2. **Validate with setup.bash** to ensure utilities work in real setup context
3. **Update interactive tools** to use shared utilities (preserving user experience)
4. **Test comprehensively** with bats for all bash infrastructure
5. **Maintain compatibility** with existing user shell workflows

---

*This epic represents a significant infrastructure improvement that will provide better development tools, more reliable testing, and easier maintenance for the dotfiles project. The enhanced three-tier architecture maximizes shellcheck + bats leverage while preserving rich zsh user experience.*
