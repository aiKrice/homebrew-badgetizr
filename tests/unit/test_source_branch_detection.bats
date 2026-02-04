#!/usr/bin/env bats
# Unit tests for detect_source_branch function (simplified logic)

setup() {
    export BASE_PATH="${BATS_TEST_DIRNAME}/../.."
    export PROJECT_ROOT="${BASE_PATH}"

    # Source the main script to get the detect_source_branch function
    # We need to define helper functions that badgetizr expects
    show_help() { :; }
    export -f show_help

    # Mock utils.sh functions if needed
    BADGETIZR_VERSION="test"
    export BADGETIZR_VERSION
}

teardown() {
    unset BADGETIZR_TEST_SOURCE_BRANCH
}

# Helper function to source detect_source_branch from badgetizr
load_detect_source_branch() {
    # Extract just the detect_source_branch function from badgetizr
    eval "$(sed -n '/^detect_source_branch() {$/,/^}$/p' "${BASE_PATH}/badgetizr")"
}

# ============================================================================
# Test Mode Override Tests
# ============================================================================

@test "detect_source_branch: test mode override returns production" {
    load_detect_source_branch

    # Arrange
    export BADGETIZR_TEST_SOURCE_BRANCH="production"

    # Act
    local result
    result=$(detect_source_branch "master" "master" "Test PR")

    # Assert
    [ "${result}" = "production" ]
}

@test "detect_source_branch: test mode override returns develop" {
    load_detect_source_branch

    # Arrange
    export BADGETIZR_TEST_SOURCE_BRANCH="develop"

    # Act
    local result
    result=$(detect_source_branch "master" "develop" "Test PR")

    # Assert
    [ "${result}" = "develop" ]
}

@test "detect_source_branch: test mode override ignores other parameters" {
    load_detect_source_branch

    # Arrange - Set override value
    export BADGETIZR_TEST_SOURCE_BRANCH="production"

    # Act - Even with parameters that would return "develop", test mode wins
    local result
    result=$(detect_source_branch "master" "develop" "Regular PR")

    # Assert
    [ "${result}" = "production" ]
}

# ============================================================================
# Hotfix Detection Tests (Simple Logic)
# ============================================================================

@test "detect_source_branch: detects hotfix when MR targets master + title has hotfix" {
    load_detect_source_branch

    # Arrange
    unset BADGETIZR_TEST_SOURCE_BRANCH

    # Act
    local result
    result=$(detect_source_branch "master" "master" "[HOTFIX] Fix critical bug")

    # Assert
    [ "${result}" = "production" ]
}

@test "detect_source_branch: detects hotfix when MR targets main + title has hotfix" {
    load_detect_source_branch

    # Arrange
    unset BADGETIZR_TEST_SOURCE_BRANCH

    # Act
    local result
    result=$(detect_source_branch "main" "main" "Hotfix: urgent fix")

    # Assert
    [ "${result}" = "production" ]
}

@test "detect_source_branch: NOT hotfix when title missing hotfix keyword" {
    load_detect_source_branch

    # Arrange
    unset BADGETIZR_TEST_SOURCE_BRANCH

    # Act
    local result
    result=$(detect_source_branch "master" "master" "Add new feature")

    # Assert
    [ "${result}" = "develop" ]
}

@test "detect_source_branch: NOT hotfix when MR targets develop" {
    load_detect_source_branch

    # Arrange
    unset BADGETIZR_TEST_SOURCE_BRANCH

    # Act - Even with hotfix in title, develop target = not hotfix
    local result
    result=$(detect_source_branch "master" "develop" "Hotfix: bug fix")

    # Assert
    [ "${result}" = "develop" ]
}

@test "detect_source_branch: case insensitive hotfix detection" {
    load_detect_source_branch

    # Arrange
    unset BADGETIZR_TEST_SOURCE_BRANCH

    # Act - Test various capitalizations
    local result1 result2 result3 result4
    result1=$(detect_source_branch "master" "master" "HOTFIX: urgent")
    result2=$(detect_source_branch "master" "master" "hotfix: urgent")
    result3=$(detect_source_branch "master" "master" "HotFix: urgent")
    result4=$(detect_source_branch "master" "main" "[Hotfix] urgent")

    # Assert
    [ "${result1}" = "production" ]
    [ "${result2}" = "production" ]
    [ "${result3}" = "production" ]
    [ "${result4}" = "production" ]
}

@test "detect_source_branch: hotfix keyword anywhere in title" {
    load_detect_source_branch

    # Arrange
    unset BADGETIZR_TEST_SOURCE_BRANCH

    # Act - Test hotfix in different positions
    local result1 result2 result3
    result1=$(detect_source_branch "master" "master" "[GL-1] - Test - hotfix")
    result2=$(detect_source_branch "master" "master" "hotfix - [GL-1] - Test")
    result3=$(detect_source_branch "master" "master" "[GL-1] - hotfix - Test")

    # Assert
    [ "${result1}" = "production" ]
    [ "${result2}" = "production" ]
    [ "${result3}" = "production" ]
}

@test "detect_source_branch: custom production branch name" {
    load_detect_source_branch

    # Arrange
    unset BADGETIZR_TEST_SOURCE_BRANCH

    # Act - Custom production branch "trunk"
    local result
    result=$(detect_source_branch "trunk" "trunk" "Hotfix: fix")

    # Assert
    [ "${result}" = "production" ]
}

# ============================================================================
# Edge Cases
# ============================================================================

@test "detect_source_branch: empty title returns develop" {
    load_detect_source_branch

    # Arrange
    unset BADGETIZR_TEST_SOURCE_BRANCH

    # Act
    local result
    result=$(detect_source_branch "master" "master" "")

    # Assert
    [ "${result}" = "develop" ]
}

@test "detect_source_branch: empty base branch returns develop" {
    load_detect_source_branch

    # Arrange
    unset BADGETIZR_TEST_SOURCE_BRANCH

    # Act
    local result
    result=$(detect_source_branch "master" "" "Hotfix: fix")

    # Assert
    [ "${result}" = "develop" ]
}

@test "detect_source_branch: function exists in badgetizr" {
    # Check that the function is defined in badgetizr
    grep -q "^detect_source_branch() {" "${BASE_PATH}/badgetizr"
}

@test "detect_source_branch: function returns without error" {
    load_detect_source_branch

    # Arrange
    unset BADGETIZR_TEST_SOURCE_BRANCH

    # Act & Assert - Should complete without error
    run detect_source_branch "master" "master" "Test"
    [ "$status" -eq 0 ]
}

@test "detect_source_branch: test mode takes precedence" {
    load_detect_source_branch

    # Arrange - Even with perfect hotfix conditions, test mode wins
    export BADGETIZR_TEST_SOURCE_BRANCH="develop"

    # Act
    local result
    result=$(detect_source_branch "master" "master" "Hotfix: urgent")

    # Assert - Test mode returns develop, not production
    [ "${result}" = "develop" ]
}
