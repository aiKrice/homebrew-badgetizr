#!/usr/bin/env bats

# Test suite for utils.sh

setup() {
    # Load the utils.sh file
    source "${BATS_TEST_DIRNAME}/../../utils.sh"
}

@test "BADGETIZR_VERSION is defined" {
    [ -n "$BADGETIZR_VERSION" ]
}

@test "BADGETIZR_VERSION follows semantic versioning pattern" {
    [[ "$BADGETIZR_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "show_help function exists" {
    declare -f show_help > /dev/null
}

@test "show_help outputs usage information" {
    run show_help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "--pr-id" ]]
}

@test "show_help mentions configuration option" {
    run show_help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--configuration" ]]
}

@test "show_help mentions version option" {
    run show_help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--version" ]]
}

@test "show_help mentions help option" {
    run show_help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--help" ]]
}
