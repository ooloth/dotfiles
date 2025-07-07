#!/usr/bin/env bash

# Example with common bash mistakes to show shellcheck value

check_file() {
    if [ -f $1 ]; then  # Missing quotes - shellcheck will catch this
        echo "File exists: $1"
    fi
    
    # Unused variable - shellcheck will catch this
    unused_var="this is never used"
    
    # Variable used before set - shellcheck will catch this
    echo $undefined_var
}