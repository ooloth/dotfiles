# Setup.zsh Improvement Plan

## Current Status (July 7, 2025)

**Task**: Improve reliability and testability of dotfiles setup process through TDD approach
**Total PRs Planned**: 10 PRs + 2 Infrastructure PRs
**Completed**: 8 PRs (including SSH Installation Testing)
**Current**: Working on Infrastructure Improvements (PR 8.1 & 8.2)

## Completed PRs

### ✅ PR 1: Testing Foundation (Merged)
- **Outcome**: Comprehensive test framework with mocking capabilities
- **Key Files**: `test/run-tests.zsh`, `test/lib/test-utils.zsh`, `test/lib/mock.zsh`
- **Note**: Test runner initially had issues running all files (fixed in PR 5)

### ✅ PR 2: Machine Detection (Merged) 
- **Outcome**: Dynamic hostname-based detection replacing hardcoded variables
- **Key Files**: `bin/lib/machine-detection.zsh`, `setup.zsh`
- **Variables Set**: `IS_AIR`, `IS_MINI`, `IS_WORK`, `MACHINE`
- **Pattern**: Air/Mini detected by hostname, default to work

### ✅ PR 3: Prerequisite Validation (Merged)
- **Outcome**: Comprehensive system checks before installation
- **Key Files**: `bin/lib/prerequisite-validation.zsh`
- **Validations**: Command Line Tools, network connectivity, macOS version, directory permissions
- **Integration**: Added to setup.zsh before installation begins

### ✅ PR 4: Dry-Run Mode (Merged)
- **Outcome**: Read-only validation mode with `--dry-run` flag
- **Key Files**: `bin/lib/dry-run-utils.zsh`
- **Functions**: `parse_dry_run_flags`, `dry_run_log`, `dry_run_execute`
- **Usage**: `zsh setup.zsh --dry-run` for safe preview

### ✅ PR 5: Error Handling Improvements (Merged)
- **Outcome**: Graceful error handling with retry mechanisms and user-friendly messages
- **Key Files**: `bin/lib/error-handling.zsh`
- **Functions**: `capture_error`, `retry_with_backoff`, `handle_error`
- **Integration**: Sourced in setup.zsh, replaces aggressive ERR trap approach

### ✅ PR 6: Installation Script Test Infrastructure (Merged)
- **Outcome**: Shared testing patterns and utilities for installation script testing
- **Key Files**: `test/install/lib/install-test-utils.zsh`, `test/install/lib/install-mocks.zsh`
- **Functions**: Installation-specific mocking, environment isolation, validation patterns
- **Integration**: Foundation for testing individual installation scripts

### ✅ PR 7: Homebrew Detection Testing (Merged)
- **Outcome**: Complete behavior bundle for Homebrew installation with detection utilities
- **Key Files**: `lib/homebrew-utils.zsh`, `test/install/test-homebrew-detection.zsh`
- **Functions**: `detect_homebrew()`, `homebrew_bundle_available()`, installation script integration
- **Pattern**: Complete behavior bundle (utilities + tests + integration + actual usage)

### ✅ PR 8: SSH Installation Testing (Merged)
- **Outcome**: Complete SSH key detection with testing and installation script integration
- **Key Files**: `lib/ssh-utils.zsh`, `test/install/test-ssh-detection.zsh`, updated `bin/install/ssh.zsh`
- **Functions**: `detect_ssh_keys()`, `ssh_key_pair_found()`, centralized path configuration
- **Improvements**: Post-implementation refactoring, dead code elimination, enhanced CLAUDE.md guidelines

## Infrastructure Improvements (In Progress)

### 🔄 PR 8.1: Pull Request Template (In Progress)
- **Goal**: Standardize PR descriptions using established patterns from successful PRs
- **Implementation**: `.github/PULL_REQUEST_TEMPLATE.md` with structured sections
- **Features**: Summary, changes, testing checkboxes, off-topic commit handling, quality gates
- **Benefits**: Consistent PR format, reduced cognitive load, captured process learnings

### ⏭️ PR 8.2: GitHub Actions CI (Planned)
- **Goal**: Automatic test execution on PRs with GitHub UI status indicators
- **Implementation**: `.github/workflows/test-dotfiles.yml` using existing test infrastructure
- **Features**: macOS runner, zsh shell, smart path triggering, existing test/run-tests.zsh integration
- **Benefits**: Visible test status in PR UI, early issue detection, no manual test verification

## Key Technical Decisions & Patterns

### Testing Philosophy
1. **Behavioral Testing**: Test what code does, not how (avoid function names, file contents)
2. **One Test Case Per Commit**: Each commit = one test case + implementation + docs
3. **File-Based Testing**: Use script files instead of functions for Zsh subshell compatibility
4. **Mock Everything**: Comprehensive mocking framework for external dependencies

### Development Patterns
1. **Infrastructure-First**: Create utilities before usage, mark with TODO comments
2. **TDD Approach**: Write failing test, implement feature, commit together
3. **Documentation Updates**: Include README/comment updates in same commit as feature
4. **PR Description Maintenance**: Update after each commit that changes scope

### Technical Gotchas
1. **Zsh Subshells**: Functions not visible across subshells, use file-based approaches
2. **Test Runner**: Remove `set -e` to prevent early exit, add DOTFILES env var
3. **Integration Tests**: Avoid running full setup.zsh, test utility sourcing instead
4. **Mocking**: Use file-based counters for stateful retry testing

## Current Infrastructure Available

### Utilities Ready for Use
- **`dry_run_execute`**: Wrap any command for conditional execution
- **`retry_with_backoff`**: Retry network operations with exponential backoff  
- **`handle_error`**: User-friendly error messages with suggestions
- **Machine detection variables**: `IS_AIR`, `IS_MINI`, `IS_WORK`, `MACHINE`
- **Prerequisite validation**: Comprehensive system checks

### Test Framework Capabilities
- Behavioral test assertions (`assert_equals`, `assert_true`, etc.)
- Command mocking with exit codes and output
- Environment isolation (`setup_test_environment`)
- File-based state management for complex scenarios

## Overview

This document outlines a comprehensive plan to improve the reliability and testability of the dotfiles setup process. The current setup.zsh script often requires debugging on new laptops due to various reliability issues. This plan implements a Test-Driven Development (TDD) approach with multiple small PRs to systematically address these issues.

## Goals

1. **Reduce setup failures** on new laptops
2. **Improve error handling** and recovery mechanisms
3. **Add comprehensive testing** to catch issues before deployment
4. **Implement dry-run mode** for safe testing
5. **Create modular, testable components**

## Key Issues Identified

1. **Machine Detection Logic** - Hardcoded machine type variables instead of dynamic detection
2. **Missing Dependency Checks** - No validation that prerequisites are met before proceeding
3. **Error Handling** - ERR trap is too aggressive and doesn't allow for graceful recovery
4. **Missing Command Line Tools Check** - The Xcode CLI tools check is commented out
5. **PATH Issues** - Scripts assume tools are in PATH before they're properly installed
6. **GitHub SSH Connection** - Commented out verification in github.zsh
7. **Directory Assumptions** - Scripts assume certain directories exist without validation
8. **Race Conditions** - Background sudo keep-alive process can interfere with other operations

## Implementation Strategy

### Branching Strategy
- All PRs branch from `main` (not cascading)
- Sequential implementation: create one PR at a time
- Wait for review/approval before proceeding to next PR
- Each PR incorporates feedback from previous ones

### Testing Framework
- **Dry-Run Mode**: Safe testing that makes no system modifications
- **Unit Tests**: Pure validation tests with no side effects
- **Mocking**: Mock external dependencies (brew, git, ssh-keygen, etc.)
- **GitHub Actions**: Smart workflow that only runs when setup-related files change

## Pull Request Breakdown

### PR 1: Testing Foundation
**Branch**: `feature/testing-foundation`
**Goal**: Establish testing infrastructure before any changes

**Changes**:
- Create `test/` directory structure
- Add basic test runner script (`test/run-tests.zsh`)
- Create test utilities and mocking framework
- Add assertion functions for test validation
- Create first failing test for machine detection
- Document testing conventions and patterns

**Files**:
- `test/run-tests.zsh` - Main test runner
- `test/lib/test-utils.zsh` - Test utilities and assertions
- `test/lib/mock.zsh` - Mocking framework for external commands
- `test/setup/test-machine-detection.zsh` - First test case
- `test/README.md` - Testing documentation

### PR 2: Machine Detection (TDD)
**Branch**: `feature/machine-detection`
**Goal**: Replace hardcoded machine variables with dynamic detection

**Tests First**:
- Test hostname-based detection for Air/Mini/Work
- Test environment variable overrides
- Test fallback behavior for unknown hostnames
- Test machine-specific configuration loading

**Implementation**:
- Remove hardcoded `IS_AIR`, `IS_MINI`, `IS_WORK` variables
- Add dynamic machine detection function
- Update setup.zsh to use dynamic detection
- Ensure all installation scripts use the new detection

**Files**:
- `test/setup/test-machine-detection.zsh` - Comprehensive tests
- `setup.zsh` - Updated machine detection
- `bin/install/*.zsh` - Updated to use dynamic detection

### PR 3: Prerequisite Validation (TDD)
**Branch**: `feature/prerequisite-validation`
**Goal**: Add comprehensive system checks before installation

**Tests First**:
- Test Command Line Tools detection
- Test network connectivity validation
- Test required directory existence
- Test permission checks
- Test macOS version compatibility

**Implementation**:
- Uncomment and improve Xcode CLI tools check
- Add network connectivity validation
- Add permission validation for required directories
- Add macOS version compatibility checks
- Implement graceful failure modes

**Files**:
- `test/setup/test-prerequisites.zsh` - Prerequisite tests
- `bin/install/prerequisites.zsh` - New prerequisite validation script
- `setup.zsh` - Updated to run prerequisite checks

### PR 4: Dry-Run Mode (TDD)
**Branch**: `feature/dry-run-mode`
**Goal**: Add safe testing mode that makes no system modifications

**Tests First**:
- Test dry-run flag parsing
- Test that no system modifications occur in dry-run mode
- Test logging and validation output
- Test all conditional logic paths

**Implementation**:
- Add `--dry-run` flag to setup.zsh
- Implement read-only validation and logging
- Add dry-run support to all installation scripts
- Ensure comprehensive coverage of all operations

**Files**:
- `test/setup/test-dry-run.zsh` - Dry-run tests
- `setup.zsh` - Updated with dry-run flag
- `bin/install/*.zsh` - Updated with dry-run support
- `config/zsh/utils.zsh` - Add dry-run utility functions

### PR 5: Error Handling Improvements (TDD)
**Branch**: `feature/error-handling`
**Goal**: Replace aggressive error handling with selective recovery

**Tests First**:
- Test error scenarios and recovery mechanisms
- Test graceful failure modes
- Test rollback capabilities
- Test user-friendly error messages

**Implementation**:
- Replace aggressive ERR trap with selective error handling
- Add recovery mechanisms for common failures
- Implement rollback capabilities
- Add user-friendly error messages and suggestions

**Files**:
- `test/setup/test-error-handling.zsh` - Error handling tests
- `setup.zsh` - Updated error handling
- `bin/install/*.zsh` - Updated error handling
- `bin/lib/error-handling.zsh` - Error handling utilities

### PR 6: Installation Script Test Infrastructure
**Branch**: `feature/install-test-infrastructure`
**Goal**: Create shared testing patterns and utilities for installation script testing

**Tests First**:
- Test installation script test patterns and utilities
- Test command mocking for external dependencies
- Test environment isolation for script testing
- Test validation patterns for installation outcomes

**Implementation**:
- Create shared test utilities for installation script testing
- Implement installation-specific mocking patterns
- Add test patterns for validating installation outcomes
- Create reusable test environment setup for installation scripts

**Files**:
- `test/install/lib/install-test-utils.zsh` - Installation testing utilities
- `test/install/lib/install-mocks.zsh` - Installation-specific mocks
- `test/install/test-install-framework.zsh` - Test the testing framework itself

### PR 7: Homebrew Installation Testing
**Branch**: `feature/test-homebrew-install`
**Goal**: Add comprehensive tests for Homebrew installation script

**Tests First**:
- Test Homebrew installation detection and setup
- Test Brewfile processing and package installation
- Test machine-specific package handling
- Test error conditions and recovery

**Implementation**:
- Create comprehensive tests for bin/install/homebrew.zsh
- Mock brew commands and validate installation behavior
- Test different machine configurations (air/mini/work)
- Test error handling and recovery mechanisms

**Files**:
- `test/install/test-homebrew.zsh` - Homebrew installation tests

### PR 8: SSH Installation Testing  
**Branch**: `feature/test-ssh-install`
**Goal**: Add comprehensive tests for SSH setup and GitHub authentication

**Tests First**:
- Test SSH key generation and setup
- Test GitHub SSH connection verification
- Test SSH configuration file management
- Test error conditions and user guidance

**Implementation**:
- Create comprehensive tests for bin/install/ssh.zsh and bin/install/github.zsh
- Mock ssh-keygen, ssh, and GitHub API calls
- Test SSH key validation and GitHub authentication
- Test error handling and user guidance

**Files**:
- `test/install/test-ssh.zsh` - SSH installation tests

### PR 9: Node.js Installation Testing
**Branch**: `feature/test-nodejs-install`  
**Goal**: Add comprehensive tests for Node.js and package manager setup

**Tests First**:
- Test fnm (Node.js version manager) installation
- Test Node.js version installation and configuration
- Test npm/pnpm global package installation
- Test machine-specific Node.js configurations

**Implementation**:
- Create comprehensive tests for bin/install/node.zsh
- Mock fnm, node, npm, pnpm commands
- Test version management and global package installation
- Test error handling and recovery

**Files**:
- `test/install/test-nodejs.zsh` - Node.js installation tests

### PR 10: Additional Installation Script Testing
**Branch**: `feature/test-remaining-installs`
**Goal**: Add tests for remaining installation scripts (shell configuration and system settings)

**Tests First**:
- Test shell configuration setup (zsh.zsh)
- Test system settings configuration (settings.zsh)
- Test additional installation scripts as needed
- Test error conditions and validation

**Implementation**:
- Create tests for bin/install/zsh.zsh (shell configuration)
- Create tests for bin/install/settings.zsh (macOS system preferences)
- Test remaining installation scripts (tmux.zsh, neovim.zsh, etc.)
- Test error conditions and validation
- Ensure comprehensive coverage of all installation steps

**Files**:
- `test/install/test-zsh.zsh` - Shell configuration tests
- `test/install/test-settings.zsh` - System settings tests  
- `test/install/test-tmux.zsh` - Tmux setup tests
- `test/install/test-neovim.zsh` - Neovim setup tests

**Note**: Symlink management is handled by `bin/update/symlinks.zsh` and would be tested separately if needed.

### Future PRs (After Installation Testing Complete)

Additional improvements to be implemented in subsequent PRs:

- **Dependency Validation**: Ensure tools are available before attempting to use them
- **GitHub SSH Verification**: Fix and improve SSH connection verification  
- **Progress Indicators**: Add better user feedback and progress reporting
- **GitHub Actions Workflow**: Add automated testing with smart triggering

## Testing Strategy

### Dry-Run Mode
- **Purpose**: Safe testing that makes no system modifications
- **Usage**: `./setup.zsh --dry-run`
- **Output**: Logs all operations without executing them
- **Validation**: Tests all conditional logic paths

### Unit Tests
- **Purpose**: Test individual components in isolation
- **Location**: `test/` directory
- **Approach**: Pure validation tests with no side effects
- **Mocking**: Mock external dependencies to avoid system changes

### Integration Tests
- **Purpose**: Test complete setup process
- **Platform**: GitHub Actions with fresh macOS runners
- **Triggering**: Only runs when setup-related files change
- **Coverage**: End-to-end validation of entire setup process

### Smart CI Triggering
The GitHub Actions workflow only runs when these files change:
- `setup.zsh`
- `bin/install/**`
- `bin/update/**`
- `macos/Brewfile`
- `config/**`
- `.github/workflows/test-setup.yml`

This prevents unnecessary CI runs for documentation changes or other non-setup modifications.

## Success Criteria

1. **Reduced setup failures** - Setup works reliably on fresh macOS installations
2. **Comprehensive testing** - All components have test coverage
3. **Safe testing** - Dry-run mode allows safe validation
4. **Better error handling** - Graceful failure and recovery mechanisms
5. **Automated validation** - GitHub Actions catches issues before deployment
6. **Maintainable code** - Modular, well-tested components

## Getting Started

1. **Run existing tests**: `./test/run-tests.zsh`
2. **Test dry-run mode**: `./setup.zsh --dry-run`
3. **Validate setup**: `./test/ci/validate-setup.zsh`
4. **Check CI status**: Monitor GitHub Actions for automated testing

## Future Enhancements

- Add support for other macOS versions
- Implement configuration profiles for different use cases
- Add telemetry for setup success/failure rates
- Create interactive setup mode with user choices
- Add support for partial installations and updates

---

*This plan implements a systematic approach to improving setup reliability through comprehensive testing and gradual implementation. Each PR builds upon the previous ones while maintaining the ability to test and validate changes safely.*