#!/bin/bash

# Claude Code Security Hook
# Protects against dangerous operations when running in YOLO mode

set -euo pipefail

# Check if we're in YOLO mode first - optimize for early return
if [[ "${CLAUDE_YOLO_MODE:-}" != "true" ]] && [[ ! -f "$HOME/.claude/yolo-mode-override" ]]; then
    # Not in YOLO mode, allow everything immediately
    exit 0
fi

# Read input from stdin
INPUT=$(cat)

# Extract tool name and parameters
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input')

# Function to show periodic security status
show_security_status() {
    local last_shown_file="$HOME/.claude/last-status-shown"
    local current_hour
    current_hour=$(date +%Y%m%d%H)
    
    # Only show status once per hour
    if [[ -f "$last_shown_file" ]]; then
        local last_shown
        last_shown=$(cat "$last_shown_file" 2>/dev/null || echo "0")
        if [[ "$current_hour" == "$last_shown" ]]; then
            return 0
        fi
    fi
    
    # Count today's stats (simple approach)
    local today
    today=$(date +"%a %d %b %Y")
    local blocked_today=0
    local total_today=0
    local allowed_today=0
    
    if [[ -f "$HOME/.claude/blocked-commands.log" ]]; then
        blocked_today=$(grep -c "$today.*BLOCKED" "$HOME/.claude/blocked-commands.log" 2>/dev/null || echo "0")
    fi
    
    if [[ -f "$HOME/.claude/security-audit.log" ]]; then
        total_today=$(grep -c "$today" "$HOME/.claude/security-audit.log" 2>/dev/null || echo "0")
    fi
    
    allowed_today=$((total_today - blocked_today))
    
    # Show status
    echo "🔒 YOLO Security Active - Enhanced protection engaged" >&2
    echo "📊 Today: $blocked_today commands blocked, $allowed_today allowed" >&2
    echo "🛡️  Monitoring: Network, file system, privileges, packages" >&2
    echo "🚨 Emergency stop: touch ~/.claude/emergency-stop" >&2
    echo "" >&2
    
    # Remember we showed status this hour
    echo "$current_hour" > "$last_shown_file"
}

# We're in YOLO mode - show periodic security status (Item 9: User Education)
# Only show status periodically to avoid performance overhead
show_security_status

# Audit log location
AUDIT_LOG="$HOME/.claude/security-audit.log"
BLOCKED_LOG="$HOME/.claude/blocked-commands.log"

# Shared configuration
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
    echo "🔒 BLOCKED: $reason" >&2
    echo "$(date): $reason - $details" >>"$BLOCKED_LOG"
    log_command "BLOCKED" "$TOOL_NAME" "$details"
    
    # Show educational message
    show_security_education "$reason"
    exit 1
}

# Function to show security education (Item 9: User Education)
show_security_education() {
    local threat_type="$1"
    
    case "$threat_type" in
        *"domain"*|*"network"*)
            echo "ℹ️  Network Protection: Only whitelisted domains allowed (github.com, docs.anthropic.com, etc.)" >&2
            echo "   This prevents data exfiltration and malicious downloads." >&2
            ;;
        *"sudo"*|*"privilege"*)
            echo "ℹ️  Privilege Protection: System-level changes blocked in YOLO mode." >&2
            echo "   This prevents unauthorized system modifications." >&2
            ;;
        *"install"*|*"package"*)
            echo "ℹ️  Package Protection: Software installation blocked in YOLO mode." >&2
            echo "   This prevents installation of malicious or conflicting packages." >&2
            ;;
        *"rm"*|*"delete"*)
            echo "ℹ️  File Protection: Destructive file operations blocked." >&2
            echo "   This prevents accidental deletion of important data." >&2
            ;;
        *"protected"*)
            echo "ℹ️  System Protection: Critical system files and directories are protected." >&2
            echo "   This maintains system integrity and security." >&2
            ;;
        *)
            echo "ℹ️  Security Protection: Potentially dangerous operation blocked." >&2
            echo "   YOLO mode provides defense-in-depth security." >&2
            ;;
    esac
    echo "   Emergency stop: touch ~/.claude/emergency-stop" >&2
}


# Function to check if SSH command is to localhost
is_ssh_localhost() {
    local command="$1"
    # Extract SSH target (simplified - captures common patterns)
    if [[ "$command" =~ ssh[[:space:]]+([^[:space:]]+) ]]; then
        local target="${BASH_REMATCH[1]}"
        # Check for localhost patterns
        if [[ "$target" =~ ^(localhost|127\.0\.0\.1|::1|[^@]*@localhost|[^@]*@127\.0\.0\.1)$ ]]; then
            return 0
        fi
    fi
    return 1
}

# Function to extract and validate URL
extract_and_validate_url() {
    local command="$1"
    local url
    
    # Extract URL using grep (more reliable than complex bash regex)
    url=$(echo "$command" | grep -oE "(https?|ftp)://[^[:space:]]+" | head -1)
    
    if [[ -z "$url" ]]; then
        return 1
    fi
    
    # Validate URL format - basic validation
    if [[ "$url" =~ ^(https?|ftp)://[a-zA-Z0-9.-]+ ]]; then
        echo "$url"
        return 0
    fi
    
    return 1
}

# Check Bash commands
if [[ "$TOOL_NAME" == "Bash" ]]; then
    COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // empty')

    # Log all bash commands
    log_command "ATTEMPT" "Bash" "$COMMAND"

    # Dangerous command patterns (using word boundaries for precision)
    DANGEROUS_PATTERNS=(
        # Network access
        "(^|[[:space:]])curl[[:space:]]+(-[^[:space:]]*[oO][^[:space:]]*|.*-o|.*--output)" # curl with output flags
        "(^|[[:space:]])wget[[:space:]]"
        "(^|[[:space:]])nc[[:space:]]"
        "(^|[[:space:]])netcat[[:space:]]"
        "(^|[[:space:]])telnet[[:space:]]"
        "(^|[[:space:]])scp[[:space:]]"
        "(^|[[:space:]])rsync[[:space:]]+[^[:space:]]*:"
        "(^|[[:space:]])sftp[[:space:]]"
        "(^|[[:space:]])ftp[[:space:]]"

        # System destruction (more comprehensive)
        "(^|[[:space:]])rm[[:space:]]+(-[^[:space:]]*[rR][fF]?|--recursive.*--force|-rf|-fr|-R.*-f|-f.*-R)[[:space:]]+(/|\$HOME|~|\*)"
        "(^|[[:space:]])dd[[:space:]]+.*of=/dev/"
        "(^|[[:space:]])mkfs([[:space:]]|$)"
        "(^|[[:space:]])fdisk([[:space:]]|$)"
        "(^|[[:space:]])parted([[:space:]]|$)"
        "(^|[[:space:]])format([[:space:]]|$)"
        "(^|[[:space:]])diskutil[[:space:]]+erase"
        "(^|[[:space:]])shred[[:space:]]"
        "(^|[[:space:]])wipefs([[:space:]]|$)"

        # Privilege escalation
        "(^|[[:space:]])sudo[[:space:]]"
        "(^|[[:space:]])su[[:space:]]+(-|[^[:space:]]*)"
        "(^|[[:space:]])chroot([[:space:]]|$)"
        "(^|[[:space:]])doas[[:space:]]"
        "(^|[[:space:]])runuser[[:space:]]"

        # Package management
        "(^|[[:space:]])brew[[:space:]]+(install|uninstall|remove|cask[[:space:]]+install)"
        "(^|[[:space:]])apt[[:space:]]+install"
        "(^|[[:space:]])apt-get[[:space:]]+(install|remove|purge)"
        "(^|[[:space:]])yum[[:space:]]+(install|remove|erase)"
        "(^|[[:space:]])dnf[[:space:]]+(install|remove|erase)"
        "(^|[[:space:]])pip[[:space:]]+install"
        "(^|[[:space:]])pip3[[:space:]]+install"
        "(^|[[:space:]])npm[[:space:]]+install[[:space:]]+(-g|--global)"
        "(^|[[:space:]])gem[[:space:]]+install"
        "(^|[[:space:]])cargo[[:space:]]+install"

        # System services
        "(^|[[:space:]])systemctl[[:space:]]+(start|stop|restart|enable|disable|mask)"
        "(^|[[:space:]])service[[:space:]]+[^[:space:]]+[[:space:]]+(start|stop|restart)"
        "(^|[[:space:]])launchctl[[:space:]]+(load|unload|start|stop|bootstrap|bootout)"
        "(^|[[:space:]])initctl[[:space:]]"

        # Dangerous file operations (improved patterns)
        "[[:space:]]*:[[:space:]]*>[[:space:]]*/etc/"
        "[[:space:]]*>[[:space:]]*/etc/"
        "[[:space:]]*>>[[:space:]]*/etc/"
        "(^|[[:space:]])tee[[:space:]]+(/etc/|/usr/|/bin/|/sbin/)"
        "(^|[[:space:]])dd[[:space:]]+.*of=/etc/"

        # Process control
        "(^|[[:space:]])kill[[:space:]]+(-9|-KILL)[[:space:]]"
        "(^|[[:space:]])killall([[:space:]]|$)"
        "(^|[[:space:]])pkill([[:space:]]|$)"
        "(^|[[:space:]])xkill([[:space:]]|$)"

        # System modification
        "(^|[[:space:]])crontab[[:space:]]+(-[er]|--edit|--remove)"
        "(^|[[:space:]])at[[:space:]]+[0-9]"
        "(^|[[:space:]])visudo([[:space:]]|$)"
        "(^|[[:space:]])passwd[[:space:]]+[^[:space:]]*"
        "(^|[[:space:]])chpasswd([[:space:]]|$)"
        
        # Kernel and boot
        "(^|[[:space:]])insmod([[:space:]]|$)"
        "(^|[[:space:]])rmmod([[:space:]]|$)"
        "(^|[[:space:]])modprobe[[:space:]]+(-r|--remove)"
        "(^|[[:space:]])kextload([[:space:]]|$)"
        "(^|[[:space:]])kextunload([[:space:]]|$)"
        
        # Network configuration
        "(^|[[:space:]])iptables([[:space:]]|$)"
        "(^|[[:space:]])ip6tables([[:space:]]|$)"
        "(^|[[:space:]])ufw[[:space:]]"
        "(^|[[:space:]])firewall-cmd([[:space:]]|$)"
        "(^|[[:space:]])pfctl([[:space:]]|$)"
    )

    # Special handling for SSH before general pattern matching
    if [[ "$COMMAND" =~ (^|[[:space:]])ssh[[:space:]] ]]; then
        if ! is_ssh_localhost "$COMMAND"; then
            block_command "SSH to external host not allowed" "$COMMAND"
        fi
    fi

    # Check each dangerous pattern
    for pattern in "${DANGEROUS_PATTERNS[@]}"; do
        # Check if pattern matches at start of command or after common separators
        if [[ "$COMMAND" =~ (^|[[:space:];|&])$pattern ]]; then
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

    # Check for download attempts with improved URL parsing
    if [[ "$COMMAND" =~ (^|[[:space:]])(curl|wget|fetch)[[:space:]] ]]; then
        # Allow localhost first
        if [[ "$COMMAND" =~ (localhost|127\.0\.0\.1|::1) ]]; then
            log_command "ALLOWED" "Bash" "$COMMAND (localhost)"
        else
            # Extract and validate URL
            URL=$(extract_and_validate_url "$COMMAND")
            if [[ $? -eq 0 && -n "$URL" ]]; then
                # Extract domain from URL with better parsing
                if [[ "$URL" =~ ^(https?|ftp)://([^/:]+) ]]; then
                    DOMAIN="${BASH_REMATCH[2]}"
                    
                    # Check against allowed domains (using shared list)
                    ALLOWED=false
                    for allowed in "${ALLOWED_DOMAINS[@]}"; do
                        if [[ "$DOMAIN" == *"$allowed" ]]; then
                            ALLOWED=true
                            break
                        fi
                    done
                    
                    if [[ "$ALLOWED" != "true" ]]; then
                        block_command "Network access to non-whitelisted domain: $DOMAIN" "$COMMAND"
                    fi
                    
                    log_command "ALLOWED" "Bash" "$COMMAND (allowed domain: $DOMAIN)"
                else
                    block_command "Invalid URL format in network command" "$COMMAND"
                fi
            else
                # Check if command has network indicators but couldn't parse URL
                if [[ "$COMMAND" =~ (http|https|ftp):// ]]; then
                    block_command "Network access attempted but URL could not be validated" "$COMMAND"
                fi
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

    # Only allow certain domains (using shared list)
    if [[ "$URL" =~ ^(https?|ftp)://([^/:]+) ]]; then
        DOMAIN="${BASH_REMATCH[2]}"
        ALLOWED=false

        for allowed in "${ALLOWED_DOMAINS[@]}"; do
            if [[ "$DOMAIN" == *"$allowed" ]]; then
                ALLOWED=true
                break
            fi
        done

        if [[ "$ALLOWED" != "true" ]]; then
            block_command "WebFetch to non-whitelisted domain: $DOMAIN" "$URL"
        fi
    else
        block_command "WebFetch URL has invalid format" "$URL"
    fi

    log_command "ALLOWED" "WebFetch" "$URL"
fi

# All checks passed
exit 0

