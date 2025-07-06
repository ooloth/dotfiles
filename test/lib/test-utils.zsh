#!/usr/bin/env zsh

# Test utilities and assertion functions for dotfiles testing

# Colors for test output
readonly TEST_RED='\033[0;31m'
readonly TEST_GREEN='\033[0;32m'
readonly TEST_YELLOW='\033[1;33m'
readonly TEST_BLUE='\033[0;34m'
readonly TEST_NC='\033[0m' # No Color

# Test state tracking
TEST_CURRENT_SUITE=""
TEST_CURRENT_TEST=""
TEST_SUITE_PASSED=0
TEST_SUITE_FAILED=0

# Test suite functions
test_suite() {
    local suite_name="$1"
    TEST_CURRENT_SUITE="$suite_name"
    TEST_SUITE_PASSED=0
    TEST_SUITE_FAILED=0
    echo -e "${TEST_BLUE}  ┌─ Test Suite: ${TEST_YELLOW}$suite_name${TEST_NC}"
}

test_suite_end() {
    local total=$((TEST_SUITE_PASSED + TEST_SUITE_FAILED))
    echo -e "${TEST_BLUE}  └─ Suite completed: ${TEST_GREEN}$TEST_SUITE_PASSED passed${TEST_NC}, ${TEST_RED}$TEST_SUITE_FAILED failed${TEST_NC} (${total} total)"
}

test_case() {
    local test_name="$1"
    TEST_CURRENT_TEST="$test_name"
    echo -e "${TEST_BLUE}    ├─ ${TEST_YELLOW}$test_name${TEST_NC}"
}

# Assertion functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${TEST_BLUE}    │  ${TEST_GREEN}✓ Assert equals passed${TEST_NC}"
        ((TEST_SUITE_PASSED++))
        return 0
    else
        echo -e "${TEST_BLUE}    │  ${TEST_RED}✗ Assert equals failed${TEST_NC}"
        echo -e "${TEST_BLUE}    │    Expected: ${TEST_YELLOW}$expected${TEST_NC}"
        echo -e "${TEST_BLUE}    │    Actual:   ${TEST_YELLOW}$actual${TEST_NC}"
        [[ -n "$message" ]] && echo -e "${TEST_BLUE}    │    Message:  ${TEST_YELLOW}$message${TEST_NC}"
        ((TEST_SUITE_FAILED++))
        return 1
    fi
}

assert_not_equals() {
    local not_expected="$1"
    local actual="$2"
    local message="${3:-}"
    
    if [[ "$not_expected" != "$actual" ]]; then
        echo -e "${TEST_BLUE}    │  ${TEST_GREEN}✓ Assert not equals passed${TEST_NC}"
        ((TEST_SUITE_PASSED++))
        return 0
    else
        echo -e "${TEST_BLUE}    │  ${TEST_RED}✗ Assert not equals failed${TEST_NC}"
        echo -e "${TEST_BLUE}    │    Not expected: ${TEST_YELLOW}$not_expected${TEST_NC}"
        echo -e "${TEST_BLUE}    │    Actual:       ${TEST_YELLOW}$actual${TEST_NC}"
        [[ -n "$message" ]] && echo -e "${TEST_BLUE}    │    Message:      ${TEST_YELLOW}$message${TEST_NC}"
        ((TEST_SUITE_FAILED++))
        return 1
    fi
}

assert_true() {
    local condition="$1"
    local message="${2:-}"
    
    if [[ "$condition" == "true" ]] || [[ "$condition" == "0" ]]; then
        echo -e "${TEST_BLUE}    │  ${TEST_GREEN}✓ Assert true passed${TEST_NC}"
        ((TEST_SUITE_PASSED++))
        return 0
    else
        echo -e "${TEST_BLUE}    │  ${TEST_RED}✗ Assert true failed${TEST_NC}"
        echo -e "${TEST_BLUE}    │    Condition: ${TEST_YELLOW}$condition${TEST_NC}"
        [[ -n "$message" ]] && echo -e "${TEST_BLUE}    │    Message:   ${TEST_YELLOW}$message${TEST_NC}"
        ((TEST_SUITE_FAILED++))
        return 1
    fi
}

assert_false() {
    local condition="$1"
    local message="${2:-}"
    
    if [[ "$condition" == "false" ]] || [[ "$condition" != "0" && "$condition" != "true" ]]; then
        echo -e "${TEST_BLUE}    │  ${TEST_GREEN}✓ Assert false passed${TEST_NC}"
        ((TEST_SUITE_PASSED++))
        return 0
    else
        echo -e "${TEST_BLUE}    │  ${TEST_RED}✗ Assert false failed${TEST_NC}"
        echo -e "${TEST_BLUE}    │    Condition: ${TEST_YELLOW}$condition${TEST_NC}"
        [[ -n "$message" ]] && echo -e "${TEST_BLUE}    │    Message:   ${TEST_YELLOW}$message${TEST_NC}"
        ((TEST_SUITE_FAILED++))
        return 1
    fi
}

assert_file_exists() {
    local file_path="$1"
    local message="${2:-}"
    
    if [[ -f "$file_path" ]]; then
        echo -e "${TEST_BLUE}    │  ${TEST_GREEN}✓ Assert file exists passed${TEST_NC}"
        ((TEST_SUITE_PASSED++))
        return 0
    else
        echo -e "${TEST_BLUE}    │  ${TEST_RED}✗ Assert file exists failed${TEST_NC}"
        echo -e "${TEST_BLUE}    │    File: ${TEST_YELLOW}$file_path${TEST_NC}"
        [[ -n "$message" ]] && echo -e "${TEST_BLUE}    │    Message: ${TEST_YELLOW}$message${TEST_NC}"
        ((TEST_SUITE_FAILED++))
        return 1
    fi
}

assert_file_not_exists() {
    local file_path="$1"
    local message="${2:-}"
    
    if [[ ! -f "$file_path" ]]; then
        echo -e "${TEST_BLUE}    │  ${TEST_GREEN}✓ Assert file not exists passed${TEST_NC}"
        ((TEST_SUITE_PASSED++))
        return 0
    else
        echo -e "${TEST_BLUE}    │  ${TEST_RED}✗ Assert file not exists failed${TEST_NC}"
        echo -e "${TEST_BLUE}    │    File: ${TEST_YELLOW}$file_path${TEST_NC}"
        [[ -n "$message" ]] && echo -e "${TEST_BLUE}    │    Message: ${TEST_YELLOW}$message${TEST_NC}"
        ((TEST_SUITE_FAILED++))
        return 1
    fi
}

assert_directory_exists() {
    local dir_path="$1"
    local message="${2:-}"
    
    if [[ -d "$dir_path" ]]; then
        echo -e "${TEST_BLUE}    │  ${TEST_GREEN}✓ Assert directory exists passed${TEST_NC}"
        ((TEST_SUITE_PASSED++))
        return 0
    else
        echo -e "${TEST_BLUE}    │  ${TEST_RED}✗ Assert directory exists failed${TEST_NC}"
        echo -e "${TEST_BLUE}    │    Directory: ${TEST_YELLOW}$dir_path${TEST_NC}"
        [[ -n "$message" ]] && echo -e "${TEST_BLUE}    │    Message: ${TEST_YELLOW}$message${TEST_NC}"
        ((TEST_SUITE_FAILED++))
        return 1
    fi
}

assert_command_exists() {
    local command="$1"
    local message="${2:-}"
    
    if command -v "$command" >/dev/null 2>&1; then
        echo -e "${TEST_BLUE}    │  ${TEST_GREEN}✓ Assert command exists passed${TEST_NC}"
        ((TEST_SUITE_PASSED++))
        return 0
    else
        echo -e "${TEST_BLUE}    │  ${TEST_RED}✗ Assert command exists failed${TEST_NC}"
        echo -e "${TEST_BLUE}    │    Command: ${TEST_YELLOW}$command${TEST_NC}"
        [[ -n "$message" ]] && echo -e "${TEST_BLUE}    │    Message: ${TEST_YELLOW}$message${TEST_NC}"
        ((TEST_SUITE_FAILED++))
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-}"
    
    if [[ "$haystack" == *"$needle"* ]]; then
        echo -e "${TEST_BLUE}    │  ${TEST_GREEN}✓ Assert contains passed${TEST_NC}"
        ((TEST_SUITE_PASSED++))
        return 0
    else
        echo -e "${TEST_BLUE}    │  ${TEST_RED}✗ Assert contains failed${TEST_NC}"
        echo -e "${TEST_BLUE}    │    Haystack: ${TEST_YELLOW}$haystack${TEST_NC}"
        echo -e "${TEST_BLUE}    │    Needle:   ${TEST_YELLOW}$needle${TEST_NC}"
        [[ -n "$message" ]] && echo -e "${TEST_BLUE}    │    Message:  ${TEST_YELLOW}$message${TEST_NC}"
        ((TEST_SUITE_FAILED++))
        return 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-}"
    
    if [[ "$haystack" != *"$needle"* ]]; then
        echo -e "${TEST_BLUE}    │  ${TEST_GREEN}✓ Assert not contains passed${TEST_NC}"
        ((TEST_SUITE_PASSED++))
        return 0
    else
        echo -e "${TEST_BLUE}    │  ${TEST_RED}✗ Assert not contains failed${TEST_NC}"
        echo -e "${TEST_BLUE}    │    Haystack: ${TEST_YELLOW}$haystack${TEST_NC}"
        echo -e "${TEST_BLUE}    │    Needle:   ${TEST_YELLOW}$needle${TEST_NC}"
        [[ -n "$message" ]] && echo -e "${TEST_BLUE}    │    Message:  ${TEST_YELLOW}$message${TEST_NC}"
        ((TEST_SUITE_FAILED++))
        return 1
    fi
}

# Helper functions for testing
setup_test_environment() {
    # Create a temporary directory for test files
    export TEST_TEMP_DIR=$(mktemp -d)
    export TEST_HOME="$TEST_TEMP_DIR/home"
    export TEST_DOTFILES="$TEST_TEMP_DIR/dotfiles"
    
    mkdir -p "$TEST_HOME" "$TEST_DOTFILES"
    
    # Set up a clean environment for testing
    export HOME="$TEST_HOME"
    export DOTFILES="$TEST_DOTFILES"
}

cleanup_test_environment() {
    # Clean up temporary test files
    if [[ -n "$TEST_TEMP_DIR" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
    
    # Restore original environment
    unset TEST_TEMP_DIR TEST_HOME TEST_DOTFILES
}

# Mock function helpers
mock_command() {
    local command="$1"
    local return_value="${2:-0}"
    local output="${3:-}"
    
    # Create a mock script that returns the specified value and output
    local mock_script="$TEST_TEMP_DIR/mock_$command"
    cat > "$mock_script" << EOF
#!/bin/bash
echo "$output"
exit $return_value
EOF
    chmod +x "$mock_script"
    
    # Add to PATH so it takes precedence
    export PATH="$TEST_TEMP_DIR:$PATH"
}

restore_command() {
    local command="$1"
    local mock_script="$TEST_TEMP_DIR/mock_$command"
    
    if [[ -f "$mock_script" ]]; then
        rm "$mock_script"
    fi
}

# Test execution helpers
run_with_timeout() {
    local timeout_seconds="$1"
    local command="$2"
    
    timeout "$timeout_seconds" bash -c "$command"
}

capture_output() {
    local command="$1"
    local output_file="$TEST_TEMP_DIR/command_output"
    
    eval "$command" > "$output_file" 2>&1
    cat "$output_file"
}

# Functions are available when this file is sourced
# No need to export since we're sourcing in the same shell context