#!/bin/bash

# Test runner script for Badgetizr
# This script installs bats-core if needed and runs all tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$SCRIPT_DIR/tests"

echo "🧪 Badgetizr Test Runner"
echo "========================"
echo ""

# Check if bats is installed
if ! command -v bats &> /dev/null; then
    echo "⚠️  bats-core is not installed"
    echo ""
    echo "Install it using one of these methods:"
    echo "  - Homebrew: brew install bats-core"
    echo "  - npm: npm install -g bats"
    echo "  - From source: https://github.com/bats-core/bats-core#installation"
    echo ""
    exit 1
fi

BATS_VERSION=$(bats --version 2>&1 | head -n 1)
echo "✅ Found: $BATS_VERSION"
echo ""

# Check for optional bats libraries
if command -v brew &> /dev/null; then
    if brew list bats-support &> /dev/null 2>&1; then
        echo "✅ bats-support is installed"
    else
        echo "ℹ️  bats-support is not installed (optional)"
        echo "   Install with: brew install bats-support"
    fi

    if brew list bats-assert &> /dev/null 2>&1; then
        echo "✅ bats-assert is installed"
    else
        echo "ℹ️  bats-assert is not installed (optional)"
        echo "   Install with: brew install bats-assert"
    fi
    echo ""
fi

# Run tests
echo "🏃 Running tests..."
echo ""

if [ $# -eq 0 ]; then
    # Run all tests
    bats "$TESTS_DIR"
else
    # Run specific test file(s)
    bats "$@"
fi

TEST_EXIT_CODE=$?

echo ""
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "✅ All tests passed!"
else
    echo "❌ Some tests failed (exit code: $TEST_EXIT_CODE)"
fi

exit $TEST_EXIT_CODE
