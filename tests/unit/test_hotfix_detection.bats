#!/usr/bin/env bats
# Unit tests for is_hotfix_pr function (simplified logic)

setup() {
    export BASE_PATH="${BATS_TEST_DIRNAME}/../.."
    export PROJECT_ROOT="${BASE_PATH}"

    # Source the main script to get the is_hotfix_pr function
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

# Helper function to source is_hotfix_pr from badgetizr
load_is_hotfix_pr() {
    # Extract just the is_hotfix_pr function from badgetizr
    eval "$(sed -n '/^is_hotfix_pr() {$/,/^}$/p' "${BASE_PATH}/badgetizr")"
}

# ============================================================================
# Test Mode Override Tests
# ============================================================================

@test "is_hotfix_pr: test mode override returns hotfix" {
    load_is_hotfix_pr

    # Arrange
    export BADGETIZR_TEST_SOURCE_BRANCH="hotfix"

    # Act
    local result
    result=$(is_hotfix_pr "master" "master" "Test PR")

    # Assert
    [ "${result}" = "hotfix" ]
}

@test "is_hotfix_pr: test mode override returns feature" {
    load_is_hotfix_pr

    # Arrange
    export BADGETIZR_TEST_SOURCE_BRANCH="feature"

    # Act
    local result
    result=$(is_hotfix_pr "master" "develop" "Test PR")

    # Assert
    [ "${result}" = "feature" ]
}

@test "is_hotfix_pr: test mode override ignores other parameters" {
    load_is_hotfix_pr

    # Arrange - Set override value
    export BADGETIZR_TEST_SOURCE_BRANCH="hotfix"

    # Act - Even with parameters that would return "develop", test mode wins
    local result
    result=$(is_hotfix_pr "master" "develop" "Regular PR")

    # Assert
    [ "${result}" = "hotfix" ]
}

# ============================================================================
# Hotfix Detection Tests (Simple Logic)
# ============================================================================

@test "is_hotfix_pr: detects hotfix when MR targets master + title has hotfix" {
    load_is_hotfix_pr

    # Arrange
    unset BADGETIZR_TEST_SOURCE_BRANCH

    # Act
    local result
    result=$(is_hotfix_pr "master" "master" "[HOTFIX] Fix critical bug")

    # Assert
    [ "${result}" = "hotfix" ]
}

@test "is_hotfix_pr: detects hotfix when MR targets main + title has hotfix" {
    load_is_hotfix_pr

    # Arrange
    unset BADGETIZR_TEST_SOURCE_BRANCH

    # Act
    local result
    result=$(is_hotfix_pr "main" "main" "Hotfix: urgent fix")

    # Assert
    [ "${result}" = "hotfix" ]
}

@test "is_hotfix_pr: NOT hotfix when title missing hotfix keyword" {
    load_is_hotfix_pr

    # Arrange
    unset BADGETIZR_TEST_SOURCE_BRANCH

    # Act
    local result
    result=$(is_hotfix_pr "master" "master" "Add new feature")

    # Assert
    [ "${result}" = "feature" ]
}

@test "is_hotfix_pr: NOT hotfix when MR targets develop" {
    load_is_hotfix_pr

    # Arrange
    unset BADGETIZR_TEST_SOURCE_BRANCH

    # Act - Even with hotfix in title, develop target = not hotfix
    local result
    result=$(is_hotfix_pr "master" "develop" "Hotfix: bug fix")

    # Assert
    [ "${result}" = "feature" ]
}

@test "is_hotfix_pr: case insensitive hotfix detection" {
    load_is_hotfix_pr

    # Arrange
    unset BADGETIZR_TEST_SOURCE_BRANCH

    # Act - Test various capitalizations
    local result1 result2 result3 result4
    result1=$(is_hotfix_pr "master" "master" "HOTFIX: urgent")
    result2=$(is_hotfix_pr "master" "master" "hotfix: urgent")
    result3=$(is_hotfix_pr "master" "master" "HotFix: urgent")
    result4=$(is_hotfix_pr "master" "main" "[Hotfix] urgent")

    # Assert
    [ "${result1}" = "hotfix" ]
    [ "${result2}" = "hotfix" ]
    [ "${result3}" = "hotfix" ]
    [ "${result4}" = "hotfix" ]
}

@test "is_hotfix_pr: hotfix keyword anywhere in title" {
    load_is_hotfix_pr

    # Arrange
    unset BADGETIZR_TEST_SOURCE_BRANCH

    # Act - Test hotfix in different positions
    local result1 result2 result3
    result1=$(is_hotfix_pr "master" "master" "[GL-1] - Test - hotfix")
    result2=$(is_hotfix_pr "master" "master" "hotfix - [GL-1] - Test")
    result3=$(is_hotfix_pr "master" "master" "[GL-1] - hotfix - Test")

    # Assert
    [ "${result1}" = "hotfix" ]
    [ "${result2}" = "hotfix" ]
    [ "${result3}" = "hotfix" ]
}

@test "is_hotfix_pr: custom production branch name" {
    load_is_hotfix_pr

    # Arrange
    unset BADGETIZR_TEST_SOURCE_BRANCH

    # Act - Custom production branch "trunk"
    local result
    result=$(is_hotfix_pr "trunk" "trunk" "Hotfix: fix")

    # Assert
    [ "${result}" = "hotfix" ]
}

# ============================================================================
# Edge Cases
# ============================================================================

@test "is_hotfix_pr: empty title returns feature" {
    load_is_hotfix_pr

    # Arrange
    unset BADGETIZR_TEST_SOURCE_BRANCH

    # Act
    local result
    result=$(is_hotfix_pr "master" "master" "")

    # Assert
    [ "${result}" = "feature" ]
}

@test "is_hotfix_pr: empty base branch returns feature" {
    load_is_hotfix_pr

    # Arrange
    unset BADGETIZR_TEST_SOURCE_BRANCH

    # Act
    local result
    result=$(is_hotfix_pr "master" "" "Hotfix: fix")

    # Assert
    [ "${result}" = "feature" ]
}

@test "is_hotfix_pr: function exists in badgetizr" {
    # Check that the function is defined in badgetizr
    grep -q "^is_hotfix_pr() {" "${BASE_PATH}/badgetizr"
}

@test "is_hotfix_pr: function returns without error" {
    load_is_hotfix_pr

    # Arrange
    unset BADGETIZR_TEST_SOURCE_BRANCH

    # Act & Assert - Should complete without error
    run is_hotfix_pr "master" "master" "Test"
    [ "$status" -eq 0 ]
}

@test "is_hotfix_pr: test mode takes precedence" {
    load_is_hotfix_pr

    # Arrange - Even with perfect hotfix conditions, test mode wins
    export BADGETIZR_TEST_SOURCE_BRANCH="feature"

    # Act
    local result
    result=$(is_hotfix_pr "master" "master" "Hotfix: urgent")

    # Assert - Test mode returns feature, not production
    [ "${result}" = "feature" ]
}
