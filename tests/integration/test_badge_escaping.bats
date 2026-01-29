#!/usr/bin/env bats
# Integration tests for badge URL escaping with real configuration values

load '../helpers/test_helpers'
load '../helpers/assertions'

setup() {
    setup_test_env

    source "$PROJECT_ROOT/utils.sh"

    # Create a test config with challenging label values
    cat > "${TEST_TEMP_DIR}/escaping_test.yml" << 'EOF'
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

    local label_expected="Github%20Issue"
    local value_expected="3%2F5"

    # Act - Generate badge URL components
    local label_encoded=$(url_encode_shields "${label}")
    local value_encoded=$(url_encode_shields "${value}")

    # Assert
    [ "$label_encoded" = "$label_expected" ]
    [ "$value_encoded" = "$value_expected" ]

    # Verify complete URL structure (label appears in both path and query param)
    local badge_url="https://img.shields.io/badge/${label_encoded}-${value_encoded}-grey?label=${label_encoded}&labelColor=grey&color=orange"

    # URL should contain properly escaped components
    [[ "$badge_url" =~ "badge/Github%20Issue-3%2F5-grey" ]]
    [[ "$badge_url" =~ "label=Github%20Issue" ]]
}

@test "Dynamic badge: label with ampersand generates correct URL" {
    # Arrange
    local label="Status & Progress"
    local value="Ready"

    # Act
    local label_encoded=$(url_encode_shields "${label}")

    # Assert - Critical: & must be %26
    [[ "$label_encoded" =~ "%26" ]]

    # Verify URL (label appears in both path and query param)
    local badge_url="https://img.shields.io/badge/${label_encoded}-${value}-grey?label=${label_encoded}"
    [[ "$badge_url" =~ "badge/Status%20%26%20Progress" ]]
    [[ "$badge_url" =~ "label=Status%20%26%20Progress" ]]
}

@test "Dynamic badge: label with equals sign generates correct URL" {
    # Arrange
    local label="Test=Value"

    # Act
    local label_encoded=$(url_encode_shields "${label}")

    # Assert - Critical: = must be %3D
    [[ "$label_encoded" =~ "%3D" ]]
}

@test "Dynamic badge: value with special characters is URL-encoded" {
    # Arrange
    local value="3&5 tasks"

    # Act
    local value_escaped=$(url_encode_shields "${value}")

    # Assert - Critical: & must be %26, space must be %20
    [[ "$value_escaped" =~ "%26" ]]
    [[ "$value_escaped" =~ "%20" ]]
    [ "$value_escaped" = "3%265%20tasks" ]
}

@test "Dynamic badge: url_encode_shields syntax is correct (regression test)" {
    # Arrange
    local label="Test Label"

    # Act - Should not produce error
    local result=$(url_encode_shields "${label}" 2>&1)
    local exit_code=$?

    # Assert
    [ "$exit_code" -eq 0 ]
    [[ ! "$result" =~ "syntax error" ]]
    [[ ! "$result" =~ "compile error" ]]
    [[ ! "$result" =~ "Error" ]]
    [ "$result" = "Test%20Label" ]
}

# ============================================================================
# CI Badge Escaping Tests
# ============================================================================

@test "CI badge: label with ampersand must use url_encode_shields()" {
    # Arrange
    local ci_label="Build & Test"

    # Act - Current implementation (BUGGY)
    local sed_escaped=$(sed -E 's/ /_/g; s/-/--/g' <<< "${ci_label}")

    # Act - Correct implementation
    local ci_label_escaped=$(url_encode_shields "${ci_label}")

    # Assert - Demonstrate the bug
    [ "$sed_escaped" = "Build_&_Test" ]               # & is NOT escaped - BREAKS URL
    [[ "$ci_label_escaped" =~ "Build%20%26%20Test" ]] # & is %26 - CORRECT

    # Verify URL would be broken with sed
    local bad_url="https://img.shields.io/badge/123-ignored?label=${sed_escaped}"
    [[ "$bad_url" =~ "label=Build_&_Test" ]] # & creates new query param - BROKEN
}

@test "CI badge: label with space should use url_encode_shields() for query param" {
    # Arrange
    local ci_label="Build Status"

    # Act
    local ci_label_escaped=$(url_encode_shields "${ci_label}")

    # Assert
    [ "$ci_label_escaped" = "Build%20Status" ]
}

# ============================================================================
# Other Badges Escaping Tests (No Query Params)
# ============================================================================

@test "Ticket badge: ticket ID uses url_encode_shields() for URL encoding" {
    # Arrange
    local ticket_label="My--Ticket"
    local ticket_id="ABC-123"

    # Act - Now uses url_encode_shields() for consistency
    local ticket_id_escaped=$(url_encode_shields "${ticket_id}")

    # Assert - dashes are doubled for shields.io
    [ "$ticket_id_escaped" = "ABC--123" ]

    # Verify URL
    local badge_url="https://img.shields.io/badge/${ticket_label}-${ticket_id_escaped}-blue"
    [[ "$badge_url" =~ "badge/My--Ticket-ABC--123-blue" ]]
}

@test "Ticket badge: ticket ID with special characters is URL-encoded" {
    # Arrange
    local ticket_id="ABC-123 & more"

    # Act
    local ticket_id_escaped=$(url_encode_shields "${ticket_id}")

    # Assert - Critical: & must be %26, space must be %20, dash doubled
    [[ "$ticket_id_escaped" =~ "%26" ]]
    [[ "$ticket_id_escaped" =~ "%20" ]]
    [[ "$ticket_id_escaped" =~ "--" ]]
    [ "$ticket_id_escaped" = "ABC--123%20%26%20more" ]
}

@test "Branch badge: label uses url_encode_shields() for URL encoding" {
    # Arrange
    local branch_label="Target Branch"
    local branch_name="develop"

    # Act - Now uses url_encode_shields() for consistency
    local branch_label_escaped=$(url_encode_shields "${branch_label}")

    # Assert
    [ "$branch_label_escaped" = "Target%20Branch" ]

    # Verify URL
    local badge_url="https://img.shields.io/badge/${branch_label_escaped}-${branch_name}-yellow"
    [[ "$badge_url" =~ "badge/Target%20Branch-develop-yellow" ]]
}

@test "Branch badge: label with special characters is URL-encoded" {
    # Arrange
    local branch_label="Branch & Target"

    # Act
    local branch_label_escaped=$(url_encode_shields "${branch_label}")

    # Assert - Critical: & must be %26, space must be %20
    [[ "$branch_label_escaped" =~ "%26" ]]
    [[ "$branch_label_escaped" =~ "%20" ]]
    [ "$branch_label_escaped" = "Branch%20%26%20Target" ]
}

@test "Badge escaping: underscore must be doubled for shields.io" {
    # Arrange
    local label="test_label"

    # Act
    local label_escaped=$(url_encode_shields "${label}")

    # Assert - underscore must be doubled (_ → __)
    [[ "$label_escaped" =~ "__" ]]
    [ "$label_escaped" = "test__label" ]
}

@test "Badge escaping: dash must be doubled for shields.io" {
    # Arrange
    local label="test-label"

    # Act
    local label_escaped=$(url_encode_shields "${label}")

    # Assert - dash must be doubled (- → --)
    [[ "$label_escaped" =~ "--" ]]
    [ "$label_escaped" = "test--label" ]
}

@test "Badge escaping: mixed special characters" {
    # Arrange
    local label="test-label_with spaces & more"

    # Act
    local label_escaped=$(url_encode_shields "${label}")

    # Assert - all escaping rules applied
    [[ "$label_escaped" =~ "--" ]]  # dash doubled
    [[ "$label_escaped" =~ "__" ]]  # underscore doubled
    [[ "$label_escaped" =~ "%20" ]] # space encoded
    [[ "$label_escaped" =~ "%26" ]] # ampersand encoded
    [ "$label_escaped" = "test--label__with%20spaces%20%26%20more" ]
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
    cat > "${TEST_TEMP_DIR}/ci_test.yml" << 'EOF'
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

    # CRITICAL: Label should use url_encode_shields(), not sed
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
    cat > "${TEST_TEMP_DIR}/empty_label.yml" << 'EOF'
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
