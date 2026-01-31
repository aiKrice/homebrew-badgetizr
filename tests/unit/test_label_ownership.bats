#!/usr/bin/env bats
# Unit tests for label ownership detection functions

load '../helpers/test_helpers'
load '../helpers/assertions'

setup() {
    setup_test_env

    # Source the provider system
    source "$PROJECT_ROOT/providers/provider_utils.sh"

    # Source mocks
    source "$PROJECT_ROOT/tests/mocks/mock_gh.sh"
    source "$PROJECT_ROOT/tests/mocks/mock_glab.sh"
}

teardown() {
    cleanup_test_env
}

# ============================================================================
# GitHub Provider: is_label_managed() Tests
# ============================================================================

@test "GitHub: is_label_managed returns true for Badgetizr-managed labels" {
    # Arrange
    mkdir -p "$MOCK_GH_RESPONSES_DIR"
    echo "test-label|fbca04|${BADGETIZR_LABEL_DESCRIPTION}" > "$MOCK_GH_RESPONSES_DIR/labels_db.txt"

    # Load GitHub provider
    export DETECTED_PROVIDER="github"
    source "$PROJECT_ROOT/providers/github.sh"

    # Act & Assert
    run is_label_managed "test-label"
    assert_success
}

@test "GitHub: is_label_managed returns false for manual labels" {
    # Arrange
    mkdir -p "$MOCK_GH_RESPONSES_DIR"
    echo "test-label|fbca04|Manually created by team" > "$MOCK_GH_RESPONSES_DIR/labels_db.txt"

    # Load GitHub provider
    export DETECTED_PROVIDER="github"
    source "$PROJECT_ROOT/providers/github.sh"

    # Act & Assert
    run is_label_managed "test-label"
    assert_failure
}

@test "GitHub: is_label_managed returns false for labels with empty description" {
    # Arrange
    mkdir -p "$MOCK_GH_RESPONSES_DIR"
    echo "test-label|fbca04|" > "$MOCK_GH_RESPONSES_DIR/labels_db.txt"

    # Load GitHub provider
    export DETECTED_PROVIDER="github"
    source "$PROJECT_ROOT/providers/github.sh"

    # Act & Assert
    run is_label_managed "test-label"
    assert_failure
}

@test "GitHub: is_label_managed returns false for non-existent labels" {
    # Arrange
    mkdir -p "$MOCK_GH_RESPONSES_DIR"
    # Empty labels database

    # Load GitHub provider
    export DETECTED_PROVIDER="github"
    source "$PROJECT_ROOT/providers/github.sh"

    # Act & Assert
    run is_label_managed "non-existent-label"
    assert_failure
}

@test "GitHub: is_label_managed handles labels with special characters" {
    # Arrange
    mkdir -p "$MOCK_GH_RESPONSES_DIR"
    echo "work in progress|fbca04|${BADGETIZR_LABEL_DESCRIPTION}" > "$MOCK_GH_RESPONSES_DIR/labels_db.txt"

    # Load GitHub provider
    export DETECTED_PROVIDER="github"
    source "$PROJECT_ROOT/providers/github.sh"

    # Act & Assert
    run is_label_managed "work in progress"
    assert_success
}

# ============================================================================
# GitLab Provider: is_label_managed() Tests
# ============================================================================

@test "GitLab: is_label_managed returns true for Badgetizr-managed labels" {
    # Arrange
    mkdir -p "$MOCK_GLAB_RESPONSES_DIR"
    echo "test-label|fbca04|${BADGETIZR_LABEL_DESCRIPTION}" > "$MOCK_GLAB_RESPONSES_DIR/labels_db.txt"

    # Load GitLab provider
    export DETECTED_PROVIDER="gitlab"
    export CI_PROJECT_PATH="test/repo"
    source "$PROJECT_ROOT/providers/gitlab.sh"

    # Act & Assert
    run is_label_managed "test-label"
    assert_success
}

@test "GitLab: is_label_managed returns false for manual labels" {
    # Arrange
    mkdir -p "$MOCK_GLAB_RESPONSES_DIR"
    echo "test-label|fbca04|Manually created by team" > "$MOCK_GLAB_RESPONSES_DIR/labels_db.txt"

    # Load GitLab provider
    export DETECTED_PROVIDER="gitlab"
    export CI_PROJECT_PATH="test/repo"
    source "$PROJECT_ROOT/providers/gitlab.sh"

    # Act & Assert
    run is_label_managed "test-label"
    assert_failure
}

@test "GitLab: is_label_managed returns false for labels with empty description" {
    # Arrange
    mkdir -p "$MOCK_GLAB_RESPONSES_DIR"
    echo "test-label|fbca04|" > "$MOCK_GLAB_RESPONSES_DIR/labels_db.txt"

    # Load GitLab provider
    export DETECTED_PROVIDER="gitlab"
    export CI_PROJECT_PATH="test/repo"
    source "$PROJECT_ROOT/providers/gitlab.sh"

    # Act & Assert
    run is_label_managed "test-label"
    assert_failure
}

# ============================================================================
# Provider Utils: remove_pr_label() Protection Tests
# ============================================================================

@test "remove_pr_label skips removal for manual labels" {
    # Arrange
    mkdir -p "$MOCK_GH_RESPONSES_DIR"
    echo "manual-label|fbca04|Team's manual label" > "$MOCK_GH_RESPONSES_DIR/labels_db.txt"

    export DETECTED_PROVIDER="github"
    source "$PROJECT_ROOT/providers/github.sh"

    # Act
    run remove_pr_label "123" "manual-label"

    # Assert
    assert_success

    # Label should NOT be in removed list
    if [ -f "$MOCK_GH_RESPONSES_DIR/removed_labels.txt" ]; then
        ! grep -q "manual-label" "$MOCK_GH_RESPONSES_DIR/removed_labels.txt"
    fi

    # Should see skip message
    echo "$output" | grep -q "Skipping removal.*not managed by Badgetizr"
}

@test "remove_pr_label removes Badgetizr-managed labels" {
    # Arrange
    mkdir -p "$MOCK_GH_RESPONSES_DIR"
    echo "badgetizr-label|fbca04|${BADGETIZR_LABEL_DESCRIPTION}" > "$MOCK_GH_RESPONSES_DIR/labels_db.txt"

    export DETECTED_PROVIDER="github"
    source "$PROJECT_ROOT/providers/github.sh"

    # Act
    run remove_pr_label "123" "badgetizr-label"

    # Assert
    assert_success

    # Label SHOULD be in removed list
    assert_label_removed "badgetizr-label"
}

# ============================================================================
# Description Matching Tests
# ============================================================================

@test "Exact description match is required" {
    # Arrange - Slightly different descriptions
    mkdir -p "$MOCK_GH_RESPONSES_DIR"

    # Test variations that should NOT match
    echo "label1|fbca04|Generated by Badgetizr" > "$MOCK_GH_RESPONSES_DIR/labels_db.txt"
    echo "label2|fbca04|${BADGETIZR_LABEL_DESCRIPTION} manually" >> "$MOCK_GH_RESPONSES_DIR/labels_db.txt"
    echo "label3|fbca04|Auto-generated by Badgetizr - do not edit" >> "$MOCK_GH_RESPONSES_DIR/labels_db.txt"

    # Only this one should match
    echo "label4|fbca04|${BADGETIZR_LABEL_DESCRIPTION}" >> "$MOCK_GH_RESPONSES_DIR/labels_db.txt"

    export DETECTED_PROVIDER="github"
    source "$PROJECT_ROOT/providers/github.sh"

    # Act & Assert
    run is_label_managed "label1"
    assert_failure

    run is_label_managed "label2"
    assert_failure

    run is_label_managed "label3"
    assert_failure

    run is_label_managed "label4"
    assert_success
}

@test "Description matching is case-sensitive" {
    # Arrange
    mkdir -p "$MOCK_GH_RESPONSES_DIR"
    echo "test-label|fbca04|generated by badgetizr - do not edit" > "$MOCK_GH_RESPONSES_DIR/labels_db.txt"

    export DETECTED_PROVIDER="github"
    source "$PROJECT_ROOT/providers/github.sh"

    # Act & Assert - Should fail because case doesn't match
    run is_label_managed "test-label"
    assert_failure
}

@test "Description with extra whitespace does not match" {
    # Arrange
    mkdir -p "$MOCK_GH_RESPONSES_DIR"
    echo "test-label|fbca04|Generated by Badgetizr  -  do not edit" > "$MOCK_GH_RESPONSES_DIR/labels_db.txt"

    export DETECTED_PROVIDER="github"
    source "$PROJECT_ROOT/providers/github.sh"

    # Act & Assert - Should fail because whitespace doesn't match exactly
    run is_label_managed "test-label"
    assert_failure
}

# ============================================================================
# Label Removal Edge Cases
# ============================================================================

@test "GitHub: Removing non-existent label shows info message" {
    # Arrange - Label is managed but removal fails (not present on PR)
    mkdir -p "$MOCK_GH_RESPONSES_DIR"
    echo "test-label|fbca04|${BADGETIZR_LABEL_DESCRIPTION}" > "$MOCK_GH_RESPONSES_DIR/labels_db.txt"

    export DETECTED_PROVIDER="github"
    source "$PROJECT_ROOT/providers/github.sh"

    # Mock gh to fail label removal (label not on PR)
    export MOCK_LABEL_REMOVAL_FAILS="true"

    # Act - This should trigger the "else" path in provider_remove_pr_label
    run provider_remove_pr_label "123" "test-label"

    # Assert - Should succeed even if label wasn't on PR
    assert_success
    [[ "$output" == *"was not present on this PR"* ]] || [[ "$output" == *"removed successfully"* ]]
}

@test "GitLab: Removing non-existent label shows info message" {
    # Arrange - Label is managed but removal fails (not present on MR)
    mkdir -p "$MOCK_GLAB_RESPONSES_DIR"
    echo "test-label|fbca04|${BADGETIZR_LABEL_DESCRIPTION}" > "$MOCK_GLAB_RESPONSES_DIR/labels_db.txt"

    export DETECTED_PROVIDER="gitlab"
    export CI_PROJECT_PATH="test/repo"
    source "$PROJECT_ROOT/providers/gitlab.sh"

    # Mock glab to fail label removal (label not on MR)
    export MOCK_LABEL_REMOVAL_FAILS="true"

    # Act - This should trigger the "else" path in provider_remove_pr_label
    run provider_remove_pr_label "123" "test-label"

    # Assert - Should succeed even if label wasn't on MR
    assert_success
    [[ "$output" == *"was not present on this MR"* ]] || [[ "$output" == *"removed successfully"* ]]
}

# ============================================================================
# Label Creation with Different Description Tests
# ============================================================================

@test "GitHub: create_pr_label with existing label (different description)" {
    # Arrange - Label exists with different description
    mkdir -p "$MOCK_GH_RESPONSES_DIR"
    echo "test-label|fbca04|Team's manual label" > "$MOCK_GH_RESPONSES_DIR/labels_db.txt"

    export DETECTED_PROVIDER="github"
    source "$PROJECT_ROOT/providers/github.sh"

    # Act - Try to create label with Badgetizr description
    run provider_create_pr_label "test-label" "fbca04" "${BADGETIZR_LABEL_DESCRIPTION}"

    # Assert
    assert_success

    # Should see warning message about different description
    echo "$output" | grep -q "exists but with different description"
    echo "$output" | grep -q "Team's manual label"
    echo "$output" | grep -q "Using existing label to avoid conflicts"

    # Label should NOT be recreated
    if [ -f "$MOCK_GH_RESPONSES_DIR/created_labels.txt" ]; then
        ! grep -q "test-label" "$MOCK_GH_RESPONSES_DIR/created_labels.txt"
    fi
}

@test "GitLab: create_pr_label with existing label (different description)" {
    # Arrange - Label exists with different description
    mkdir -p "$MOCK_GLAB_RESPONSES_DIR"
    echo "test-label|fbca04|Team's manual GitLab label" > "$MOCK_GLAB_RESPONSES_DIR/labels_db.txt"

    export DETECTED_PROVIDER="gitlab"
    export CI_PROJECT_PATH="test/repo"
    source "$PROJECT_ROOT/providers/gitlab.sh"

    # Act - Try to create label with Badgetizr description
    run provider_create_pr_label "test-label" "fbca04" "${BADGETIZR_LABEL_DESCRIPTION}"

    # Assert
    assert_success

    # Should see warning message about different description
    echo "$output" | grep -q "exists but with different description"
    echo "$output" | grep -q "Team's manual GitLab label"
    echo "$output" | grep -q "Using existing label to avoid conflicts"

    # Label should NOT be recreated
    if [ -f "$MOCK_GLAB_RESPONSES_DIR/created_labels.txt" ]; then
        ! grep -q "test-label" "$MOCK_GLAB_RESPONSES_DIR/created_labels.txt"
    fi
}
