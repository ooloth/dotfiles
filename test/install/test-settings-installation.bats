#!/usr/bin/env bats

# Integration tests for settings installation

setup() {
  # Create temporary directory for each test
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"
  
  # Save original environment
  export ORIGINAL_DOTFILES="${DOTFILES:-}"
  
  # Set up test environment
  export DOTFILES="$TEST_TEMP_DIR/fake_dotfiles"
  
  # Create fake dotfiles structure
  mkdir -p "$DOTFILES/lib"
  mkdir -p "$DOTFILES/bin/lib"
  mkdir -p "$DOTFILES/bin/install"
  
  # Copy utilities
  cp "lib/settings-utils.bash" "$DOTFILES/lib/"
  cp "bin/lib/dry-run-utils.bash" "$DOTFILES/bin/lib/"
}

teardown() {
  # Restore original environment
  if [[ -n "${ORIGINAL_DOTFILES}" ]]; then
    export DOTFILES="$ORIGINAL_DOTFILES"
  else
    unset DOTFILES
  fi
  
  # Clean up temporary directory
  if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

@test "settings installation runs on macOS with required commands" {
  # Create mock script that sources our libraries but mocks the external commands
  cat > "$TEST_TEMP_DIR/test_settings.bash" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Mock external commands
uname() { echo "Darwin"; }
command() {
  if [[ "$1" == "-v" && ("$2" == "defaults" || "$2" == "chflags") ]]; then
    return 0
  else
    /usr/bin/command "$@"
  fi
}
defaults() { echo "Mock defaults: $@"; }
chflags() { echo "Mock chflags: $@"; }
export -f uname command defaults chflags

# Source the actual script content
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$1"

# Source utilities
source "$DOTFILES/lib/settings-utils.bash"
source "$DOTFILES/bin/lib/dry-run-utils.bash"

echo "💻 Configuring macOS system settings"

# Validate environment
if ! validate_macos_environment; then
  exit 1
fi

# Apply settings based on mode
if is_dry_run; then
  echo ""
  echo "[DRY RUN] Would configure the following macOS settings:"
  echo ""
  echo "General Settings:"
  echo "  - Expand save dialog by default"
  echo "  - Enable full keyboard access for all controls"
  echo "  - Enable subpixel font rendering on non-Apple LCDs"
  echo ""
  echo "Finder Settings:"
  echo "  - Show all filename extensions"
  echo "  - Hide hidden files by default"
  echo "  - Use current directory as default search scope"
  echo "  - Show Path bar and Status bar"
  echo "  - Unhide ~/Library folder"
  echo ""
  echo "Safari Settings:"
  echo "  - Enable Safari's debug menu"
else
  # Configure general settings
  if ! configure_general_settings; then
    echo "❌ Failed to configure general settings"
    exit 1
  fi
  
  # Configure Finder settings
  if ! configure_finder_settings; then
    echo "❌ Failed to configure Finder settings"
    exit 1
  fi
  
  # Configure Safari settings
  if ! configure_safari_settings; then
    echo "❌ Failed to configure Safari settings"
    exit 1
  fi
  
  echo ""
  echo "🚀 Done configuring Mac system preferences."
fi
EOF
  chmod +x "$TEST_TEMP_DIR/test_settings.bash"
  
  run bash "$TEST_TEMP_DIR/test_settings.bash" "$DOTFILES"
  [ "$status" -eq 0 ]
  [[ "$output" == *"💻 Configuring macOS system settings"* ]]
  [[ "$output" == *"Configuring general settings..."* ]]
  [[ "$output" == *"🔍 Configuring Finder..."* ]]
  [[ "$output" == *"🌐 Configuring Safari..."* ]]
  [[ "$output" == *"🚀 Done configuring Mac system preferences."* ]]
}

@test "settings installation handles dry run mode" {
  # Create mock script with dry run mode
  cat > "$TEST_TEMP_DIR/test_settings_dry.bash" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Set dry run mode
export DRY_RUN=1

# Mock external commands
uname() { echo "Darwin"; }
command() {
  if [[ "$1" == "-v" && ("$2" == "defaults" || "$2" == "chflags") ]]; then
    return 0
  else
    /usr/bin/command "$@"
  fi
}
defaults() { echo "Mock defaults: $@"; }
chflags() { echo "Mock chflags: $@"; }
export -f uname command defaults chflags

# Source the actual script content
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$1"

# Source utilities
source "$DOTFILES/lib/settings-utils.bash"
source "$DOTFILES/bin/lib/dry-run-utils.bash"

echo "💻 Configuring macOS system settings"

# Validate environment
if ! validate_macos_environment; then
  exit 1
fi

# Apply settings based on mode
if is_dry_run; then
  echo ""
  echo "[DRY RUN] Would configure the following macOS settings:"
  echo ""
  echo "General Settings:"
  echo "  - Expand save dialog by default"
  echo "  - Enable full keyboard access for all controls"
  echo "  - Enable subpixel font rendering on non-Apple LCDs"
  echo ""
  echo "Finder Settings:"
  echo "  - Show all filename extensions"
  echo "  - Hide hidden files by default"
  echo "  - Use current directory as default search scope"
  echo "  - Show Path bar and Status bar"
  echo "  - Unhide ~/Library folder"
  echo ""
  echo "Safari Settings:"
  echo "  - Enable Safari's debug menu"
else
  # Configure general settings
  if ! configure_general_settings; then
    echo "❌ Failed to configure general settings"
    exit 1
  fi
  
  # Configure Finder settings
  if ! configure_finder_settings; then
    echo "❌ Failed to configure Finder settings"
    exit 1
  fi
  
  # Configure Safari settings
  if ! configure_safari_settings; then
    echo "❌ Failed to configure Safari settings"
    exit 1
  fi
  
  echo ""
  echo "🚀 Done configuring Mac system preferences."
fi
EOF
  chmod +x "$TEST_TEMP_DIR/test_settings_dry.bash"
  
  run bash "$TEST_TEMP_DIR/test_settings_dry.bash" "$DOTFILES"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[DRY RUN] Would configure the following macOS settings:"* ]]
  [[ "$output" == *"General Settings:"* ]]
  [[ "$output" == *"Finder Settings:"* ]]
  [[ "$output" == *"Safari Settings:"* ]]
  
  # Verify no actual configuration was attempted
  [[ "$output" != *"Configuring general settings..."* ]]
}

@test "settings installation fails on non-macOS systems" {
  # Create mock script for non-macOS
  cat > "$TEST_TEMP_DIR/test_settings_linux.bash" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Mock uname to return non-Darwin
uname() { echo "Linux"; }
export -f uname

# Source the actual script content
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$1"

# Source utilities
source "$DOTFILES/lib/settings-utils.bash"
source "$DOTFILES/bin/lib/dry-run-utils.bash"

echo "💻 Configuring macOS system settings"

# Validate environment
if ! validate_macos_environment; then
  exit 1
fi
EOF
  chmod +x "$TEST_TEMP_DIR/test_settings_linux.bash"
  
  run bash "$TEST_TEMP_DIR/test_settings_linux.bash" "$DOTFILES"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ macOS system settings can only be applied on macOS"* ]]
}

@test "settings installation fails when defaults command unavailable" {
  # Create mock script for missing defaults
  cat > "$TEST_TEMP_DIR/test_settings_no_defaults.bash" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Mock macOS but missing defaults command
uname() { echo "Darwin"; }
command() {
  if [[ "$1" == "-v" && "$2" == "defaults" ]]; then
    return 1
  elif [[ "$1" == "-v" && "$2" == "chflags" ]]; then
    return 0
  else
    /usr/bin/command "$@"
  fi
}
export -f uname command

# Source the actual script content
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$1"

# Source utilities
source "$DOTFILES/lib/settings-utils.bash"
source "$DOTFILES/bin/lib/dry-run-utils.bash"

echo "💻 Configuring macOS system settings"

# Validate environment
if ! validate_macos_environment; then
  exit 1
fi
EOF
  chmod +x "$TEST_TEMP_DIR/test_settings_no_defaults.bash"
  
  run bash "$TEST_TEMP_DIR/test_settings_no_defaults.bash" "$DOTFILES"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ defaults command not available"* ]]
}

@test "settings installation fails when chflags command unavailable" {
  # Create mock script for missing chflags
  cat > "$TEST_TEMP_DIR/test_settings_no_chflags.bash" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Mock macOS but missing chflags command
uname() { echo "Darwin"; }
command() {
  if [[ "$1" == "-v" && "$2" == "defaults" ]]; then
    return 0
  elif [[ "$1" == "-v" && "$2" == "chflags" ]]; then
    return 1
  else
    /usr/bin/command "$@"
  fi
}
export -f uname command

# Source the actual script content
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$1"

# Source utilities
source "$DOTFILES/lib/settings-utils.bash"
source "$DOTFILES/bin/lib/dry-run-utils.bash"

echo "💻 Configuring macOS system settings"

# Validate environment
if ! validate_macos_environment; then
  exit 1
fi
EOF
  chmod +x "$TEST_TEMP_DIR/test_settings_no_chflags.bash"
  
  run bash "$TEST_TEMP_DIR/test_settings_no_chflags.bash" "$DOTFILES"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ chflags command not available"* ]]
}

@test "settings installation handles general settings failure" {
  # Create mock script with failing general settings
  cat > "$TEST_TEMP_DIR/test_settings_fail_general.bash" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Mock external commands
uname() { echo "Darwin"; }
command() {
  if [[ "$1" == "-v" && ("$2" == "defaults" || "$2" == "chflags") ]]; then
    return 0
  else
    /usr/bin/command "$@"
  fi
}
defaults() {
  # Make defaults fail for general settings
  if [[ "$2" == "NSNavPanelExpandedStateForSaveMode" || "$2" == "AppleKeyboardUIMode" || "$2" == "AppleFontSmoothing" ]]; then
    return 1
  fi
  echo "Mock defaults: $@"
}
chflags() { echo "Mock chflags: $@"; }
export -f uname command defaults chflags

# Source the actual script content
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$1"

# Source utilities
source "$DOTFILES/lib/settings-utils.bash"
source "$DOTFILES/bin/lib/dry-run-utils.bash"

echo "💻 Configuring macOS system settings"

# Validate environment
if ! validate_macos_environment; then
  exit 1
fi

# Configure general settings
if ! configure_general_settings; then
  echo "❌ Failed to configure general settings"
  exit 1
fi
EOF
  chmod +x "$TEST_TEMP_DIR/test_settings_fail_general.bash"
  
  run bash "$TEST_TEMP_DIR/test_settings_fail_general.bash" "$DOTFILES"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Failed to configure general settings"* ]]
}

@test "settings installation handles finder settings failure" {
  # Create mock script with failing finder settings
  cat > "$TEST_TEMP_DIR/test_settings_fail_finder.bash" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Mock external commands
uname() { echo "Darwin"; }
command() {
  if [[ "$1" == "-v" && ("$2" == "defaults" || "$2" == "chflags") ]]; then
    return 0
  else
    /usr/bin/command "$@"
  fi
}
defaults() {
  # Make defaults fail for Finder settings
  if [[ "$1" == "NSGlobalDomain" && "$2" == "AppleShowAllExtensions" ]]; then
    return 1
  fi
  echo "Mock defaults: $@"
}
chflags() { echo "Mock chflags: $@"; }
export -f uname command defaults chflags

# Source the actual script content
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$1"

# Source utilities
source "$DOTFILES/lib/settings-utils.bash"
source "$DOTFILES/bin/lib/dry-run-utils.bash"

echo "💻 Configuring macOS system settings"

# Validate environment
if ! validate_macos_environment; then
  exit 1
fi

# Configure general settings (should succeed)
if ! configure_general_settings; then
  echo "❌ Failed to configure general settings"
  exit 1
fi

# Configure Finder settings (should fail)
if ! configure_finder_settings; then
  echo "❌ Failed to configure Finder settings"
  exit 1
fi
EOF
  chmod +x "$TEST_TEMP_DIR/test_settings_fail_finder.bash"
  
  run bash "$TEST_TEMP_DIR/test_settings_fail_finder.bash" "$DOTFILES"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Failed to configure Finder settings"* ]]
}

@test "settings installation handles safari settings failure" {
  # Create mock script with failing safari settings
  cat > "$TEST_TEMP_DIR/test_settings_fail_safari.bash" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Mock external commands
uname() { echo "Darwin"; }
command() {
  if [[ "$1" == "-v" && ("$2" == "defaults" || "$2" == "chflags") ]]; then
    return 0
  else
    /usr/bin/command "$@"
  fi
}
defaults() {
  # Make defaults fail for Safari settings
  if [[ "$1" == "com.apple.Safari" && "$2" == "IncludeInternalDebugMenu" ]]; then
    return 1
  fi
  echo "Mock defaults: $@"
}
chflags() { echo "Mock chflags: $@"; }
export -f uname command defaults chflags

# Source the actual script content
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$1"

# Source utilities
source "$DOTFILES/lib/settings-utils.bash"
source "$DOTFILES/bin/lib/dry-run-utils.bash"

echo "💻 Configuring macOS system settings"

# Validate environment
if ! validate_macos_environment; then
  exit 1
fi

# Configure general settings (should succeed)
if ! configure_general_settings; then
  echo "❌ Failed to configure general settings"
  exit 1
fi

# Configure Finder settings (should succeed)
if ! configure_finder_settings; then
  echo "❌ Failed to configure Finder settings"
  exit 1
fi

# Configure Safari settings (should fail)
if ! configure_safari_settings; then
  echo "❌ Failed to configure Safari settings"
  exit 1
fi
EOF
  chmod +x "$TEST_TEMP_DIR/test_settings_fail_safari.bash"
  
  run bash "$TEST_TEMP_DIR/test_settings_fail_safari.bash" "$DOTFILES"
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Failed to configure Safari settings"* ]]
}