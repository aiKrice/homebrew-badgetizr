#!/usr/bin/env bats
# Integration tests for hotfix badge detection (simple logic)

load '../helpers/test_helpers'
load '../helpers/assertions'

setup() {
    setup_test_env

    # Source mocks
    source "$PROJECT_ROOT/tests/mocks/mock_gh.sh"
    source "$PROJECT_ROOT/tests/mocks/mock_responses.sh"
}

teardown() {
    cleanup_test_env
}

# ============================================================================
# Hotfix Detection Tests (Coverage for detect_source_branch)
# ============================================================================

@test "Hotfix: MR targets master + title contains hotfix → badge shown" {
    # Arrange
    export MOCK_PR_TITLE="[HOTFIX] Fix critical bug"
    export MOCK_PR_BASE_BRANCH="master"
    export MOCK_PR_HEAD_BRANCH="hotfix/urgent"
    unset BADGETIZR_TEST_SOURCE_BRANCH # Don't use test mode

    local hotfix_config=$(create_temp_config "$(
        cat << EOF_CONFIG
badge_hotfix:
  enabled: "true"
  settings:
    color: "red"
    text_color: "white"
    label: "HOTFIX"
    production_branch: "master"
EOF_CONFIG
    )")

    # Act
    run simulate_badgetizr_run 123 "$hotfix_config" --pr-destination-branch="${MOCK_PR_BASE_BRANCH}"

    # Assert
    assert_success
    assert_badge_type_exists "hotfix"
}

@test "Hotfix: MR targets master but title missing hotfix → badge NOT shown" {
    # Arrange
    export MOCK_PR_TITLE="Add new feature"
    export MOCK_PR_BASE_BRANCH="master"
    export MOCK_PR_HEAD_BRANCH="feature/new"
    unset BADGETIZR_TEST_SOURCE_BRANCH # Don't use test mode

    local hotfix_config=$(create_temp_config "$(
        cat << EOF_CONFIG
badge_hotfix:
  enabled: "true"
  settings:
    color: "red"
    text_color: "white"
    label: "HOTFIX"
    production_branch: "master"
EOF_CONFIG
    )")

    # Act
    run simulate_badgetizr_run 123 "$hotfix_config" --pr-destination-branch="${MOCK_PR_BASE_BRANCH}"

    # Assert
    assert_success
    assert_badge_type_not_exists "hotfix"
}

@test "Hotfix: title has hotfix but MR targets develop → badge NOT shown" {
    # Arrange
    export MOCK_PR_TITLE="Hotfix: bug fix"
    export MOCK_PR_BASE_BRANCH="develop"
    export MOCK_PR_HEAD_BRANCH="fix/bug"
    unset BADGETIZR_TEST_SOURCE_BRANCH # Don't use test mode

    local hotfix_config=$(create_temp_config "$(
        cat << EOF_CONFIG
badge_hotfix:
  enabled: "true"
  settings:
    color: "red"
    text_color: "white"
    label: "HOTFIX"
    production_branch: "master"
EOF_CONFIG
    )")

    # Act
    run simulate_badgetizr_run 123 "$hotfix_config" --pr-destination-branch="${MOCK_PR_BASE_BRANCH}"

    # Assert
    assert_success
    assert_badge_type_not_exists "hotfix"
}

@test "Hotfix: case insensitive - HOTFIX uppercase" {
    # Arrange
    export MOCK_PR_TITLE="HOTFIX: urgent fix"
    export MOCK_PR_BASE_BRANCH="main"
    export MOCK_PR_HEAD_BRANCH="hotfix/urgent"
    unset BADGETIZR_TEST_SOURCE_BRANCH

    local hotfix_config=$(create_temp_config "$(
        cat << EOF_CONFIG
badge_hotfix:
  enabled: "true"
  settings:
    color: "red"
    label: "HOTFIX"
    production_branch: "main"
EOF_CONFIG
    )")

    # Act
    run simulate_badgetizr_run 123 "$hotfix_config" --pr-destination-branch="${MOCK_PR_BASE_BRANCH}"

    # Assert
    assert_success
    assert_badge_type_exists "hotfix"
}

@test "Hotfix: works with main instead of master" {
    # Arrange
    export MOCK_PR_TITLE="[Hotfix] Fix issue"
    export MOCK_PR_BASE_BRANCH="main"
    export MOCK_PR_HEAD_BRANCH="hotfix/issue"
    unset BADGETIZR_TEST_SOURCE_BRANCH

    local hotfix_config=$(create_temp_config "$(
        cat << EOF_CONFIG
badge_hotfix:
  enabled: "true"
  settings:
    color: "red"
    label: "HOTFIX"
    production_branch: "main"
EOF_CONFIG
    )")

    # Act
    run simulate_badgetizr_run 123 "$hotfix_config" --pr-destination-branch="${MOCK_PR_BASE_BRANCH}"

    # Assert
    assert_success
    assert_badge_type_exists "hotfix"
}
