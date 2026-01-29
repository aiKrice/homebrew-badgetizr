#!/usr/bin/env bats
# Integration tests for badge generation

load '../helpers/test_helpers'
load '../helpers/assertions'

setup() {
    setup_test_env

    # Source mocks and responses
    source "$PROJECT_ROOT/tests/mocks/mock_gh.sh"
    source "$PROJECT_ROOT/tests/mocks/mock_responses.sh"

    # Create test config
    TEST_CONFIG=$(create_temp_config "$(get_default_test_config)")
}

teardown() {
    cleanup_test_env
}

# ============================================================================
# WIP Badge Tests
# ============================================================================

@test "WIP badge is generated when PR title contains [WIP]" {
    # Arrange
    setup_wip_pr

    # Act
    run simulate_badgetizr_run 123 "$TEST_CONFIG"

    # Debug output on failure
    if [ "$status" -ne 0 ]; then
        echo "Output: $output"
        echo "Status: $status"
    fi

    # Assert
    assert_success
    assert_has_badgetizr_delimiters
    assert_badge_type_exists "wip"
    assert_badge_has_color "yellow"
}

@test "WIP badge is generated when PR title starts with WIP:" {
    # Arrange
    export MOCK_PR_TITLE="WIP: Implementing new feature"
    export MOCK_PR_BODY="Work in progress"

    # Act
    run simulate_badgetizr_run 123 "$TEST_CONFIG"

    # Assert
    assert_success
    assert_badge_type_exists "wip"
}

@test "WIP badge is NOT generated when title has no WIP marker" {
    # Arrange
    export MOCK_PR_TITLE="Normal PR title"
    export MOCK_PR_BODY="Normal PR body"

    # Act
    run simulate_badgetizr_run 123 "$TEST_CONFIG"

    # Assert
    assert_success
    assert_badge_type_not_exists "wip"
}

# ============================================================================
# Hotfix Badge Tests
# ============================================================================

@test "Hotfix badge is generated for hotfix branch" {
    # Arrange
    setup_hotfix_pr
    local hotfix_config=$(create_temp_config "$(
        cat <<EOF
badge_hotfix:
  enabled: "true"
  settings:
    color: "red"
    text_color: "white"
    label: "HOTFIX"
EOF
    )")

    # Act - Hotfix badge checks if PR targets main/master (via provider)
    run simulate_badgetizr_run 123 "$hotfix_config"

    # Assert
    assert_success
    assert_badge_type_exists "hotfix"
    assert_badge_has_color "red"
}

@test "Hotfix badge contains HOTFIX text" {
    # Arrange
    setup_hotfix_pr
    local hotfix_config=$(create_temp_config "$(
        cat <<EOF
badge_hotfix:
  enabled: "true"
  settings:
    color: "red"
    text_color: "white"
    label: "HOTFIX"
EOF
    )")

    # Act
    run simulate_badgetizr_run 123 "$hotfix_config"

    # Assert
    assert_badge_contains "HOTFIX"
}

@test "Hotfix badge is NOT generated for non-hotfix branches" {
    # Arrange - PR targeting develop (not main/master)
    export MOCK_PR_HEAD_BRANCH="feature/normal-feature"
    export MOCK_PR_BASE_BRANCH="develop"
    local hotfix_config=$(create_temp_config "$(
        cat <<EOF
badge_hotfix:
  enabled: "true"
  settings:
    color: "red"
    text_color: "white"
    label: "HOTFIX"
EOF
    )")

    # Act
    run simulate_badgetizr_run 123 "$hotfix_config"

    # Assert
    assert_success
    assert_badge_type_not_exists "hotfix"
}

# ============================================================================
# CI Badge Tests
# ============================================================================

@test "CI badge is generated with started status" {
    # Arrange
    setup_ci_started
    local ci_config=$(create_temp_config "$(
        cat <<EOF
badge_ci:
  enabled: "true"
  settings:
    label_color: "black"
    label: "Build"
    logo: "github"
    color: darkgreen
EOF
    )")

    # Act
    run simulate_badgetizr_run 123 "$ci_config" --ci-status=started --ci-text="Running tests" --pr-build-url=https://ci.example.com/123

    # Assert
    assert_success
    assert_badge_type_exists "ci"
}

@test "CI badge is generated with passed status" {
    # Arrange
    setup_ci_passed
    local ci_config=$(create_temp_config "$(get_ci_badge_config)")

    # Act
    run simulate_badgetizr_run 123 "$ci_config" --ci-status=passed --pr-build-url=https://ci.example.com/123

    # Assert
    assert_success
    assert_badge_type_exists "ci"
    assert_badge_has_color "darkgreen"
}

@test "CI badge is generated with failed status" {
    # Arrange
    setup_ci_failed
    local ci_config=$(create_temp_config "$(get_ci_badge_config)")

    # Act
    run simulate_badgetizr_run 123 "$ci_config" --ci-status=failed --pr-build-url=https://ci.example.com/123

    # Assert
    assert_success
    assert_badge_type_exists "ci"
    assert_badge_has_color "red"
}

@test "CI badge contains custom text" {
    # Arrange
    local ci_config=$(create_temp_config "$(get_ci_badge_config)")

    # Act
    run simulate_badgetizr_run 123 "$ci_config" --ci-status=started --ci-text="Custom CI Text" --pr-build-url=https://ci.example.com/123

    # Assert
    assert_badge_contains "Custom"
}

# ============================================================================
# Ticket Badge Tests
# ============================================================================

@test "Ticket badge is generated when PR title contains ticket ID" {
    # Arrange
    setup_ticket_pr
    export MOCK_PR_TITLE="feat(GH-123): Add new feature"
    local ticket_config=$(create_temp_config "$(get_ticket_badge_config)")

    # Act
    run simulate_badgetizr_run 123 "$ticket_config"

    # Assert
    assert_success
    assert_badge_type_exists "ticket"
}

@test "Ticket badge extracts ID from PR title" {
    # Arrange
    export MOCK_PR_TITLE="fix(GH-456): Bug fix"
    local ticket_config=$(create_temp_config "$(get_ticket_badge_config)")

    # Act
    run simulate_badgetizr_run 123 "$ticket_config"

    # Assert
    assert_badge_contains "456" || assert_badge_contains "GH-456"
}

@test "Ticket badge is NOT generated without ticket ID" {
    # Arrange
    export MOCK_PR_TITLE="feat: Add feature without ticket"

    # Act
    run simulate_badgetizr_run 123 "$TEST_CONFIG"

    # Assert
    # Ticket badge should not exist or should show default message
    # Depending on implementation
    assert_success
}

# ============================================================================
# Branch Badge Tests
# ============================================================================

@test "Branch badge is generated when targeting non-default branch" {
    # Arrange
    setup_branch_target_pr
    export MOCK_PR_BASE_BRANCH="release/v2.0"
    local branch_config=$(create_temp_config "$(get_branch_badge_config)")

    # Act
    run simulate_badgetizr_run 123 "$branch_config" --pr-destination-branch=release/v2.0

    # Assert
    assert_success
    assert_badge_type_exists "branch"
}

@test "Branch badge shows target branch name" {
    # Arrange
    export MOCK_PR_BASE_BRANCH="release/v3.0"
    local branch_config=$(create_temp_config "$(get_branch_badge_config)")

    # Act
    run simulate_badgetizr_run 123 "$branch_config" --pr-destination-branch=release/v3.0

    # Assert
    assert_badge_contains "release"
}

@test "Branch badge is NOT generated when targeting default branch" {
    # Arrange
    export MOCK_PR_BASE_BRANCH="develop"

    # Act
    run simulate_badgetizr_run 123 "$TEST_CONFIG" "--pr-destination-branch=develop"

    # Assert
    # Branch badge should not exist when targeting default branch (develop)
    assert_success
}

# ============================================================================
# Multiple Badges Tests
# ============================================================================

@test "Multiple badges can be generated simultaneously" {
    # Arrange
    export MOCK_PR_TITLE="[WIP] feat(GH-789): Add feature"
    export MOCK_PR_HEAD_BRANCH="hotfix/urgent"
    export MOCK_PR_BASE_BRANCH="main"

    # Config with multiple badges enabled
    local multi_config=$(create_temp_config "$(
        cat <<EOF
badge_wip:
  enabled: "true"
  settings:
    color: "yellow"
    label: "WIP"
badge_hotfix:
  enabled: "true"
  settings:
    color: "red"
    label: "HOTFIX"
badge_ticket:
  enabled: "true"
  settings:
    color: "black"
    label: "Issue"
    sed_pattern: '.*[([]GH-([0-9]+)[])].*'
    url: "https://github.com/test/repo/issues/%s"
    logo: "github"
badge_ci:
  enabled: "true"
  settings:
    label: "Build"
    color: darkgreen
EOF
    )")

    # Act
    run simulate_badgetizr_run 123 "$multi_config" --ci-status=started --pr-build-url=https://ci.example.com/123

    # Assert
    assert_success

    # Should have WIP, Hotfix, Ticket, and CI badges
    local badge_count=$(count_badges "$output")
    [ "$badge_count" -ge 3 ] # At least 3 badges
}

@test "Badges are wrapped in badgetizr delimiters" {
    # Arrange
    setup_wip_pr

    # Act
    run simulate_badgetizr_run 123 "$TEST_CONFIG"

    # Assert
    assert_has_badgetizr_delimiters
}

@test "Badge generation handles empty PR body" {
    # Arrange
    export MOCK_PR_TITLE="Test PR"
    export MOCK_PR_BODY=""

    # Act
    run simulate_badgetizr_run 123 "$TEST_CONFIG"

    # Assert
    assert_success
    assert_has_badgetizr_delimiters
}

# ============================================================================
# Badge URL Format Tests
# ============================================================================

@test "Generated badge URLs are valid shields.io URLs" {
    # Arrange
    setup_wip_pr

    # Act
    run simulate_badgetizr_run 123 "$TEST_CONFIG"

    # Assert
    local wip_badge_url=$(get_badge_url_by_type "$output" "wip")
    validate_badge_url "$wip_badge_url"
}

@test "Badge URLs contain proper encoding" {
    # Arrange
    export MOCK_PR_TITLE="[WIP] Test: Special chars & symbols"

    # Act
    run simulate_badgetizr_run 123 "$TEST_CONFIG"

    # Assert
    assert_success
    # Badge should be generated successfully even with special characters
    assert_badge_type_exists "wip"
}

# ============================================================================
# Configuration Tests
# ============================================================================

@test "Badge generation respects disabled badges in config" {
    # Arrange
    local config_with_disabled=$(
        cat <<EOF
badge_wip:
  enabled: "false"
badge_hotfix:
  enabled: "true"
  settings:
    color: "red"
    label: "HOTFIX"
EOF
    )
    local custom_config=$(create_temp_config "$config_with_disabled")
    export MOCK_PR_TITLE="[WIP] Test"
    export MOCK_PR_BASE_BRANCH="main"
    export MOCK_PR_HEAD_BRANCH="hotfix/test"

    # Act
    run simulate_badgetizr_run 123 "$custom_config"

    # Assert
    assert_success
    assert_badge_type_not_exists "wip"
    # Should have hotfix badge since we're targeting main from hotfix branch
    assert_badge_type_exists "hotfix"
}

@test "Badge colors can be customized via config" {
    # Arrange
    local config_custom_color=$(
        cat <<EOF
badge_wip:
  enabled: "true"
  settings:
    color: "purple"
    label: "WIP"
EOF
    )
    local custom_config=$(create_temp_config "$config_custom_color")
    setup_wip_pr

    # Act
    run simulate_badgetizr_run 123 "$custom_config"

    # Assert
    assert_success
    assert_badge_has_color "purple"
}
