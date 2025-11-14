#!/usr/bin/env bats
# Integration tests for badge URL escaping with real configuration values
# BUSINESS CRITICAL: Prevent regressions in badge label/value escaping

load '../helpers/test_helpers'
load '../helpers/assertions'

setup() {
    setup_test_env

    # Create a test config with challenging label values
    cat > "${TEST_TEMP_DIR}/escaping_test.yml" <<'EOF'
badge_dynamic:
  enabled: true
  settings:
    patterns:
      - label: "Github Issue"  # Space
        sed_pattern: ".*Task: ([0-9]+\\/[0-9]+).*"
        value: "default"
        color: "orange"
      - label: "Status & Progress"  # Ampersand
        sed_pattern: ".*Status: ([A-Za-z]+).*"
        value: "default"
        color: "blue"
      - label: "Test=Value"  # Equals sign
        sed_pattern: ".*Test: ([A-Za-z]+).*"
        value: "default"
        color: "green"

badge_ci:
  enabled: false  # Disabled to simplify test
  settings:
    label: "Build & Test"  # Ampersand in CI label
    color: "blue"
    logo: "githubactions"

badge_ticket:
  enabled: true
  settings:
    label: "My-Ticket"  # Hyphen
    sed_pattern: ".*\\[([A-Z]+-[0-9]+)\\].*"
    url: "https://jira.example.com/browse/%s"
    color: "blue"

badge_branch:
  enabled: true
  settings:
    label: "Target Branch"  # Space
    base_branch: "master"
    color: "yellow"
EOF

    # Source mocks and utils
    source "$PROJECT_ROOT/tests/mocks/mock_gh.sh"
    source "$PROJECT_ROOT/tests/mocks/mock_responses.sh"
}

teardown() {
    cleanup_test_env
}

# ============================================================================
# Dynamic Badge Escaping Tests
# ============================================================================

@test "Dynamic badge: label with space generates correct URL" {
    # Arrange
    local label="Github Issue"
    local value="3/5"

    # Expected outputs (all use jq @uri now)
    local default_label="Github%20Issue"
    local override_label="Github%20Issue"
    local value_escaped="3%2F5"

    # Act - Generate badge URL components
    local default_label_actual=$(jq -rn --arg s "${label}" '$s | @uri')
    local override_label_actual=$(jq -rn --arg s "${label}" '$s | @uri')
    local value_actual=$(jq -rn --arg s "${value}" '$s | @uri')

    # Assert
    [ "$default_label_actual" = "$default_label" ]
    [ "$override_label_actual" = "$override_label" ]
    [ "$value_actual" = "$value_escaped" ]

    # Verify complete URL structure
    local badge_url="https://img.shields.io/badge/${default_label_actual}-${value_actual}-grey?label=${override_label_actual}&labelColor=grey&color=orange"

    # URL should contain properly escaped components
    [[ "$badge_url" =~ "badge/Github%20Issue-3%2F5-grey" ]]
    [[ "$badge_url" =~ "label=Github%20Issue" ]]
}

@test "Dynamic badge: label with ampersand generates correct URL" {
    # Arrange
    local label="Status & Progress"
    local value="Ready"

    # Act (now uses jq @uri for everything)
    local default_label=$(jq -rn --arg s "${label}" '$s | @uri')
    local override_label=$(jq -rn --arg s "${label}" '$s | @uri')

    # Assert - Critical: & must be %26 everywhere
    [[ "$default_label" =~ "%26" ]]
    [[ "$override_label" =~ "%26" ]]

    # Verify URL
    local badge_url="https://img.shields.io/badge/${default_label}-${value}-grey?label=${override_label}"
    [[ "$badge_url" =~ "badge/Status%20%26%20Progress" ]]
    [[ "$badge_url" =~ "label=Status%20%26%20Progress" ]]
}

@test "Dynamic badge: label with equals sign generates correct URL" {
    # Arrange
    local label="Test=Value"

    # Act
    local override_label=$(jq -rn --arg s "${label}" '$s | @uri')

    # Assert - Critical: = must be %3D everywhere
    [[ "$override_label" =~ "%3D" ]]
}

@test "Dynamic badge: value with special characters is URL-encoded" {
    # Arrange
    local value="3&5 tasks"

    # Act
    local value_escaped=$(jq -rn --arg s "${value}" '$s | @uri')

    # Assert - Critical: & must be %26, space must be %20
    [[ "$value_escaped" =~ "%26" ]]
    [[ "$value_escaped" =~ "%20" ]]
    [ "$value_escaped" = "3%265%20tasks" ]
}

@test "Dynamic badge: jq syntax is correct (regression test)" {
    # BUSINESS CRITICAL: Prevent the '${{s}}' bug from returning

    # Arrange
    local label="Test Label"

    # Act - Should not produce jq compile error
    local result=$(jq -rn --arg s "${label}" '$s | @uri' 2>&1)
    local exit_code=$?

    # Assert
    [ "$exit_code" -eq 0 ]
    [[ ! "$result" =~ "syntax error" ]]
    [[ ! "$result" =~ "compile error" ]]
    [ "$result" = "Test%20Label" ]
}

# ============================================================================
# CI Badge Escaping Tests
# ============================================================================

@test "CI badge: label with ampersand must use jq @uri" {
    # Arrange
    local ci_label="Build & Test"

    # Act - Current implementation (BUGGY)
    local sed_escaped=$(sed -E 's/ /_/g; s/-/--/g' <<< "${ci_label}")

    # Act - Correct implementation
    local jq_escaped=$(jq -rn --arg s "${ci_label}" '$s | @uri')

    # Assert - Demonstrate the bug
    [ "$sed_escaped" = "Build_&_Test" ]  # & is NOT escaped - BREAKS URL
    [[ "$jq_escaped" =~ "Build%20%26%20Test" ]]  # & is %26 - CORRECT

    # Verify URL would be broken with sed
    local bad_url="https://img.shields.io/badge/123-ignored?label=${sed_escaped}"
    [[ "$bad_url" =~ "label=Build_&_Test" ]]  # & creates new query param - BROKEN
}

@test "CI badge: label with space should use jq @uri for query param" {
    # Arrange
    local ci_label="Build Status"

    # Act
    local jq_escaped=$(jq -rn --arg s "${ci_label}" '$s | @uri')

    # Assert
    [ "$jq_escaped" = "Build%20Status" ]
}

# ============================================================================
# Other Badges Escaping Tests (No Query Params)
# ============================================================================

@test "Ticket badge: label in path uses sed escaping (no query param)" {
    # Arrange
    local ticket_label="My-Ticket"
    local ticket_id="ABC-123"

    # Act - Ticket badge uses labels in PATH, not query params
    local ticket_id_escaped=$(sed -E 's/ /_/g; s/-/--/g' <<< "${ticket_id}")

    # Assert
    [ "$ticket_id_escaped" = "ABC--123" ]  # Hyphens doubled for shields.io

    # Verify URL - label is in path, not query param, so sed is OK
    local badge_url="https://img.shields.io/badge/${ticket_label}-${ticket_id_escaped}-blue"
    [[ "$badge_url" =~ "badge/My-Ticket-ABC--123-blue" ]]
}

@test "Branch badge: label in path uses sed escaping (no query param)" {
    # Arrange
    local branch_label="Target Branch"
    local branch_name="develop"

    # Act
    local branch_label_escaped=$(sed -E 's/ /_/g; s/-/--/g' <<< "${branch_label}")

    # Assert
    [ "$branch_label_escaped" = "Target_Branch" ]

    # Verify URL - all in path, so sed is OK
    local badge_url="https://img.shields.io/badge/${branch_label_escaped}-${branch_name}-yellow"
    [[ "$badge_url" =~ "badge/Target_Branch-develop-yellow" ]]
}

# ============================================================================
# End-to-End Integration Tests with Config File
# ============================================================================

@test "Integration: dynamic badge from config with special characters works" {
    # Arrange
    export MOCK_GIT_REMOTE="https://github.com/test/repo.git"
    mock_git

    # Create PR with matching body
    export MOCK_PR_TITLE="Test PR"
    export MOCK_PR_BODY="Task: 3/5 tasks completed"

    # Act - Run badgetizr with test config
    run "$PROJECT_ROOT/badgetizr" \
        --pr-id=123 \
        --configuration="${TEST_TEMP_DIR}/escaping_test.yml" \
        --pr-destination-branch=develop

    # Assert - Should succeed without errors
    assert_success

    # Verify badge was created with proper escaping
    [ -f "$MOCK_GH_RESPONSES_DIR/pr_body.txt" ]
    local pr_body=$(cat "$MOCK_GH_RESPONSES_DIR/pr_body.txt")

    # Should contain escaped label in query param
    [[ "$pr_body" =~ "label=Github%20Issue" ]]

    # Cleanup
    unmock_git
}

@test "Integration: CI badge with ampersand in label from config" {
    # Arrange
    # Create config with CI badge enabled
    cat > "${TEST_TEMP_DIR}/ci_test.yml" <<'EOF'
badge_ci:
  enabled: true
  settings:
    label: "Build & Test"
    color: "blue"
    logo: "githubactions"
EOF

    export MOCK_GIT_REMOTE="https://github.com/test/repo.git"
    mock_git
    export MOCK_PR_TITLE="Test PR"
    export MOCK_PR_BODY="Test body"

    # Act - Run badgetizr with CI badge enabled
    run "$PROJECT_ROOT/badgetizr" \
        --pr-id=123 \
        --configuration="${TEST_TEMP_DIR}/ci_test.yml" \
        --pr-destination-branch=develop \
        --pr-build-number=456 \
        --pr-build-url="https://ci.example.com/build/456"

    # Assert
    assert_success

    # Verify CI badge was created
    [ -f "$MOCK_GH_RESPONSES_DIR/pr_body.txt" ]
    local pr_body=$(cat "$MOCK_GH_RESPONSES_DIR/pr_body.txt")

    # CRITICAL: Label should use jq @uri, not sed
    # With current bug, this will contain "label=Build_&_Test" (WRONG)
    # After fix, should contain "label=Build%20%26%20Test" (CORRECT)
    [[ "$pr_body" =~ "img.shields.io" ]]

    # Cleanup
    unmock_git
}

# ============================================================================
# Error Case Tests
# ============================================================================

@test "Dynamic badge: pattern not matching does not crash" {
    # Arrange
    export MOCK_GIT_REMOTE="https://github.com/test/repo.git"
    mock_git
    export MOCK_PR_TITLE="Test PR"
    export MOCK_PR_BODY="No matching pattern here"

    # Act
    run "$PROJECT_ROOT/badgetizr" \
        --pr-id=123 \
        --configuration="${TEST_TEMP_DIR}/escaping_test.yml" \
        --pr-destination-branch=develop

    # Assert - Should succeed even if patterns don't match
    assert_success

    # Cleanup
    unmock_git
}

@test "Dynamic badge: empty label does not crash" {
    # Arrange
    cat > "${TEST_TEMP_DIR}/empty_label.yml" <<'EOF'
badge_dynamic:
  enabled: true
  settings:
    patterns:
      - label: ""
        sed_pattern: ".*Task: ([0-9]+).*"
        value: "default"
        color: "orange"
EOF

    export MOCK_GIT_REMOTE="https://github.com/test/repo.git"
    mock_git
    export MOCK_PR_BODY="Task: 5 completed"
    setup_wip_pr

    # Act
    run "$PROJECT_ROOT/badgetizr" \
        --pr-id=123 \
        --configuration="${TEST_TEMP_DIR}/empty_label.yml" \
        --pr-destination-branch=develop

    # Assert - Should handle gracefully
    assert_success

    # Cleanup
    unmock_git
}
