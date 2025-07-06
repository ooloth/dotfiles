#!/usr/bin/env zsh

# Mocking framework for external commands and dependencies

# Global variables for mock management
declare -A MOCK_COMMANDS
declare -A MOCK_OUTPUTS
declare -A MOCK_EXIT_CODES
declare -A MOCK_CALL_COUNTS
MOCK_DIR=""

# Initialize mocking system
init_mocking() {
    MOCK_DIR="$TEST_TEMP_DIR/mocks"
    mkdir -p "$MOCK_DIR"
    
    # Clear existing mocks
    MOCK_COMMANDS=()
    MOCK_OUTPUTS=()
    MOCK_EXIT_CODES=()
    MOCK_CALL_COUNTS=()
    
    # Add mock directory to beginning of PATH
    export PATH="$MOCK_DIR:$PATH"
}

# Clean up mocking system
cleanup_mocking() {
    if [[ -n "$MOCK_DIR" && -d "$MOCK_DIR" ]]; then
        rm -rf "$MOCK_DIR"
    fi
    
    # Remove mock directory from PATH
    export PATH="${PATH//$MOCK_DIR:/}"
    
    # Clear mock data
    MOCK_COMMANDS=()
    MOCK_OUTPUTS=()
    MOCK_EXIT_CODES=()
    MOCK_CALL_COUNTS=()
}

# Mock a command with specified behavior
mock_command() {
    local command="$1"
    local exit_code="${2:-0}"
    local output="${3:-}"
    local side_effect="${4:-}"
    
    # Store mock configuration
    MOCK_COMMANDS["$command"]="$command"
    MOCK_EXIT_CODES["$command"]="$exit_code"
    MOCK_OUTPUTS["$command"]="$output"
    MOCK_CALL_COUNTS["$command"]=0
    
    # Create mock script
    local mock_script="$MOCK_DIR/$command"
    cat > "$mock_script" << EOF
#!/usr/bin/env zsh

# Mock for command: $command
# Arguments passed: \$@

# Record the call
MOCK_CALL_FILE="$MOCK_DIR/.${command}_calls"
echo "\$@" >> "\$MOCK_CALL_FILE"

# Execute side effect if provided
if [[ -n "$side_effect" ]]; then
    $side_effect
fi

# Output the mocked response
echo "$output"

# Exit with mocked exit code
exit $exit_code
EOF
    
    chmod +x "$mock_script"
    
    echo "Mocked command: $command (exit: $exit_code)"
}

# Mock common system commands
mock_brew() {
    local subcommand="${1:-}"
    local exit_code="${2:-0}"
    local output="${3:-}"
    
    case "$subcommand" in
        "install")
            mock_command "brew" "$exit_code" "$output"
            ;;
        "list")
            mock_command "brew" "$exit_code" "${output:-homebrew/core/git 2.39.0}"
            ;;
        "--version")
            mock_command "brew" "$exit_code" "${output:-Homebrew 4.0.0}"
            ;;
        *)
            mock_command "brew" "$exit_code" "$output"
            ;;
    esac
}

mock_git() {
    local subcommand="${1:-}"
    local exit_code="${2:-0}"
    local output="${3:-}"
    
    case "$subcommand" in
        "clone")
            mock_command "git" "$exit_code" "$output" "mkdir -p \$4 2>/dev/null || true"
            ;;
        "pull")
            mock_command "git" "$exit_code" "${output:-Already up to date.}"
            ;;
        "config")
            mock_command "git" "$exit_code" "$output"
            ;;
        *)
            mock_command "git" "$exit_code" "$output"
            ;;
    esac
}

mock_ssh_keygen() {
    local exit_code="${1:-0}"
    local output="${2:-}"
    
    mock_command "ssh-keygen" "$exit_code" "$output" "
        mkdir -p ~/.ssh 2>/dev/null || true
        touch ~/.ssh/id_rsa ~/.ssh/id_rsa.pub 2>/dev/null || true
        echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC...' > ~/.ssh/id_rsa.pub 2>/dev/null || true
    "
}

mock_ssh() {
    local exit_code="${1:-0}"
    local output="${2:-Hi username! You've successfully authenticated, but GitHub does not provide shell access.}"
    
    mock_command "ssh" "$exit_code" "$output"
}

mock_curl() {
    local exit_code="${1:-0}"
    local output="${2:-}"
    
    mock_command "curl" "$exit_code" "$output"
}

mock_sudo() {
    local exit_code="${1:-0}"
    local output="${2:-}"
    
    mock_command "sudo" "$exit_code" "$output"
}

mock_chsh() {
    local exit_code="${1:-0}"
    local output="${2:-}"
    
    mock_command "chsh" "$exit_code" "$output"
}

mock_xcode_select() {
    local exit_code="${1:-0}"
    local output="${2:-}"
    
    mock_command "xcode-select" "$exit_code" "$output"
}

# Check if a command was called
was_command_called() {
    local command="$1"
    local call_file="$MOCK_DIR/.${command}_calls"
    
    [[ -f "$call_file" ]] && [[ -s "$call_file" ]]
}

# Get the number of times a command was called
get_call_count() {
    local command="$1"
    local call_file="$MOCK_DIR/.${command}_calls"
    
    if [[ -f "$call_file" ]]; then
        wc -l < "$call_file" | tr -d ' '
    else
        echo "0"
    fi
}

# Get the arguments from a specific call
get_call_args() {
    local command="$1"
    local call_number="${2:-1}"
    local call_file="$MOCK_DIR/.${command}_calls"
    
    if [[ -f "$call_file" ]]; then
        sed -n "${call_number}p" "$call_file"
    fi
}

# Get all call arguments
get_all_call_args() {
    local command="$1"
    local call_file="$MOCK_DIR/.${command}_calls"
    
    if [[ -f "$call_file" ]]; then
        cat "$call_file"
    fi
}

# Assert that a command was called
assert_command_called() {
    local command="$1"
    local expected_count="${2:-1}"
    local message="${3:-}"
    
    local actual_count=$(get_call_count "$command")
    
    if [[ "$actual_count" -eq "$expected_count" ]]; then
        echo -e "${TEST_BLUE}    │  ${TEST_GREEN}✓ Assert command called passed${TEST_NC}"
        ((TEST_SUITE_PASSED++))
        return 0
    else
        echo -e "${TEST_BLUE}    │  ${TEST_RED}✗ Assert command called failed${TEST_NC}"
        echo -e "${TEST_BLUE}    │    Command: ${TEST_YELLOW}$command${TEST_NC}"
        echo -e "${TEST_BLUE}    │    Expected calls: ${TEST_YELLOW}$expected_count${TEST_NC}"
        echo -e "${TEST_BLUE}    │    Actual calls: ${TEST_YELLOW}$actual_count${TEST_NC}"
        [[ -n "$message" ]] && echo -e "${TEST_BLUE}    │    Message: ${TEST_YELLOW}$message${TEST_NC}"
        ((TEST_SUITE_FAILED++))
        return 1
    fi
}

# Assert that a command was called with specific arguments
assert_command_called_with() {
    local command="$1"
    local expected_args="$2"
    local message="${3:-}"
    
    local all_calls=$(get_all_call_args "$command")
    
    if [[ "$all_calls" == *"$expected_args"* ]]; then
        echo -e "${TEST_BLUE}    │  ${TEST_GREEN}✓ Assert command called with passed${TEST_NC}"
        ((TEST_SUITE_PASSED++))
        return 0
    else
        echo -e "${TEST_BLUE}    │  ${TEST_RED}✗ Assert command called with failed${TEST_NC}"
        echo -e "${TEST_BLUE}    │    Command: ${TEST_YELLOW}$command${TEST_NC}"
        echo -e "${TEST_BLUE}    │    Expected args: ${TEST_YELLOW}$expected_args${TEST_NC}"
        echo -e "${TEST_BLUE}    │    All calls:${TEST_NC}"
        while IFS= read -r call; do
            echo -e "${TEST_BLUE}    │      ${TEST_YELLOW}$call${TEST_NC}"
        done <<< "$all_calls"
        [[ -n "$message" ]] && echo -e "${TEST_BLUE}    │    Message: ${TEST_YELLOW}$message${TEST_NC}"
        ((TEST_SUITE_FAILED++))
        return 1
    fi
}

# Assert that a command was not called
assert_command_not_called() {
    local command="$1"
    local message="${2:-}"
    
    local actual_count=$(get_call_count "$command")
    
    if [[ "$actual_count" -eq 0 ]]; then
        echo -e "${TEST_BLUE}    │  ${TEST_GREEN}✓ Assert command not called passed${TEST_NC}"
        ((TEST_SUITE_PASSED++))
        return 0
    else
        echo -e "${TEST_BLUE}    │  ${TEST_RED}✗ Assert command not called failed${TEST_NC}"
        echo -e "${TEST_BLUE}    │    Command: ${TEST_YELLOW}$command${TEST_NC}"
        echo -e "${TEST_BLUE}    │    Actual calls: ${TEST_YELLOW}$actual_count${TEST_NC}"
        [[ -n "$message" ]] && echo -e "${TEST_BLUE}    │    Message: ${TEST_YELLOW}$message${TEST_NC}"
        ((TEST_SUITE_FAILED++))
        return 1
    fi
}

# Mock file system operations
mock_file_system() {
    # Mock common file operations
    mock_command "mkdir" 0 ""
    mock_command "touch" 0 ""
    mock_command "ln" 0 ""
    mock_command "cp" 0 ""
    mock_command "mv" 0 ""
    mock_command "rm" 0 ""
    mock_command "chmod" 0 ""
    mock_command "chown" 0 ""
}

# Functions are available when this file is sourced
# No need to export since we're sourcing in the same shell context