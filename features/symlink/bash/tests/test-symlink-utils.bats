#!/usr/bin/env bats

# Symlink utilities tests (bash version)
# Tests the bash version of symlink management functionality

# Load the symlink utilities
load "../utils.bash"
load "../../../common/testing.bash"

setup() {
    # Create temporary directory for each test
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"

    # Create test source and target directories
    export TEST_SOURCE_DIR="$TEST_TEMP_DIR/source"
    export TEST_TARGET_DIR="$TEST_TEMP_DIR/target"
    mkdir -p "$TEST_SOURCE_DIR" "$TEST_TARGET_DIR"

    # Save original HOME for restoration
    export ORIGINAL_HOME="$HOME"
}

teardown() {
    # Restore original environment
    export HOME="$ORIGINAL_HOME"

    # Clean up temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Unit Tests for maybe_symlink function

@test "maybe_symlink creates symlink when target does not exist" {
    # Create source file
    echo "test content" >"$TEST_SOURCE_DIR/test.txt"

    run maybe_symlink "$TEST_SOURCE_DIR/test.txt" "$TEST_TARGET_DIR"
    [ "$status" -eq 0 ]

    # Verify symlink was created
    [ -L "$TEST_TARGET_DIR/test.txt" ]
    [ "$(readlink "$TEST_TARGET_DIR/test.txt")" = "$TEST_SOURCE_DIR/test.txt" ]
}

@test "maybe_symlink does nothing when correct symlink already exists" {
    # Create source file and existing correct symlink
    echo "test content" >"$TEST_SOURCE_DIR/existing.txt"
    ln -s "$TEST_SOURCE_DIR/existing.txt" "$TEST_TARGET_DIR/existing.txt"

    run maybe_symlink "$TEST_SOURCE_DIR/existing.txt" "$TEST_TARGET_DIR"
    [ "$status" -eq 0 ]

    # Verify symlink still exists and is correct
    [ -L "$TEST_TARGET_DIR/existing.txt" ]
    [ "$(readlink "$TEST_TARGET_DIR/existing.txt")" = "$TEST_SOURCE_DIR/existing.txt" ]
}

@test "maybe_symlink replaces incorrect symlink" {
    # Create source files
    echo "old content" >"$TEST_SOURCE_DIR/old.txt"
    echo "new content" >"$TEST_SOURCE_DIR/new.txt"

    # Create symlink pointing to wrong target
    ln -s "$TEST_SOURCE_DIR/old.txt" "$TEST_TARGET_DIR/new.txt"

    run maybe_symlink "$TEST_SOURCE_DIR/new.txt" "$TEST_TARGET_DIR"
    [ "$status" -eq 0 ]

    # Verify symlink now points to correct target
    [ -L "$TEST_TARGET_DIR/new.txt" ]
    [ "$(readlink "$TEST_TARGET_DIR/new.txt")" = "$TEST_SOURCE_DIR/new.txt" ]
}

@test "maybe_symlink replaces regular file with symlink" {
    # Create source file and regular file at target
    echo "source content" >"$TEST_SOURCE_DIR/replace.txt"
    echo "target content" >"$TEST_TARGET_DIR/replace.txt"

    run maybe_symlink "$TEST_SOURCE_DIR/replace.txt" "$TEST_TARGET_DIR"
    [ "$status" -eq 0 ]

    # Verify regular file was replaced with symlink
    [ -L "$TEST_TARGET_DIR/replace.txt" ]
    [ "$(readlink "$TEST_TARGET_DIR/replace.txt")" = "$TEST_SOURCE_DIR/replace.txt" ]
}

@test "maybe_symlink creates target directory when it does not exist" {
    # Create source file
    echo "test content" >"$TEST_SOURCE_DIR/test.txt"

    # Use non-existent target directory
    local new_target="$TEST_TEMP_DIR/new_target"

    run maybe_symlink "$TEST_SOURCE_DIR/test.txt" "$new_target"
    [ "$status" -eq 0 ]

    # Verify directory was created and symlink exists
    [ -d "$new_target" ]
    [ -L "$new_target/test.txt" ]
    [ "$(readlink "$new_target/test.txt")" = "$TEST_SOURCE_DIR/test.txt" ]
}

@test "maybe_symlink fails when source file does not exist" {
    run maybe_symlink "$TEST_SOURCE_DIR/nonexistent.txt" "$TEST_TARGET_DIR"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Source file does not exist"* ]]
}

@test "maybe_symlink fails when no arguments provided" {
    run maybe_symlink
    [ "$status" -eq 1 ]
    [[ "$output" == *"Source file path is required"* ]]
}

@test "maybe_symlink fails when only source provided" {
    echo "test" >"$TEST_SOURCE_DIR/test.txt"

    run maybe_symlink "$TEST_SOURCE_DIR/test.txt"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Target directory path is required"* ]]
}

# Unit Tests for remove_broken_symlinks function

@test "remove_broken_symlinks removes symlinks pointing to non-existent files" {
    # Create symlink pointing to non-existent file
    ln -s "$TEST_SOURCE_DIR/nonexistent.txt" "$TEST_TARGET_DIR/broken.txt"

    run remove_broken_symlinks "$TEST_TARGET_DIR"
    [ "$status" -eq 0 ]

    # Verify broken symlink was removed
    [ ! -e "$TEST_TARGET_DIR/broken.txt" ]
}

@test "remove_broken_symlinks keeps valid symlinks" {
    # Create source file and valid symlink
    echo "content" >"$TEST_SOURCE_DIR/valid.txt"
    ln -s "$TEST_SOURCE_DIR/valid.txt" "$TEST_TARGET_DIR/valid.txt"

    run remove_broken_symlinks "$TEST_TARGET_DIR"
    [ "$status" -eq 0 ]

    # Verify valid symlink still exists
    [ -L "$TEST_TARGET_DIR/valid.txt" ]
    [ -e "$TEST_TARGET_DIR/valid.txt" ]
}

@test "remove_broken_symlinks keeps regular files" {
    # Create regular file
    echo "content" >"$TEST_TARGET_DIR/regular.txt"

    run remove_broken_symlinks "$TEST_TARGET_DIR"
    [ "$status" -eq 0 ]

    # Verify regular file still exists
    [ -f "$TEST_TARGET_DIR/regular.txt" ]
    [ ! -L "$TEST_TARGET_DIR/regular.txt" ]
}

@test "remove_broken_symlinks handles non-existent directory gracefully" {
    run remove_broken_symlinks "$TEST_TEMP_DIR/nonexistent"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Directory does not exist"* ]]
}

@test "remove_broken_symlinks requires directory argument" {
    run remove_broken_symlinks
    [ "$status" -eq 1 ]
    [[ "$output" == *"Directory path is required"* ]]
}

# Unit Tests for is_symlink_correct function

@test "is_symlink_correct returns 0 for correct symlink" {
    # Create source file and correct symlink
    echo "content" >"$TEST_SOURCE_DIR/correct.txt"
    ln -s "$TEST_SOURCE_DIR/correct.txt" "$TEST_TARGET_DIR/correct.txt"

    run is_symlink_correct "$TEST_TARGET_DIR/correct.txt" "$TEST_SOURCE_DIR/correct.txt"
    [ "$status" -eq 0 ]
}

@test "is_symlink_correct returns 1 for incorrect symlink" {
    # Create source files and incorrect symlink
    echo "content1" >"$TEST_SOURCE_DIR/file1.txt"
    echo "content2" >"$TEST_SOURCE_DIR/file2.txt"
    ln -s "$TEST_SOURCE_DIR/file1.txt" "$TEST_TARGET_DIR/link.txt"

    run is_symlink_correct "$TEST_TARGET_DIR/link.txt" "$TEST_SOURCE_DIR/file2.txt"
    [ "$status" -eq 1 ]
}

@test "is_symlink_correct returns 1 for non-existent symlink" {
    run is_symlink_correct "$TEST_TARGET_DIR/nonexistent.txt" "$TEST_SOURCE_DIR/any.txt"
    [ "$status" -eq 1 ]
}

@test "is_symlink_correct returns 1 for regular file" {
    # Create regular file
    echo "content" >"$TEST_TARGET_DIR/regular.txt"

    run is_symlink_correct "$TEST_TARGET_DIR/regular.txt" "$TEST_SOURCE_DIR/any.txt"
    [ "$status" -eq 1 ]
}

# Integration Tests

@test "symlink workflow: create multiple symlinks" {
    # Create multiple source files
    echo "file1" >"$TEST_SOURCE_DIR/file1.txt"
    echo "file2" >"$TEST_SOURCE_DIR/file2.txt"
    echo "file3" >"$TEST_SOURCE_DIR/file3.txt"

    # Create symlinks
    run maybe_symlink "$TEST_SOURCE_DIR/file1.txt" "$TEST_TARGET_DIR"
    [ "$status" -eq 0 ]

    run maybe_symlink "$TEST_SOURCE_DIR/file2.txt" "$TEST_TARGET_DIR"
    [ "$status" -eq 0 ]

    run maybe_symlink "$TEST_SOURCE_DIR/file3.txt" "$TEST_TARGET_DIR"
    [ "$status" -eq 0 ]

    # Verify all symlinks created correctly
    [ -L "$TEST_TARGET_DIR/file1.txt" ]
    [ -L "$TEST_TARGET_DIR/file2.txt" ]
    [ -L "$TEST_TARGET_DIR/file3.txt" ]

    # Verify symlinks point to correct targets
    [ "$(readlink "$TEST_TARGET_DIR/file1.txt")" = "$TEST_SOURCE_DIR/file1.txt" ]
    [ "$(readlink "$TEST_TARGET_DIR/file2.txt")" = "$TEST_SOURCE_DIR/file2.txt" ]
    [ "$(readlink "$TEST_TARGET_DIR/file3.txt")" = "$TEST_SOURCE_DIR/file3.txt" ]
}

@test "symlink workflow: cleanup broken symlinks then create new ones" {
    # Create broken symlinks
    ln -s "$TEST_SOURCE_DIR/missing1.txt" "$TEST_TARGET_DIR/broken1.txt"
    ln -s "$TEST_SOURCE_DIR/missing2.txt" "$TEST_TARGET_DIR/broken2.txt"

    # Create valid symlink
    echo "valid" >"$TEST_SOURCE_DIR/valid.txt"
    ln -s "$TEST_SOURCE_DIR/valid.txt" "$TEST_TARGET_DIR/valid.txt"

    # Cleanup broken symlinks
    run remove_broken_symlinks "$TEST_TARGET_DIR"
    [ "$status" -eq 0 ]

    # Verify broken symlinks removed, valid one kept
    [ ! -e "$TEST_TARGET_DIR/broken1.txt" ]
    [ ! -e "$TEST_TARGET_DIR/broken2.txt" ]
    [ -L "$TEST_TARGET_DIR/valid.txt" ]

    # Create new symlinks
    echo "new content" >"$TEST_SOURCE_DIR/new.txt"
    run maybe_symlink "$TEST_SOURCE_DIR/new.txt" "$TEST_TARGET_DIR"
    [ "$status" -eq 0 ]

    # Verify new symlink created
    [ -L "$TEST_TARGET_DIR/new.txt" ]
    [ "$(readlink "$TEST_TARGET_DIR/new.txt")" = "$TEST_SOURCE_DIR/new.txt" ]
}
