#!/usr/bin/env bats

# Test suite for macos-utils.bash

# Load the macos utilities
load "../../lib/macos-utils.bash"

setup() {
  # Create temporary directory for each test
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"
}

teardown() {
  # Clean up temporary directory
  if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# Test is_macos
@test "is_macos returns true on Darwin system" {
  # Mock uname to return Darwin
  uname() {
    echo "Darwin"
  }
  
  run is_macos
  [ "$status" -eq 0 ]
}

@test "is_macos returns false on non-Darwin system" {
  # Mock uname to return Linux
  uname() {
    echo "Linux"
  }
  
  run is_macos
  [ "$status" -ne 0 ]
}

# Test is_softwareupdate_available
@test "is_softwareupdate_available returns true when command exists" {
  # Mock command to simulate softwareupdate being available
  command() {
    if [[ "$1" == "-v" && "$2" == "softwareupdate" ]]; then
      return 0
    else
      command "$@"
    fi
  }
  
  run is_softwareupdate_available
  [ "$status" -eq 0 ]
}

@test "is_softwareupdate_available returns false when command missing" {
  # Mock command to simulate softwareupdate being unavailable
  command() {
    if [[ "$1" == "-v" && "$2" == "softwareupdate" ]]; then
      return 1
    else
      command "$@"
    fi
  }
  
  run is_softwareupdate_available
  [ "$status" -ne 0 ]
}

# Test is_system_profiler_available
@test "is_system_profiler_available returns true when command exists" {
  # Mock command to simulate system_profiler being available
  command() {
    if [[ "$1" == "-v" && "$2" == "system_profiler" ]]; then
      return 0
    else
      command "$@"
    fi
  }
  
  run is_system_profiler_available
  [ "$status" -eq 0 ]
}

@test "is_system_profiler_available returns false when command missing" {
  # Mock command to simulate system_profiler being unavailable
  command() {
    if [[ "$1" == "-v" && "$2" == "system_profiler" ]]; then
      return 1
    else
      command "$@"
    fi
  }
  
  run is_system_profiler_available
  [ "$status" -ne 0 ]
}

# Test get_macos_version
@test "get_macos_version returns version when available" {
  # Mock dependencies
  is_macos() { return 0; }
  is_system_profiler_available() { return 0; }
  
  # Mock system_profiler
  system_profiler() {
    echo "Software:"
    echo "    System Version: macOS 14.1 (23B74)"
  }
  
  run get_macos_version
  [ "$status" -eq 0 ]
  [[ "$output" == *"14.1"* ]]
}

@test "get_macos_version returns unknown when not on macOS" {
  # Mock is_macos to return false
  is_macos() { return 1; }
  is_system_profiler_available() { return 0; }
  
  run get_macos_version
  [ "$status" -eq 0 ]
  [ "$output" = "unknown" ]
}

# Test get_macos_build
@test "get_macos_build returns build number when available" {
  # Mock dependencies
  is_macos() { return 0; }
  is_system_profiler_available() { return 0; }
  
  # Mock system_profiler
  system_profiler() {
    echo "Software:"
    echo "    System Version: macOS 14.1 (23B74)"
  }
  
  run get_macos_build
  [ "$status" -eq 0 ]
  [ "$output" = "23B74" ]
}

# Test check_software_updates
@test "check_software_updates runs softwareupdate list" {
  # Mock is_softwareupdate_available
  is_softwareupdate_available() { return 0; }
  
  # Mock softwareupdate command
  softwareupdate() {
    if [[ "$1" == "--list" ]]; then
      echo "Software Update Tool"
      echo "No new software available."
    else
      command softwareupdate "$@"
    fi
  }
  
  run check_software_updates
  [ "$status" -eq 0 ]
  [[ "$output" == *"🔍 Checking for macOS software updates..."* ]]
  [[ "$output" == *"No new software available."* ]]
}

@test "check_software_updates fails when softwareupdate unavailable" {
  # Mock is_softwareupdate_available to return false
  is_softwareupdate_available() { return 1; }
  
  run check_software_updates
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ softwareupdate command not available"* ]]
}

# Test install_software_updates
@test "install_software_updates runs softwareupdate with restart by default" {
  # Mock is_softwareupdate_available
  is_softwareupdate_available() { return 0; }
  
  # Mock sudo and softwareupdate
  sudo() {
    if [[ "$1" == "softwareupdate" ]]; then
      echo "SUDO_SOFTWAREUPDATE: $*"
      return 0
    else
      command sudo "$@"
    fi
  }
  
  run install_software_updates
  [ "$status" -eq 0 ]
  [[ "$output" == *"📦 Installing macOS software updates..."* ]]
  [[ "$output" == *"⚠️  System may restart automatically"* ]]
  [[ "$output" == *"SUDO_SOFTWAREUPDATE: softwareupdate --install --all --agree-to-license --verbose --restart"* ]]
}

@test "install_software_updates runs without restart when specified" {
  # Mock is_softwareupdate_available
  is_softwareupdate_available() { return 0; }
  
  # Mock sudo and softwareupdate
  sudo() {
    if [[ "$1" == "softwareupdate" ]]; then
      echo "SUDO_SOFTWAREUPDATE: $*"
      return 0
    else
      command sudo "$@"
    fi
  }
  
  run install_software_updates "false"
  [ "$status" -eq 0 ]
  [[ "$output" == *"SUDO_SOFTWAREUPDATE:"* ]]
  [[ "$output" != *"--restart"* ]]
}

@test "install_software_updates handles softwareupdate failure" {
  # Mock is_softwareupdate_available
  is_softwareupdate_available() { return 0; }
  
  # Mock sudo to fail
  sudo() {
    return 1
  }
  
  run install_software_updates
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ Failed to install software updates"* ]]
}

# Test needs_restart_for_updates
@test "needs_restart_for_updates returns true when restart required" {
  # Mock is_softwareupdate_available
  is_softwareupdate_available() { return 0; }
  
  # Mock softwareupdate to show restart-required updates
  softwareupdate() {
    echo "macOS Update 14.1.1"
    echo "   restart required"
  }
  
  run needs_restart_for_updates
  [ "$status" -eq 0 ]
}

@test "needs_restart_for_updates returns false when no restart required" {
  # Mock is_softwareupdate_available
  is_softwareupdate_available() { return 0; }
  
  # Mock softwareupdate to show no restart-required updates
  softwareupdate() {
    echo "No new software available."
  }
  
  run needs_restart_for_updates
  [ "$status" -ne 0 ]
}

# Test get_system_uptime
@test "get_system_uptime returns uptime on macOS" {
  # Mock is_macos
  is_macos() { return 0; }
  
  # Mock uptime command
  uptime() {
    echo "10:30  up 2 days, 14:25, 3 users, load averages: 1.25 1.15 1.10"
  }
  
  run get_system_uptime
  [ "$status" -eq 0 ]
  [[ "$output" == *"2 days"* ]]
}

@test "get_system_uptime returns unknown when not on macOS" {
  # Mock is_macos to return false
  is_macos() { return 1; }
  
  run get_system_uptime
  [ "$status" -eq 0 ]
  [ "$output" = "unknown" ]
}

# Test is_work_machine
@test "is_work_machine returns true when IS_WORK is true" {
  export IS_WORK=true
  
  run is_work_machine
  [ "$status" -eq 0 ]
}

@test "is_work_machine returns false when IS_WORK is false" {
  export IS_WORK=false
  
  run is_work_machine
  [ "$status" -ne 0 ]
}

@test "is_work_machine returns false when IS_WORK is unset" {
  unset IS_WORK
  
  run is_work_machine
  [ "$status" -ne 0 ]
}

# Test validate_macos_update_environment
@test "validate_macos_update_environment succeeds when all requirements met" {
  # Mock all requirements to succeed
  is_macos() { return 0; }
  is_softwareupdate_available() { return 0; }
  is_work_machine() { return 1; }
  
  run validate_macos_update_environment
  [ "$status" -eq 0 ]
}

@test "validate_macos_update_environment fails when not on macOS" {
  # Mock not on macOS
  is_macos() { return 1; }
  is_softwareupdate_available() { return 0; }
  is_work_machine() { return 1; }
  
  run validate_macos_update_environment
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ macOS system updates can only be performed on macOS"* ]]
}

@test "validate_macos_update_environment fails when softwareupdate unavailable" {
  # Mock softwareupdate unavailable
  is_macos() { return 0; }
  is_softwareupdate_available() { return 1; }
  is_work_machine() { return 1; }
  
  run validate_macos_update_environment
  [ "$status" -ne 0 ]
  [[ "$output" == *"❌ softwareupdate command not available"* ]]
}

@test "validate_macos_update_environment skips on work machine" {
  # Mock work machine
  is_macos() { return 0; }
  is_softwareupdate_available() { return 0; }
  is_work_machine() { return 0; }
  
  run validate_macos_update_environment
  [ "$status" -eq 2 ]
  [[ "$output" == *"⏭️  Skipping macOS updates on work machine"* ]]
}

# Test get_system_info
@test "get_system_info displays system information on macOS" {
  # Mock dependencies
  is_macos() { return 0; }
  get_macos_version() { echo "14.1"; }
  get_macos_build() { echo "23B74"; }
  get_system_uptime() { echo "2 days"; }
  
  run get_system_info
  [ "$status" -eq 0 ]
  [[ "$output" == *"System: macOS 14.1"* ]]
  [[ "$output" == *"Build: 23B74"* ]]
  [[ "$output" == *"Uptime: 2 days"* ]]
}

@test "get_system_info handles non-macOS systems" {
  # Mock not on macOS
  is_macos() { return 1; }
  
  run get_system_info
  [ "$status" -eq 0 ]
  [[ "$output" == *"System: Non-macOS"* ]]
}

# Test has_admin_privileges
@test "has_admin_privileges returns true when user in admin group" {
  # Mock groups command
  groups() {
    echo "staff admin wheel"
  }
  
  run has_admin_privileges
  [ "$status" -eq 0 ]
}

@test "has_admin_privileges returns false when user not in admin group" {
  # Mock groups command
  groups() {
    echo "staff wheel"
  }
  
  run has_admin_privileges
  [ "$status" -ne 0 ]
}

# Test warn_about_restart
@test "warn_about_restart displays warning message" {
  run warn_about_restart
  [ "$status" -eq 0 ]
  [[ "$output" == *"⚠️  WARNING: macOS software updates may restart your system"* ]]
  [[ "$output" == *"📋 Save your work and close important applications"* ]]
}

# Test is_supported_macos_version
@test "is_supported_macos_version returns true for supported version" {
  # Mock dependencies
  is_macos() { return 0; }
  
  # Mock sw_vers
  sw_vers() {
    if [[ "$1" == "-productVersion" ]]; then
      echo "14.1"
    fi
  }
  
  run is_supported_macos_version "10.14"
  [ "$status" -eq 0 ]
}

@test "is_supported_macos_version returns false for unsupported version" {
  # Mock dependencies
  is_macos() { return 0; }
  
  # Mock sw_vers to return old version
  sw_vers() {
    if [[ "$1" == "-productVersion" ]]; then
      echo "10.13"
    fi
  }
  
  run is_supported_macos_version "10.14"
  [ "$status" -ne 0 ]
}

@test "is_supported_macos_version returns false when not on macOS" {
  # Mock not on macOS
  is_macos() { return 1; }
  
  run is_supported_macos_version
  [ "$status" -ne 0 ]
}