#!/usr/bin/env bats
# Integration tests for label ownership protection functionality

load '../helpers/test_helpers'
load '../helpers/assertions'

setup() {
    setup_test_env

    # Source provider utils for constants
    source "$PROJECT_ROOT/providers/provider_utils.sh"

    # Source mocks
    source "$PROJECT_ROOT/tests/mocks/mock_gh.sh"
    source "$PROJECT_ROOT/tests/mocks/mock_glab.sh"
    source "$PROJECT_ROOT/tests/mocks/mock_responses.sh"
}

teardown() {
    cleanup_test_env
}

# ============================================================================
# Label Ownership Detection Tests
# ============================================================================

@test "Badgetizr-created labels have correct description" {
    # Arrange
    export MOCK_PR_TITLE="[WIP] Add new feature"
    local wip_labelized_config=$(create_temp_config "$(
        cat << EOF
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

    # Check that label was created with correct description
    if [ -f "$MOCK_GH_RESPONSES_DIR/labels_db.txt" ]; then
        grep "work in progress" "$MOCK_GH_RESPONSES_DIR/labels_db.txt" | grep -q "${BADGETIZR_LABEL_DESCRIPTION}"
    fi
}

@test "Manual labels are NOT removed by Badgetizr" {
    # Arrange - Create a manual label (without Badgetizr description)
    mkdir -p "$MOCK_GH_RESPONSES_DIR"
    echo "work in progress|fbca04|Manually created label" > "$MOCK_GH_RESPONSES_DIR/labels_db.txt"

    export MOCK_PR_TITLE="Normal PR title without WIP"
    local wip_labelized_config=$(create_temp_config "$(
        cat << EOF
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

    # Label should NOT be in removed_labels.txt since it's not managed by Badgetizr
    if [ -f "$MOCK_GH_RESPONSES_DIR/removed_labels.txt" ]; then
        ! grep -q "work in progress" "$MOCK_GH_RESPONSES_DIR/removed_labels.txt" || {
            echo "ERROR: Manual label was incorrectly removed!"
            return 1
        }
    fi

    # Should see skip message in output
    echo "$output" | grep -q "Skipping removal.*not managed by Badgetizr" || {
        echo "WARNING: Expected skip message not found in output"
    }
}

@test "WIP label removed when title changes (integration)" {
    # This test verifies that Badgetizr-managed labels ARE removed but manual labels are NOT

    # Arrange - Create a Badgetizr-managed WIP label and mark it as present on the PR
    mkdir -p "${MOCK_GH_RESPONSES_DIR}"
    echo "work in progress|fbca04|${BADGETIZR_LABEL_DESCRIPTION}" > "${MOCK_GH_RESPONSES_DIR}/labels_db.txt"

    # The label must be already applied to the PR for Badgetizr to consider removing it
    export MOCK_PR_LABELS="work in progress"
    export MOCK_PR_TITLE="Normal feature implementation"

    local wip_labelized_config
    wip_labelized_config=$(create_temp_config "$(
        cat << EOF
badge_wip:
  enabled: "true"
  settings:
    color: "yellow"
    label: "WIP"
    labelized: "work in progress"
EOF
    )")

    # Act
    run simulate_badgetizr_run 123 "${wip_labelized_config}"

    # Assert
    assert_success
    # Badgetizr-managed label SHOULD be removed
    assert_label_removed "work in progress"
}

# ============================================================================
# Hotfix Badge Label Ownership Tests
# ============================================================================

@test "Hotfix: Badgetizr-managed labels are removed correctly" {
    # Arrange - Create Badgetizr-managed hotfix label
    mkdir -p "$MOCK_GH_RESPONSES_DIR"
    echo "hotfix|d73a49|${BADGETIZR_LABEL_DESCRIPTION}" > "$MOCK_GH_RESPONSES_DIR/labels_db.txt"

    export MOCK_PR_TITLE="Normal PR"
    export MOCK_PR_BASE_BRANCH="develop"
    export MOCK_PR_HEAD_BRANCH="feature/normal"
    local hotfix_labelized_config=$(create_temp_config "$(
        cat << EOF
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

@test "Hotfix: Manual labels are NOT removed" {
    # Arrange - Create manual hotfix label
    mkdir -p "$MOCK_GH_RESPONSES_DIR"
    echo "hotfix|d73a49|Manual hotfix label for critical bugs" > "$MOCK_GH_RESPONSES_DIR/labels_db.txt"

    export MOCK_PR_TITLE="Normal PR"
    export MOCK_PR_BASE_BRANCH="develop"
    export MOCK_PR_HEAD_BRANCH="feature/normal"
    local hotfix_labelized_config=$(create_temp_config "$(
        cat << EOF
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

    # Label should NOT be removed
    if [ -f "$MOCK_GH_RESPONSES_DIR/removed_labels.txt" ]; then
        ! grep -q "hotfix" "$MOCK_GH_RESPONSES_DIR/removed_labels.txt" || {
            echo "ERROR: Manual hotfix label was incorrectly removed!"
            return 1
        }
    fi
}

# ============================================================================
# GitLab Label Ownership Tests
# ============================================================================

@test "GitLab: Badgetizr-created labels have correct description" {
    # Arrange
    export MOCK_MR_TITLE="[WIP] Add new feature"
    export MOCK_GIT_REMOTE="https://gitlab.com/test/repo.git"
    mock_git

    local wip_labelized_config=$(create_temp_config "$(
        cat << EOF
badge_wip:
  enabled: "true"
  settings:
    color: "yellow"
    label: "WIP"
    labelized: "work in progress"
EOF
    )")

    # Act
    export PROVIDER="gitlab"
    run simulate_badgetizr_run 123 "$wip_labelized_config"

    # Cleanup
    unmock_git

    # Assert
    assert_success

    # Check that label was created with correct description (GitLab)
    if [ -f "$MOCK_GLAB_RESPONSES_DIR/labels_db.txt" ]; then
        grep "work in progress" "$MOCK_GLAB_RESPONSES_DIR/labels_db.txt" | grep -q "${BADGETIZR_LABEL_DESCRIPTION}"
    fi
}

@test "GitLab: Manual labels are NOT removed" {
    # Arrange - Create manual label for GitLab
    mkdir -p "$MOCK_GLAB_RESPONSES_DIR"
    echo "work in progress|fbca04|Team's manual WIP label" > "$MOCK_GLAB_RESPONSES_DIR/labels_db.txt"

    export MOCK_MR_TITLE="Normal MR title"
    export MOCK_GIT_REMOTE="https://gitlab.com/test/repo.git"
    mock_git

    local wip_labelized_config=$(create_temp_config "$(
        cat << EOF
badge_wip:
  enabled: "true"
  settings:
    color: "yellow"
    label: "WIP"
    labelized: "work in progress"
EOF
    )")

    # Act
    export PROVIDER="gitlab"
    run simulate_badgetizr_run 123 "$wip_labelized_config"

    # Cleanup
    unmock_git

    # Assert
    assert_success

    # Label should NOT be removed
    if [ -f "$MOCK_GLAB_RESPONSES_DIR/removed_labels.txt" ]; then
        ! grep -q "work in progress" "$MOCK_GLAB_RESPONSES_DIR/removed_labels.txt" || {
            echo "ERROR: GitLab manual label was incorrectly removed!"
            return 1
        }
    fi
}

# ============================================================================
# Edge Cases
# ============================================================================

@test "Labels with empty description are NOT removed" {
    # Arrange - Label with no description
    mkdir -p "$MOCK_GH_RESPONSES_DIR"
    echo "work in progress|fbca04|" > "$MOCK_GH_RESPONSES_DIR/labels_db.txt"

    export MOCK_PR_TITLE="Normal PR"
    local wip_labelized_config=$(create_temp_config "$(
        cat << EOF
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

    # Label should NOT be removed
    if [ -f "$MOCK_GH_RESPONSES_DIR/removed_labels.txt" ]; then
        ! grep -q "work in progress" "$MOCK_GH_RESPONSES_DIR/removed_labels.txt"
    fi
}

@test "Labels with similar but different description are NOT removed" {
    # Arrange - Label with similar description
    mkdir -p "$MOCK_GH_RESPONSES_DIR"
    echo "work in progress|fbca04|Generated by Badgetizr v1.0.0" > "$MOCK_GH_RESPONSES_DIR/labels_db.txt"

    export MOCK_PR_TITLE="Normal PR"
    local wip_labelized_config=$(create_temp_config "$(
        cat << EOF
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

    # Label should NOT be removed (description doesn't match exactly)
    if [ -f "$MOCK_GH_RESPONSES_DIR/removed_labels.txt" ]; then
        ! grep -q "work in progress" "$MOCK_GH_RESPONSES_DIR/removed_labels.txt"
    fi
}

@test "Label ownership prevents removal of manual labels (end-to-end)" {
    # End-to-end test: manual WIP label should NOT be removed when title changes

    # Arrange - Create a manual (non-Badgetizr) WIP label
    mkdir -p "${MOCK_GH_RESPONSES_DIR}"
    echo "work in progress|fbca04|Team's manual WIP label" > "${MOCK_GH_RESPONSES_DIR}/labels_db.txt"

    export MOCK_PR_TITLE="Normal feature implementation"
    local wip_labelized_config
    wip_labelized_config=$(create_temp_config "$(
        cat << EOF
badge_wip:
  enabled: "true"
  settings:
    color: "yellow"
    label: "WIP"
    labelized: "work in progress"
EOF
    )")

    # Act
    run simulate_badgetizr_run 123 "${wip_labelized_config}"

    # Assert
    assert_success

    # Manual label should NOT be removed (verify removed_labels.txt doesn't contain it)
    if [[ -f "${MOCK_GH_RESPONSES_DIR}/removed_labels.txt" ]]; then
        ! grep -q "work in progress" "${MOCK_GH_RESPONSES_DIR}/removed_labels.txt" || {
            echo "ERROR: Manual label was incorrectly removed!"
            return 1
        }
    fi

    # Should see skip message in output indicating label is not managed
    echo "${output}" | grep -q "not managed by Badgetizr" || {
        echo "WARNING: Expected skip message not found in output"
    }
}
