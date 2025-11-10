#!/usr/bin/env bats

# Test suite for provider validation and error handling

setup() {
    export PROJECT_ROOT="${BATS_TEST_DIRNAME}/../.."

    # Load test helpers for assertions
    load '../helpers/test_helpers'

    # Setup test environment (creates temp dirs, etc)
    setup_test_env

    source "$PROJECT_ROOT/providers/provider_utils.sh"
}

teardown() {
    cleanup_test_env
}

@test "load_provider fails with clear error for invalid provider" {
    # Act
    run load_provider "nonexistent"

    # Assert
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Provider nonexistent not found" ]]
}

@test "check_provider_cli fails when gh is not available" {
    # Arrange - Use a subshell where gh command doesn't exist
    # We unset any existing gh function and ensure command -v fails
    run bash -c '
        # Unset any mocked gh function
        unset -f gh 2>/dev/null || true
        # Create empty PATH to ensure gh is not found
        PATH=""
        source "'"$PROJECT_ROOT"'/providers/provider_utils.sh"
        check_provider_cli "github"
    '

    # Assert
    [ "$status" -eq 1 ]
    [[ "$output" =~ "GitHub CLI (gh) is not installed" ]]
}

@test "check_provider_cli fails when glab is not available" {
    # Arrange - Use a subshell where glab command doesn't exist
    run bash -c '
        # Unset any mocked glab function
        unset -f glab 2>/dev/null || true
        # Create empty PATH to ensure glab is not found
        PATH=""
        source "'"$PROJECT_ROOT"'/providers/provider_utils.sh"
        check_provider_cli "gitlab"
    '

    # Assert
    [ "$status" -eq 1 ]
    [[ "$output" =~ "GitLab CLI (glab) is not installed" ]]
}

@test "check_provider_cli succeeds when gh is available" {
    # Arrange - Use existing mock infrastructure
    source "$PROJECT_ROOT/tests/mocks/mock_gh.sh"

    # Act
    run check_provider_cli "github"

    # Assert
    [ "$status" -eq 0 ]
}

@test "check_provider_cli succeeds when glab is available" {
    # Arrange - Use existing mock infrastructure
    source "$PROJECT_ROOT/tests/mocks/mock_glab.sh"

    # Act
    run check_provider_cli "gitlab"

    # Assert
    [ "$status" -eq 0 ]
}
