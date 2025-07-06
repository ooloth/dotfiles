#!/usr/bin/env zsh

# Test runner for dotfiles setup scripts
# Usage: ./test/run-tests.zsh [test-file-pattern]

# Note: Not using set -e to allow test failures without stopping the runner

# Set DOTFILES environment variable
export DOTFILES="${DOTFILES:-$(cd "$(dirname "$0")/.." && pwd)}"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Test statistics
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Get the dotfiles directory
DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
export DOTFILES

# Source test utilities
source "$DOTFILES/test/lib/test-utils.zsh"

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}                                  ${YELLOW}Dotfiles Test Runner${NC}                                  ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

print_test_file_header() {
    local test_file="$1"
    echo -e "${BLUE}┌─ Running tests in: ${YELLOW}$test_file${NC}"
}

print_test_file_footer() {
    echo -e "${BLUE}└─ Tests completed${NC}"
    echo
}

run_test_file() {
    local test_file="$1"
    
    print_test_file_header "$test_file"
    
    # Show progress indicator for potentially slow tests
    echo -e "   ${BLUE}Running test file...${NC}"
    
    # Source the test file and run it in a subshell to prevent function pollution
    if (source "$test_file") 2>/dev/null; then
        echo -e "   ${GREEN}✓ Test file executed successfully${NC}"
    else
        echo -e "   ${RED}✗ Test file failed to execute${NC}"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$test_file")
    fi
    
    print_test_file_footer
}

find_test_files() {
    local pattern="${1:-*.zsh}"
    find "$DOTFILES/test" -name "test-*.zsh" -type f -not -path "*/lib/*" | sort
}

print_summary() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                                     Test Summary${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "Total tests run: ${YELLOW}$TESTS_RUN${NC}"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    echo
    
    if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
        echo -e "${RED}Failed tests:${NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo -e "  ${RED}✗ $test${NC}"
        done
        echo
    fi
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ $TESTS_FAILED test(s) failed${NC}"
        exit 1
    fi
}

main() {
    print_header
    
    local test_pattern="${1:-}"
    local test_files
    
    if [[ -n "$test_pattern" ]]; then
        test_files=($(find "$DOTFILES/test" -name "*$test_pattern*" -type f | sort))
    else
        test_files=($(find_test_files))
    fi
    
    if [[ ${#test_files[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No test files found matching pattern: $test_pattern${NC}"
        exit 0
    fi
    
    echo -e "Found ${YELLOW}${#test_files[@]}${NC} test file(s) to run"
    echo
    
    # Run each test file
    for test_file in "${test_files[@]}"; do
        run_test_file "$test_file"
        ((TESTS_RUN++))
    done
    
    # Count passed tests (total - failed)
    TESTS_PASSED=$((TESTS_RUN - TESTS_FAILED))
    
    print_summary
}

# Run main function with all arguments
main "$@"