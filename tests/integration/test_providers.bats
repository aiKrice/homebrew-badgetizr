#!/usr/bin/env bats
# Integration tests for provider functionality (GitHub and GitLab)

load '../helpers/test_helpers'
load '../helpers/assertions'

setup() {
    setup_test_env

    # Source provider utils and mocks
    source "$PROJECT_ROOT/providers/provider_utils.sh"
    source "$PROJECT_ROOT/tests/mocks/mock_gh.sh"
    source "$PROJECT_ROOT/tests/mocks/mock_glab.sh"
    source "$PROJECT_ROOT/tests/mocks/mock_responses.sh"
}

teardown() {
    cleanup_test_env
}

# ============================================================================
# GitHub Provider Tests
# ============================================================================

@test "GitHub provider: detect_provider identifies GitHub repository" {
    # Arrange
    export MOCK_GIT_REMOTE="https://github.com/test/repo.git"
    mock_git

    # Act
    local provider=$(detect_provider)

    # Assert
    [ "$provider" = "github" ]

    # Cleanup
    unmock_git
}

@test "GitHub provider: get_pr_info retrieves PR title" {
    # Arrange
    setup_wip_pr
    source "$PROJECT_ROOT/providers/github.sh"

    # Act
    local title=$(provider_get_pr_info 123 "title")

    # Assert
    [ "$title" = "[WIP] Add new feature" ]
}

@test "GitHub provider: get_pr_info retrieves PR body" {
    # Arrange
    setup_wip_pr
    source "$PROJECT_ROOT/providers/github.sh"

    # Act
    local body=$(provider_get_pr_info 123 "body")

    # Assert
    [ "$body" = "This is a work in progress PR" ]
}

@test "GitHub provider: get_destination_branch retrieves base branch" {
    # Arrange
    export MOCK_PR_BASE_BRANCH="develop"
    source "$PROJECT_ROOT/providers/github.sh"

    # Act
    local branch=$(provider_get_destination_branch 123)

    # Assert
    [ "$branch" = "develop" ]
}

@test "GitHub provider: test_auth succeeds with valid authentication" {
    # Arrange
    export MOCK_AUTH_SUCCESS="true"
    source "$PROJECT_ROOT/providers/github.sh"

    # Act
    run provider_test_auth

    # Assert
    assert_success
}

@test "GitHub provider: test_auth fails with invalid authentication" {
    # Arrange
    export MOCK_AUTH_SUCCESS="false"
    source "$PROJECT_ROOT/providers/github.sh"

    # Act
    run provider_test_auth

    # Assert
    [ "$status" -eq 1 ]
}

@test "GitHub provider: update_pr_description updates PR body" {
    # Arrange
    setup_wip_pr
    source "$PROJECT_ROOT/providers/github.sh"
    local new_body="Updated PR description with badges"

    # Act
    provider_update_pr_description 123 "$new_body"

    # Assert
    [ -f "$MOCK_GH_RESPONSES_DIR/pr_body.txt" ]
    grep -q "Updated PR description" "$MOCK_GH_RESPONSES_DIR/pr_body.txt"
}

@test "GitHub provider: add_pr_label adds label to PR" {
    # Arrange
    source "$PROJECT_ROOT/providers/github.sh"

    # Act
    provider_add_pr_label 123 "wip"

    # Assert
    [ -f "$MOCK_GH_RESPONSES_DIR/added_labels.txt" ]
    grep -q "^wip$" "$MOCK_GH_RESPONSES_DIR/added_labels.txt"
}

@test "GitHub provider: remove_pr_label removes label from PR" {
    # Arrange
    source "$PROJECT_ROOT/providers/github.sh"

    # Act
    provider_remove_pr_label 123 "wip"

    # Assert
    [ -f "$MOCK_GH_RESPONSES_DIR/removed_labels.txt" ]
    grep -q "^wip$" "$MOCK_GH_RESPONSES_DIR/removed_labels.txt"
}

@test "GitHub provider: create_pr_label creates new label" {
    # Arrange
    source "$PROJECT_ROOT/providers/github.sh"

    # Act
    provider_create_pr_label "test-label" "ff0000" "Test label description"

    # Assert
    [ -f "$MOCK_GH_RESPONSES_DIR/created_labels.txt" ]
    grep -q "test-label" "$MOCK_GH_RESPONSES_DIR/created_labels.txt"
}

# ============================================================================
# GitLab Provider Tests
# ============================================================================

@test "GitLab provider: detect_provider identifies GitLab repository" {
    # Arrange
    export MOCK_GIT_REMOTE="https://gitlab.com/test/repo.git"
    mock_git

    # Act
    local provider=$(detect_provider)

    # Assert
    [ "$provider" = "gitlab" ]

    # Cleanup
    unmock_git
}

@test "GitLab provider: detect_provider identifies self-managed GitLab" {
    # Arrange
    export MOCK_GIT_REMOTE="https://gitlab.company.com/test/repo.git"
    mock_git

    # Act
    local provider=$(detect_provider)

    # Assert
    [ "$provider" = "gitlab" ]

    # Cleanup
    unmock_git
}

@test "GitLab provider: get_pr_info retrieves MR title" {
    # Arrange
    export MOCK_MR_TITLE="Add new feature"
    source "$PROJECT_ROOT/providers/gitlab.sh"

    # Act
    local title=$(provider_get_pr_info 123 "title")

    # Assert
    [ "$title" = "Add new feature" ]
}

@test "GitLab provider: get_pr_info retrieves MR description" {
    # Arrange
    export MOCK_MR_DESCRIPTION="Test MR description"
    source "$PROJECT_ROOT/providers/gitlab.sh"

    # Act
    local body=$(provider_get_pr_info 123 "body")

    # Assert
    [ "$body" = "Test MR description" ]
}

@test "GitLab provider: get_destination_branch retrieves target branch" {
    # Arrange
    export MOCK_MR_TARGET_BRANCH="main"
    source "$PROJECT_ROOT/providers/gitlab.sh"

    # Act
    local branch=$(provider_get_destination_branch 123)

    # Assert
    [ "$branch" = "main" ]
}

@test "GitLab provider: test_auth succeeds with valid authentication" {
    # Arrange
    export MOCK_GLAB_AUTH_SUCCESS="true"
    source "$PROJECT_ROOT/providers/gitlab.sh"

    # Act
    run provider_test_auth

    # Assert
    assert_success
}

@test "GitLab provider: test_auth works with environment variable" {
    # Arrange
    export GITLAB_TOKEN="test-token"
    export MOCK_GLAB_AUTH_SUCCESS="true"
    source "$PROJECT_ROOT/providers/gitlab.sh"

    # Act
    # Note: This will call curl which may fail, but we're testing the variable detection
    run provider_test_auth

    # Assert
    # Should at least detect the token variable (exit code may vary due to curl)
    [[ "$output" =~ "GITLAB_TOKEN" ]] || [[ "$output" =~ "GitLab" ]]
}

@test "GitLab provider: update_pr_description updates MR description" {
    # Arrange
    export MOCK_MR_TITLE="Test MR"
    source "$PROJECT_ROOT/providers/gitlab.sh"
    local new_body="Updated MR description with badges"

    # Act
    provider_update_pr_description 123 "$new_body"

    # Assert
    [ -f "$MOCK_GLAB_RESPONSES_DIR/mr_description.txt" ]
    grep -q "Updated MR description" "$MOCK_GLAB_RESPONSES_DIR/mr_description.txt"
}

@test "GitLab provider: add_pr_label adds label to MR" {
    # Arrange
    source "$PROJECT_ROOT/providers/gitlab.sh"

    # Pre-create the label so it exists in the mock
    provider_create_pr_label "wip" "yellow" "Work in progress"

    # Act
    provider_add_pr_label 123 "wip"

    # Assert
    [ -f "$MOCK_GLAB_RESPONSES_DIR/added_labels.txt" ]
    grep -q "^wip$" "$MOCK_GLAB_RESPONSES_DIR/added_labels.txt"
}

@test "GitLab provider: remove_pr_label removes label from MR" {
    # Arrange
    source "$PROJECT_ROOT/providers/gitlab.sh"

    # Act
    provider_remove_pr_label 123 "wip"

    # Assert
    [ -f "$MOCK_GLAB_RESPONSES_DIR/removed_labels.txt" ]
    grep -q "^wip$" "$MOCK_GLAB_RESPONSES_DIR/removed_labels.txt"
}

@test "GitLab provider: create_pr_label creates new label" {
    # Arrange
    source "$PROJECT_ROOT/providers/gitlab.sh"

    # Act
    provider_create_pr_label "test-label" "ff0000" "Test label description"

    # Assert
    [ -f "$MOCK_GLAB_RESPONSES_DIR/created_labels.txt" ]
    grep -q "test-label" "$MOCK_GLAB_RESPONSES_DIR/created_labels.txt"
}

# ============================================================================
# Provider Detection Tests
# ============================================================================

@test "detect_provider defaults to github for unsupported remote URL" {
    # Arrange
    export MOCK_GIT_REMOTE="https://bitbucket.org/test/repo.git"
    mock_git

    # Act
    local provider=$(detect_provider)

    # Assert
    # Should fallback to github for unknown providers
    [ "$provider" = "github" ]

    # Cleanup
    unmock_git
}

@test "detect_provider handles SSH GitHub URLs" {
    # Arrange
    export MOCK_GIT_REMOTE="git@github.com:test/repo.git"
    mock_git

    # Act
    local provider=$(detect_provider)

    # Assert
    [ "$provider" = "github" ]

    # Cleanup
    unmock_git
}

@test "detect_provider handles SSH GitLab URLs" {
    # Arrange
    export MOCK_GIT_REMOTE="git@gitlab.com:test/repo.git"
    mock_git

    # Act
    local provider=$(detect_provider)

    # Assert
    [ "$provider" = "gitlab" ]

    # Cleanup
    unmock_git
}
