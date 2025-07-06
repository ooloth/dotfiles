#!/usr/bin/env zsh

# Machine detection utilities for dotfiles setup
# Dynamically detects machine type based on hostname patterns

# Detect machine type based on hostname
detect_machine_type() {
    # Check for environment variable override first
    if [[ -n "$MACHINE" ]]; then
        echo "$MACHINE"
        return 0
    fi
    
    # Get hostname for detection
    local hostname
    if command -v hostname >/dev/null 2>&1; then
        hostname=$(hostname)
    else
        # Fallback if hostname command is not available
        hostname="${HOST:-unknown}"
    fi
    
    # Pattern matching for machine types
    case "$hostname" in
        *Air*)
            echo "air"
            ;;
        *Mini*)
            echo "mini"
            ;;
        *)
            # Default to work for unknown hostnames
            echo "work"
            ;;
    esac
}

# Set machine-specific environment variables based on detected type
set_machine_variables() {
    local machine_type="$1"
    
    # Reset all machine variables
    export IS_AIR=false
    export IS_MINI=false
    export IS_WORK=false
    
    # Set the appropriate variable based on machine type
    case "$machine_type" in
        "air")
            export IS_AIR=true
            export MACHINE="air"
            ;;
        "mini")
            export IS_MINI=true
            export MACHINE="mini"
            ;;
        *)
            # Default to work for unknown types (including explicit "work")
            export IS_WORK=true
            export MACHINE="work"
            ;;
    esac
}

# Initialize machine detection and set variables
init_machine_detection() {
    local detected_type=$(detect_machine_type)
    set_machine_variables "$detected_type"
    
    # Optional: print detection result for debugging
    if [[ "${DEBUG_MACHINE_DETECTION:-false}" == "true" ]]; then
        echo "Detected machine type: $MACHINE" >&2
    fi
}

# Export functions for use in other scripts
# Note: Only export functions, not variables, to avoid pollution