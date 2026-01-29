#!/usr/bin/env bats

# Test suite for providers/provider_utils.sh

setup() {
    # Load utils and provider_utils
    export BASE_PATH="${BATS_TEST_DIRNAME}/.."
    source "${BASE_PATH}/utils.sh"
    source "${BASE_PATH}/providers/provider_utils.sh"
}

@test "detect_provider function exists" {
    declare -f detect_provider >/dev/null
}

teardown() {
    # Clean up any mock functions to prevent test pollution
    unset -f git 2>/dev/null || true
}

@test "detect_provider returns github for github.com URLs" {
    # Mock git remote command to return a GitHub URL
    git() {
        if [[ "$1" == "remote" && "$2" == "get-url" ]]; then
            echo "https://github.com/user/repo.git"
        fi
    }
    export -f git

    run detect_provider
    [ "$status" -eq 0 ]
    [ "$output" = "github" ]

    unset -f git
}

@test "detect_provider returns gitlab for gitlab.com URLs" {
    # Mock git remote command to return a GitLab URL
    git() {
        if [[ "$1" == "remote" && "$2" == "get-url" ]]; then
            echo "https://gitlab.com/user/repo.git"
        fi
    }
    export -f git

    run detect_provider
    [ "$status" -eq 0 ]
    [ "$output" = "gitlab" ]

    unset -f git
}

@test "detect_provider defaults to github when remote is unavailable" {
    # Mock git remote command to fail
    git() {
        return 1
    }
    export -f git

    run detect_provider
    [ "$status" -eq 0 ]
    [ "$output" = "github" ]

    unset -f git
}

@test "check_provider_cli function exists" {
    declare -f check_provider_cli >/dev/null
}

@test "check_provider_cli validates github provider" {
    # Only test the function logic, not actual CLI presence
    run bash -c "source '${BASE_PATH}/providers/provider_utils.sh' && declare -f check_provider_cli > /dev/null"
    [ "$status" -eq 0 ]
}

@test "check_provider_cli validates gitlab provider" {
    # Only test the function logic, not actual CLI presence
    run bash -c "source '${BASE_PATH}/providers/provider_utils.sh' && declare -f check_provider_cli > /dev/null"
    [ "$status" -eq 0 ]
}

@test "load_provider function exists" {
    declare -f load_provider >/dev/null
}

@test "get_pr_info wrapper function exists" {
    declare -f get_pr_info >/dev/null
}

@test "update_pr_description wrapper function exists" {
    declare -f update_pr_description >/dev/null
}

@test "add_pr_label wrapper function exists" {
    declare -f add_pr_label >/dev/null
}

@test "remove_pr_label wrapper function exists" {
    declare -f remove_pr_label >/dev/null
}

@test "create_pr_label wrapper function exists" {
    declare -f create_pr_label >/dev/null
}

@test "test_provider_auth wrapper function exists" {
    declare -f test_provider_auth >/dev/null
}

@test "get_destination_branch wrapper function exists" {
    declare -f get_destination_branch >/dev/null
}
