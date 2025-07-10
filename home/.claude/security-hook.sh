#!/bin/bash

# Claude Code Security Hook
# Protects against dangerous operations when running in YOLO mode

set -euo pipefail

# Read input from stdin
INPUT=$(cat)

# Extract tool name and parameters
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input')

# Check if we're in YOLO mode by looking for the flag in process tree
if ! pgrep -f "claude.*--dangerously-skip-permissions" > /dev/null 2>&1; then
    # Not in YOLO mode, allow everything
    exit 0
fi

# Audit log location
AUDIT_LOG="$HOME/.claude/security-audit.log"
BLOCKED_LOG="$HOME/.claude/blocked-commands.log"

# Emergency stop check
if [[ -f "$HOME/.claude/emergency-stop" ]]; then
    echo "EMERGENCY STOP: All operations blocked. Remove ~/.claude/emergency-stop to continue." >&2
    echo "$(date): EMERGENCY STOP triggered for $TOOL_NAME" >>"$BLOCKED_LOG"
    exit 1
fi

# Function to log commands
log_command() {
    local status="$1"
    local tool="$2"
    local details="$3"
    echo "$(date): [$status] $tool: $details" >>"$AUDIT_LOG"
}

# Function to block and log
block_command() {
    local reason="$1"
    local details="$2"
    echo "BLOCKED: $reason" >&2
    echo "$(date): $reason - $details" >>"$BLOCKED_LOG"
    log_command "BLOCKED" "$TOOL_NAME" "$details"
    exit 1
}

# Check Bash commands
if [[ "$TOOL_NAME" == "Bash" ]]; then
    COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // empty')

    # Log all bash commands
    log_command "ATTEMPT" "Bash" "$COMMAND"

    # Dangerous command patterns
    DANGEROUS_PATTERNS=(
        # Network access
        "curl[[:space:]]+-[^-]*o" # curl with output
        "wget[[:space:]]"
        "nc[[:space:]]"
        "telnet[[:space:]]"
        "ssh[[:space:]]+[^l]" # ssh to external (not localhost)
        "scp[[:space:]]"
        "rsync[[:space:]]+.*:"

        # System destruction
        "rm[[:space:]]+-[^-]*[rf].*/"
        "dd[[:space:]]+.*of=/dev/"
        "mkfs"
        "fdisk"
        "parted"

        # Privilege escalation
        "sudo[[:space:]]"
        "su[[:space:]]"
        "chroot"
        "doas"

        # Package management
        "brew[[:space:]]+install"
        "brew[[:space:]]+uninstall"
        "brew[[:space:]]+remove"
        "apt[[:space:]]+install"
        "apt-get[[:space:]]+install"
        "yum[[:space:]]+install"
        "pip[[:space:]]+install"
        "npm[[:space:]]+install[[:space:]]+--global"

        # System services
        "systemctl[[:space:]]+(start|stop|restart|enable|disable)"
        "service[[:space:]]"
        "launchctl[[:space:]]+(load|unload|start|stop)"

        # Dangerous file operations
        ":>/etc/"
        ">/etc/"
        ">>/etc/"

        # Process control
        "kill[[:space:]]+-9"
        "killall"
        "pkill"

        # System modification
        "crontab[[:space:]]+-[er]"
        "at[[:space:]]"
        "visudo"
    )

    # Check each pattern - only at the beginning of commands
    for pattern in "${DANGEROUS_PATTERNS[@]}"; do
        # Check if pattern matches at start of command or after common separators
        if [[ "$COMMAND" =~ ^$pattern ]] || [[ "$COMMAND" =~ [[:space:]\;\|\&]$pattern ]]; then
            block_command "Dangerous command pattern detected: $pattern" "$COMMAND"
        fi
    done

    # Check for system directory modifications
    PROTECTED_PATHS=(
        "/etc"
        "/usr"
        "/bin"
        "/sbin"
        "/boot"
        "/dev"
        "/lib"
        "/lib64"
        "/proc"
        "/sys"
        "/var/log"
        "$HOME/.ssh"
        "$HOME/.gnupg"
    )

    for path in "${PROTECTED_PATHS[@]}"; do
        if [[ "$COMMAND" =~ (rm|mv|cp|chmod|chown).*$path ]]; then
            block_command "Attempt to modify protected path: $path" "$COMMAND"
        fi
    done

    # Check for download attempts
    if [[ "$COMMAND" =~ (curl|wget|fetch).*(http|https|ftp):// ]]; then
        # Allow localhost
        if [[ "$COMMAND" =~ (localhost|127\.0\.0\.1|::1) ]]; then
            log_command "ALLOWED" "Bash" "$COMMAND (localhost)"
        else
            # Extract URL from command
            URL=$(echo "$COMMAND" | grep -oE "(https?|ftp)://[^[:space:]]+" | head -1)
            if [[ -n "$URL" ]]; then
                # Extract domain from URL
                DOMAIN=$(echo "$URL" | sed -E 's|https?://([^/]+).*|\1|')
                
                # Check against allowed domains (same list as WebFetch)
                ALLOWED_DOMAINS=(
                    "github.com"
                    "githubusercontent.com"
                    "docs.anthropic.com"
                    "anthropic.com"
                    "stackoverflow.com"
                    "developer.mozilla.org"
                    "rust-lang.org"
                    "python.org"
                    "nodejs.org"
                    "npmjs.com"
                )
                
                ALLOWED=false
                for allowed in "${ALLOWED_DOMAINS[@]}"; do
                    if [[ "$DOMAIN" == *"$allowed" ]]; then
                        ALLOWED=true
                        break
                    fi
                done
                
                if [[ "$ALLOWED" != "true" ]]; then
                    block_command "curl/wget to non-whitelisted domain: $DOMAIN" "$COMMAND"
                fi
                
                log_command "ALLOWED" "Bash" "$COMMAND (allowed domain: $DOMAIN)"
            else
                block_command "External network access attempted (could not parse URL)" "$COMMAND"
            fi
        fi
    fi

    log_command "ALLOWED" "Bash" "$COMMAND"
fi

# Check file operations
if [[ "$TOOL_NAME" =~ ^(Write|Edit|MultiEdit)$ ]]; then
    FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')

    log_command "ATTEMPT" "$TOOL_NAME" "$FILE_PATH"

    # Normalize path
    if [[ -n "$FILE_PATH" ]]; then
        # Resolve to absolute path
        if cd "$(dirname "$FILE_PATH")" 2>/dev/null; then
            ABS_PATH="$(pwd)/$(basename "$FILE_PATH")"
        else
            ABS_PATH="$(dirname "$FILE_PATH")/$(basename "$FILE_PATH")"
        fi

        # Check protected paths
        PROTECTED_PREFIXES=(
            "/etc"
            "/usr"
            "/bin"
            "/sbin"
            "/boot"
            "/lib"
            "/System"
            "/Library"
            "/private/etc"
            "/private/var"
            "$HOME/.ssh"
            "$HOME/.gnupg"
            "$HOME/Library/Keychains"
        )

        for prefix in "${PROTECTED_PREFIXES[@]}"; do
            if [[ "$ABS_PATH" == "$prefix"* ]]; then
                block_command "Attempt to modify protected file" "$FILE_PATH"
            fi
        done

        # Block certain file patterns
        BLOCKED_PATTERNS=(
            "*.pem"
            "*.key"
            "*.crt"
            "*.p12"
            "id_rsa*"
            "id_ed25519*"
            "id_ecdsa*"
            "*.kdbx" # KeePass
            "*.1password"
            "*.keychain"
        )

        for pattern in "${BLOCKED_PATTERNS[@]}"; do
            if [[ "$(basename "$FILE_PATH")" == "$pattern" ]]; then
                block_command "Attempt to modify sensitive file type" "$FILE_PATH"
            fi
        done
    fi

    log_command "ALLOWED" "$TOOL_NAME" "$FILE_PATH"
fi

# Check web operations
if [[ "$TOOL_NAME" == "WebFetch" ]]; then
    URL=$(echo "$TOOL_INPUT" | jq -r '.url // empty')

    log_command "ATTEMPT" "WebFetch" "$URL"

    # Only allow certain domains
    ALLOWED_DOMAINS=(
        "github.com"
        "githubusercontent.com"
        "docs.anthropic.com"
        "anthropic.com"
        "stackoverflow.com"
        "developer.mozilla.org"
        "rust-lang.org"
        "python.org"
        "nodejs.org"
        "npmjs.com"
    )

    DOMAIN=$(echo "$URL" | sed -E 's|https?://([^/]+).*|\1|')
    ALLOWED=false

    for allowed in "${ALLOWED_DOMAINS[@]}"; do
        if [[ "$DOMAIN" == *"$allowed" ]]; then
            ALLOWED=true
            break
        fi
    done

    if [[ "$ALLOWED" != "true" ]]; then
        block_command "WebFetch to non-whitelisted domain" "$URL"
    fi

    log_command "ALLOWED" "WebFetch" "$URL"
fi

# All checks passed
exit 0

