#!/usr/bin/env bash

# Setup for all test suites
setup_suite() {
    # Load bats support libraries if available
    if [ -f "/usr/local/lib/bats-support/load.bash" ]; then
        load '/usr/local/lib/bats-support/load.bash'
    fi

    if [ -f "/usr/local/lib/bats-assert/load.bash" ]; then
        load '/usr/local/lib/bats-assert/load.bash'
    fi

    # Set up test environment
    export BATS_TEST_DIRNAME="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
    export PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." >/dev/null 2>&1 && pwd)"

    # Add project root to PATH for testing
    export PATH="$PROJECT_ROOT:$PATH"
}
