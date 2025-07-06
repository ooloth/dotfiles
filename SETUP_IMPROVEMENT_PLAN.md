# Setup.zsh Improvement Plan

## Progress Tracker

### Completed PRs
- ✅ **PR 1: Testing Foundation** - Test framework and utilities established
- ✅ **PR 2: Machine Detection (TDD)** - Dynamic hostname-based detection implemented
- ✅ **PR 3: Prerequisite Validation (TDD)** - Comprehensive system checks added
- ✅ **PR 4: Dry-Run Mode (TDD)** - Read-only validation mode implemented

### Key Learnings & Decisions
1. **Test Behavior, Not Implementation** - Focus on what code does, not how (avoid testing function names, file contents)
2. **One Test Per Commit** - Each commit contains exactly one test and its implementation together
3. **Infrastructure-First PRs** - Add TODO comments and usage previews when creating utilities before they're used
4. **Documentation in Same Commit** - Update README.md, code comments, etc. in the same commit as the feature
5. **Maintain PR Descriptions** - Update after each commit that changes scope

### Implementation Notes for Future PRs
- The `dry_run_execute` function is ready to wrap all installation commands
- Machine detection sets `IS_AIR`, `IS_MINI`, `IS_WORK` and `MACHINE` variables
- Prerequisite validation runs before any installation begins
- Test framework supports mocking, environment isolation, and behavioral testing

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

### PR 6: Individual Script Testing
**Branch**: `feature/script-testing`
**Goal**: Add comprehensive unit tests for each installation script

**Tests First**:
- Test each installation script in isolation
- Mock external dependencies (brew, git, ssh-keygen)
- Test different machine states and configurations
- Test error conditions and edge cases

**Implementation**:
- Create test files for each installation script
- Implement mocking for external commands
- Add validation for script outputs and side effects
- Ensure comprehensive test coverage

**Files**:
- `test/install/test-ssh.zsh` - SSH installation tests
- `test/install/test-homebrew.zsh` - Homebrew installation tests
- `test/install/test-symlinks.zsh` - Symlink tests
- `test/install/test-*.zsh` - Tests for all installation scripts

### PR 7: Dependency Validation (TDD)
**Branch**: `feature/dependency-validation`
**Goal**: Ensure tools are available before attempting to use them

**Tests First**:
- Test command availability checks
- Test PATH validation
- Test dependency resolution order
- Test tool version compatibility

**Implementation**:
- Add dependency validation before tool usage
- Implement PATH validation and correction
- Add tool version compatibility checks
- Ensure proper dependency resolution order

**Files**:
- `test/setup/test-dependencies.zsh` - Dependency tests
- `bin/lib/dependency-validation.zsh` - Dependency utilities
- `bin/install/*.zsh` - Updated with dependency checks

### PR 8: GitHub SSH Verification Fix (TDD)
**Branch**: `feature/ssh-verification`
**Goal**: Fix and improve SSH connection verification

**Tests First**:
- Test SSH connection verification
- Test retry logic and timeout handling
- Test error messages and user guidance
- Test SSH key setup validation

**Implementation**:
- Uncomment and improve SSH connection test in github.zsh
- Add retry logic with exponential backoff
- Add better error messages and user guidance
- Implement SSH key validation

**Files**:
- `test/install/test-github-ssh.zsh` - SSH verification tests
- `bin/install/github.zsh` - Updated SSH verification
- `bin/install/ssh.zsh` - Updated SSH key generation

### PR 9: Progress Indicators
**Branch**: `feature/progress-indicators`
**Goal**: Add better user feedback and progress reporting

**Tests First**:
- Test progress reporting functionality
- Test step-by-step progress tracking
- Test time estimation and completion status
- Test error reporting integration

**Implementation**:
- Add progress indicators for long-running operations
- Implement step-by-step progress reporting
- Add time estimation and completion status
- Integrate with error reporting system

**Files**:
- `test/setup/test-progress.zsh` - Progress indicator tests
- `bin/lib/progress.zsh` - Progress reporting utilities
- `setup.zsh` - Updated with progress indicators
- `bin/install/*.zsh` - Updated with progress reporting

### PR 10: GitHub Actions Workflow
**Branch**: `feature/github-actions`
**Goal**: Add automated testing with smart triggering

**Implementation**:
- Create GitHub Actions workflow for automated testing
- Implement path-based triggering for setup-related files only
- Add manual trigger capability
- Test complete setup process on fresh macOS runners
- Add test result reporting and notifications

**Files**:
- `.github/workflows/test-setup.yml` - GitHub Actions workflow
- `test/ci/validate-setup.zsh` - CI validation script
- `test/ci/test-matrix.yml` - Test matrix configuration

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