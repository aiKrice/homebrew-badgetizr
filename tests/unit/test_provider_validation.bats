#!/usr/bin/env bats

# Test suite for provider validation and error handling

setup() {
    export PROJECT_ROOT="${BATS_TEST_DIRNAME}/../.."

    # Load test helpers for assertions
    load '../helpers/test_helpers'

    source "$PROJECT_ROOT/providers/provider_utils.sh"
}

@test "load_provider fails with clear error for invalid provider" {
    # Act
    run load_provider "nonexistent"

    # Assert
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Provider nonexistent not found" ]]
}

@test "check_provider_cli fails when gh is not available" {
    # Arrange - Mock command to simulate gh not found
    run bash -c '
        command() {
            if [[ "$2" == "gh" ]]; then
                return 1  # gh not found
            else
                builtin command "$@"
            fi
        }
        export -f command
        source "'"$PROJECT_ROOT"'/providers/provider_utils.sh"
        check_provider_cli "github"
    '

    # Assert
    [ "$status" -eq 1 ]
    [[ "$output" =~ "GitHub CLI (gh) is not installed" ]] || [[ "$output" =~ "Error" ]]
}

@test "check_provider_cli fails when glab is not available" {
    # Arrange - Mock command to simulate glab not found
    run bash -c '
        command() {
            if [[ "$2" == "glab" ]]; then
                return 1  # glab not found
            else
                builtin command "$@"
            fi
        }
        export -f command
        source "'"$PROJECT_ROOT"'/providers/provider_utils.sh"
        check_provider_cli "gitlab"
    '

    # Assert
    [ "$status" -eq 1 ]
    [[ "$output" =~ "GitLab CLI (glab) is not installed" ]] || [[ "$output" =~ "Error" ]]
}

@test "check_provider_cli succeeds when gh is available" {
    # This test assumes gh is installed on the system or mocked in tests
    # If gh is in PATH, check should succeed
    if command -v gh &> /dev/null; then
        run check_provider_cli "github"
        [ "$status" -eq 0 ]
    else
        skip "gh not available in PATH"
    fi
}

@test "check_provider_cli succeeds when glab is available" {
    # This test assumes glab is installed on the system or mocked in tests
    # If glab is in PATH, check should succeed
    if command -v glab &> /dev/null; then
        run check_provider_cli "gitlab"
        [ "$status" -eq 0 ]
    else
        skip "glab not available in PATH"
    fi
}
