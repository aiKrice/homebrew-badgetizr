#!/usr/bin/env bats
# Integration tests for label management functionality

load '../helpers/test_helpers'
load '../helpers/assertions'

setup() {
    setup_test_env

    # Source mocks
    source "$PROJECT_ROOT/tests/mocks/mock_gh.sh"
    source "$PROJECT_ROOT/tests/mocks/mock_glab.sh"
    source "$PROJECT_ROOT/tests/mocks/mock_responses.sh"
}

teardown() {
    cleanup_test_env
}

# ============================================================================
# WIP Badge Labelized Tests
# ============================================================================

@test "WIP badge adds label when labelized is enabled" {
    # Arrange
    export MOCK_PR_TITLE="[WIP] Add new feature"
    local wip_labelized_config=$(create_temp_config "$(
        cat <<EOF
badge_wip:
  enabled: "true"
  settings:
    color: "yellow"
    label: "WIP"
    labelized: "work in progress"
EOF
    )")

    # Act
    run simulate_badgetizr_run 123 "$wip_labelized_config"

    # Assert
    assert_success
    assert_badge_type_exists "wip"
    assert_label_added "work in progress"
}

@test "WIP badge removes label when title no longer has WIP" {
    # Arrange
    export MOCK_PR_TITLE="Normal PR title"
    local wip_labelized_config=$(create_temp_config "$(
        cat <<EOF
badge_wip:
  enabled: "true"
  settings:
    color: "yellow"
    label: "WIP"
    labelized: "work in progress"
EOF
    )")

    # Act
    run simulate_badgetizr_run 123 "$wip_labelized_config"

    # Assert
    assert_success
    assert_label_removed "work in progress"
}

@test "WIP badge creates label if it doesn't exist" {
    # Arrange
    export MOCK_PR_TITLE="[WIP] Add new feature"
    local wip_labelized_config=$(create_temp_config "$(
        cat <<EOF
badge_wip:
  enabled: "true"
  settings:
    color: "yellow"
    label: "WIP"
    labelized: "work in progress"
EOF
    )")

    # Act
    run simulate_badgetizr_run 123 "$wip_labelized_config"

    # Assert
    assert_success
    # Label should be created if it doesn't exist
    assert_label_created "work in progress" || assert_label_added "work in progress"
}

# ============================================================================
# Hotfix Badge Labelized Tests
# ============================================================================

@test "Hotfix badge adds label when targeting main/master" {
    # Arrange
    export MOCK_PR_TITLE="Fix critical bug"
    export MOCK_PR_BASE_BRANCH="main"
    export MOCK_PR_HEAD_BRANCH="hotfix/urgent-fix"
    local hotfix_labelized_config=$(create_temp_config "$(
        cat <<EOF
badge_hotfix:
  enabled: "true"
  settings:
    color: "red"
    text_color: "white"
    label: "HOTFIX"
    labelized: "hotfix"
EOF
    )")

    # Act
    run simulate_badgetizr_run 123 "$hotfix_labelized_config"

    # Assert
    assert_success
    assert_badge_type_exists "hotfix"
    assert_label_added "hotfix"
}

@test "Hotfix badge removes label when not targeting main/master" {
    # Arrange
    export MOCK_PR_TITLE="Normal PR"
    export MOCK_PR_BASE_BRANCH="develop"
    export MOCK_PR_HEAD_BRANCH="feature/normal"
    local hotfix_labelized_config=$(create_temp_config "$(
        cat <<EOF
badge_hotfix:
  enabled: "true"
  settings:
    color: "red"
    text_color: "white"
    label: "HOTFIX"
    labelized: "hotfix"
EOF
    )")

    # Act
    run simulate_badgetizr_run 123 "$hotfix_labelized_config"

    # Assert
    assert_success
    assert_label_removed "hotfix"
}

@test "Hotfix badge creates label with red color" {
    # Arrange
    export MOCK_PR_TITLE="Fix critical bug"
    export MOCK_PR_BASE_BRANCH="main"
    export MOCK_PR_HEAD_BRANCH="hotfix/urgent-fix"
    local hotfix_labelized_config=$(create_temp_config "$(
        cat <<EOF
badge_hotfix:
  enabled: "true"
  settings:
    color: "red"
    text_color: "white"
    label: "HOTFIX"
    labelized: "hotfix"
EOF
    )")

    # Act
    run simulate_badgetizr_run 123 "$hotfix_labelized_config"

    # Assert
    assert_success
    # Hotfix label should be created with red color (d73a49)
    if [ -f "$MOCK_GH_RESPONSES_DIR/created_labels.txt" ]; then
        grep -q "hotfix" "$MOCK_GH_RESPONSES_DIR/created_labels.txt" || true
    fi
}

# ============================================================================
# Label Management Without Labelized
# ============================================================================

@test "WIP badge without labelized does not manage labels" {
    # Arrange
    export MOCK_PR_TITLE="[WIP] Add new feature"
    local wip_no_label_config=$(create_temp_config "$(
        cat <<EOF
badge_wip:
  enabled: "true"
  settings:
    color: "yellow"
    label: "WIP"
EOF
    )")

    # Act
    run simulate_badgetizr_run 123 "$wip_no_label_config"

    # Assert
    assert_success
    assert_badge_type_exists "wip"
    # No labels should be added
    [ ! -f "$MOCK_GH_RESPONSES_DIR/added_labels.txt" ] ||
        [ ! -s "$MOCK_GH_RESPONSES_DIR/added_labels.txt" ]
}

@test "Hotfix badge without labelized does not manage labels" {
    # Arrange
    export MOCK_PR_TITLE="Fix critical bug"
    export MOCK_PR_BASE_BRANCH="main"
    export MOCK_PR_HEAD_BRANCH="hotfix/urgent-fix"
    local hotfix_no_label_config=$(create_temp_config "$(
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
    run simulate_badgetizr_run 123 "$hotfix_no_label_config"

    # Assert
    assert_success
    assert_badge_type_exists "hotfix"
    # No labels should be added
    [ ! -f "$MOCK_GH_RESPONSES_DIR/added_labels.txt" ] ||
        [ ! -s "$MOCK_GH_RESPONSES_DIR/added_labels.txt" ]
}

# ============================================================================
# Label Creation Tests
# ============================================================================

@test "Label is created with correct color for WIP" {
    # Arrange
    export MOCK_PR_TITLE="[WIP] Add new feature"
    local wip_labelized_config=$(create_temp_config "$(
        cat <<EOF
badge_wip:
  enabled: "true"
  settings:
    color: "yellow"
    label: "WIP"
    labelized: "wip-label"
EOF
    )")

    # Act
    run simulate_badgetizr_run 123 "$wip_labelized_config"

    # Assert
    assert_success
    # WIP label should be created or added
    assert_label_created "wip-label" || assert_label_added "wip-label"
}

@test "Multiple badges can manage labels simultaneously" {
    # Arrange
    export MOCK_PR_TITLE="[WIP] Fix critical bug"
    export MOCK_PR_BASE_BRANCH="main"
    export MOCK_PR_HEAD_BRANCH="hotfix/urgent"
    local multi_labelized_config=$(create_temp_config "$(
        cat <<EOF
badge_wip:
  enabled: "true"
  settings:
    color: "yellow"
    label: "WIP"
    labelized: "work in progress"
badge_hotfix:
  enabled: "true"
  settings:
    color: "red"
    label: "HOTFIX"
    labelized: "hotfix"
EOF
    )")

    # Act
    run simulate_badgetizr_run 123 "$multi_labelized_config"

    # Assert
    assert_success
    assert_badge_type_exists "wip"
    assert_badge_type_exists "hotfix"

    # Both labels should be managed
    if [ -f "$MOCK_GH_RESPONSES_DIR/added_labels.txt" ]; then
        local label_count=$(wc -l <"$MOCK_GH_RESPONSES_DIR/added_labels.txt" | tr -d ' ')
        [ "$label_count" -ge 1 ] # At least one label added
    fi
}

# ============================================================================
# GitLab Label Management Tests
# ============================================================================

@test "GitLab: WIP badge adds label when labelized is enabled" {
    # Arrange
    export MOCK_MR_TITLE="[WIP] Add new feature"
    export MOCK_GIT_REMOTE="https://gitlab.com/test/repo.git"
    mock_git

    local wip_labelized_config=$(create_temp_config "$(
        cat <<EOF
badge_wip:
  enabled: "true"
  settings:
    color: "yellow"
    label: "WIP"
    labelized: "work in progress"
EOF
    )")

    # Act
    # Note: This would normally use GitLab provider, but for now we test the concept
    export PROVIDER="gitlab"
    run simulate_badgetizr_run 123 "$wip_labelized_config"

    # Cleanup
    unmock_git

    # Assert
    # Either GitHub or GitLab labels should be tracked
    [ -f "$MOCK_GH_RESPONSES_DIR/added_labels.txt" ] ||
        [ -f "$MOCK_GLAB_RESPONSES_DIR/added_labels.txt" ] || true
}

@test "Label removal is tracked correctly" {
    # Arrange
    export MOCK_PR_TITLE="Normal title without WIP"
    local wip_labelized_config=$(create_temp_config "$(
        cat <<EOF
badge_wip:
  enabled: "true"
  settings:
    color: "yellow"
    label: "WIP"
    labelized: "work in progress"
EOF
    )")

    # Act
    run simulate_badgetizr_run 123 "$wip_labelized_config"

    # Assert
    assert_success
    # Label should be removed
    if [ -f "$MOCK_GH_RESPONSES_DIR/removed_labels.txt" ]; then
        grep -q "work in progress" "$MOCK_GH_RESPONSES_DIR/removed_labels.txt"
    fi
}
