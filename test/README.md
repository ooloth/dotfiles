# Dotfiles Testing Framework

This directory contains the testing framework for the dotfiles setup scripts. The framework provides comprehensive testing capabilities including unit tests, mocking, and integration testing.

## Quick Start

```bash
# Run all tests
./test/run-tests.zsh

# Run specific test file
./test/run-tests.zsh machine-detection

# Run tests matching a pattern
./test/run-tests.zsh setup
```

## Directory Structure

```
test/
├── run-tests.zsh           # Main test runner
├── lib/                    # Test utilities and framework
│   ├── test-utils.zsh      # Assertion functions and test helpers
│   └── mock.zsh            # Mocking framework for external commands
├── setup/                  # Tests for main setup functionality
│   └── test-machine-detection.zsh
├── install/                # Tests for individual installation scripts
│   ├── test-ssh.zsh
│   ├── test-homebrew.zsh
│   └── test-*.zsh
└── ci/                     # CI/CD specific tests
    └── validate-setup.zsh
```

## Testing Philosophy

### Test-Driven Development (TDD)
- Write tests first, then implement functionality
- Tests guide the design and implementation
- All functionality should be tested before merging

### Safe Testing
- Tests make **no system modifications**
- Use mocking for external dependencies
- Isolated test environments prevent interference
- Dry-run mode for integration testing

### Comprehensive Coverage
- Unit tests for individual functions
- Integration tests for complete workflows
- Edge case and error condition testing
- Performance and reliability testing

## Test Framework Features

### Assertion Functions
- `assert_equals expected actual [message]`
- `assert_not_equals not_expected actual [message]`
- `assert_true condition [message]`
- `assert_false condition [message]`
- `assert_file_exists path [message]`
- `assert_file_not_exists path [message]`
- `assert_directory_exists path [message]`
- `assert_command_exists command [message]`
- `assert_contains haystack needle [message]`
- `assert_not_contains haystack needle [message]`

### Test Organization
- `test_suite "Suite Name"` - Start a test suite
- `test_case "Test Name"` - Individual test case
- `test_suite_end` - End a test suite

### Environment Management
- `setup_test_environment` - Create isolated test environment
- `cleanup_test_environment` - Clean up test environment
- Temporary directories for test files
- Environment variable isolation

### Mocking Framework
- `init_mocking` - Initialize mocking system
- `cleanup_mocking` - Clean up mocks
- `mock_command cmd exit_code output [side_effect]` - Mock any command
- Specialized mocks for common commands:
  - `mock_brew [subcommand] [exit_code] [output]`
  - `mock_git [subcommand] [exit_code] [output]`
  - `mock_ssh_keygen [exit_code] [output]`
  - `mock_ssh [exit_code] [output]`
  - `mock_curl [exit_code] [output]`
  - `mock_sudo [exit_code] [output]`

### Mock Assertions
- `assert_command_called command [count] [message]`
- `assert_command_called_with command args [message]`
- `assert_command_not_called command [message]`
- `get_call_count command` - Get number of times command was called
- `get_call_args command [call_number]` - Get arguments from specific call

## Writing Tests

### Basic Test Structure
```bash
#!/usr/bin/env zsh

# Source test utilities
source "$DOTFILES/test/lib/test-utils.zsh"
source "$DOTFILES/test/lib/mock.zsh"

test_my_functionality() {
    test_suite "My Functionality"
    
    # Set up test environment
    setup_test_environment
    init_mocking
    
    test_case "Should do something"
    # Test implementation here
    assert_equals "expected" "actual" "Should match expected value"
    
    # Clean up
    cleanup_mocking
    cleanup_test_environment
    
    test_suite_end
}

# Run tests
main() {
    test_my_functionality
}

main
```

### Testing External Commands
```bash
test_case "Should install homebrew"
# Mock the curl command used by homebrew installer
mock_curl 0 "Installation successful"

# Mock the brew command after installation
mock_brew "--version" 0 "Homebrew 4.0.0"

# Run the installation script
source "$DOTFILES/bin/install/homebrew.zsh"

# Verify the commands were called
assert_command_called "curl" 1 "Should call curl to install homebrew"
assert_command_called "brew" 1 "Should call brew to verify installation"
```

### Testing File Operations
```bash
test_case "Should create symlinks"
# Set up test files
echo "test content" > "$TEST_DOTFILES/config/test.conf"

# Mock file operations
mock_command "ln" 0 ""

# Run symlink creation
create_symlink "$TEST_DOTFILES/config/test.conf" "$TEST_HOME/.test.conf"

# Verify operations
assert_command_called_with "ln" "-sf $TEST_DOTFILES/config/test.conf $TEST_HOME/.test.conf"
```

## Test Naming Conventions

### Test Files
- All test files start with `test-`
- Use descriptive names: `test-machine-detection.zsh`
- Group related tests in same file
- Place in appropriate subdirectory

### Test Functions
- Use descriptive function names: `test_machine_detection`
- One function per major feature area
- Include both positive and negative test cases

### Test Cases
- Use descriptive test case names
- Start with "Should" for expected behavior
- Include edge cases and error conditions

## Running Tests

### Local Testing
```bash
# Run all tests
./test/run-tests.zsh

# Run specific test file
./test/run-tests.zsh machine-detection

# Run tests with specific pattern
./test/run-tests.zsh install
```

### CI/CD Testing
Tests are automatically run via GitHub Actions when setup-related files change:
- `setup.zsh`
- `bin/install/**`
- `bin/update/**`
- `macos/Brewfile`
- `config/**`

### Debugging Tests
- Use `echo` statements for debugging (they'll be visible in test output)
- Check mock call logs with `get_all_call_args command`
- Use `capture_output` helper for command output testing
- Set up isolated test environments to prevent interference

## Best Practices

### Test Independence
- Each test should be independent and isolated
- Use `setup_test_environment` and `cleanup_test_environment`
- Don't rely on state from previous tests
- Clean up mocks after each test

### Meaningful Assertions
- Use descriptive assertion messages
- Test both success and failure cases
- Verify expected side effects (files created, commands called)
- Test edge cases and error conditions

### Performance
- Mock expensive operations (network calls, file operations)
- Use temporary directories for test files
- Clean up resources after testing
- Keep tests focused and fast

### Maintainability
- Keep tests simple and readable
- Use helper functions for common operations
- Document complex test scenarios
- Update tests when functionality changes

## Troubleshooting

### Common Issues
1. **PATH Issues**: Ensure mocked commands are in PATH
2. **Environment Variables**: Use isolated test environments
3. **File Permissions**: Check file permissions in test directories
4. **Mock Cleanup**: Always clean up mocks after tests

### Debugging Tips
1. Add debug output to understand test flow
2. Check mock call logs to verify command execution
3. Use `set -x` for detailed script execution
4. Verify test environment setup is correct

---

This testing framework provides a solid foundation for reliable, maintainable tests that help ensure the dotfiles setup process works correctly across different environments and scenarios.