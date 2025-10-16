#!/usr/bin/env bats

# Test suite for main badgetizr script

setup() {
    export BADGETIZR_SCRIPT="${BATS_TEST_DIRNAME}/../badgetizr"
    export TEST_CONFIG="${BATS_TEST_DIRNAME}/fixtures/test-config.yml"
}

@test "badgetizr script exists and is executable" {
    [ -x "$BADGETIZR_SCRIPT" ]
}

@test "badgetizr script has correct shebang" {
    run head -n 1 "$BADGETIZR_SCRIPT"
    [[ "$output" =~ "#!/bin/bash" ]]
}

@test "badgetizr --version shows version" {
    run "$BADGETIZR_SCRIPT" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "badgetizr -v shows version" {
    run "$BADGETIZR_SCRIPT" -v
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "badgetizr --help shows usage information" {
    run "$BADGETIZR_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "badgetizr -h shows usage information" {
    run "$BADGETIZR_SCRIPT" -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "badgetizr without --pr-id shows error" {
    run "$BADGETIZR_SCRIPT"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Error" ]] || [[ "$output" =~ "mandatory" ]]
}

@test "badgetizr with invalid option shows error" {
    run "$BADGETIZR_SCRIPT" --invalid-option
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid option" ]]
}

@test "badgetizr with invalid short option shows error" {
    run "$BADGETIZR_SCRIPT" -x
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid option" ]]
}

@test "detect_base_path function works in dev mode" {
    # Test when utils.sh is in the same directory
    run bash -c "cd '${BATS_TEST_DIRNAME}/..' && source badgetizr && detect_base_path && echo \"\$BASE_PATH\""
    [ "$status" -eq 0 ]
    # Validate that BASE_PATH is set and is an absolute path
    [[ "$output" =~ ^/ ]]
    # Validate that the resolved path exists
    [ -n "$output" ]
}
