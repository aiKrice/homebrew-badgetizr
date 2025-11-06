#!/usr/bin/env bash

# Setup for all test suites
setup_suite() {
    # Load bats support libraries if available
    # Try multiple common installation paths
    local bats_support_paths=(
        "/usr/local/lib/bats-support/load.bash"
        "/usr/lib/bats-support/load.bash"
        "${HOME}/.bats/bats-support/load.bash"
        "/opt/homebrew/lib/bats-support/load.bash"
    )

    for path in "${bats_support_paths[@]}"; do
        if [ -f "$path" ]; then
            load "$path"
            break
        fi
    done

    local bats_assert_paths=(
        "/usr/local/lib/bats-assert/load.bash"
        "/usr/lib/bats-assert/load.bash"
        "${HOME}/.bats/bats-assert/load.bash"
        "/opt/homebrew/lib/bats-assert/load.bash"
    )

    for path in "${bats_assert_paths[@]}"; do
        if [ -f "$path" ]; then
            load "$path"
            break
        fi
    done

    # Set up test environment
    export BATS_TEST_DIRNAME="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
    export PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." >/dev/null 2>&1 && pwd)"

    # Add project root to PATH for testing
    export PATH="$PROJECT_ROOT:$PATH"
}
