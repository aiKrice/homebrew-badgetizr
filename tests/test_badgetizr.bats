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
    run "$BADGETIZR_SCRIPT" 2> /dev/null
    [ "$status" -ne 0 ]
}

@test "badgetizr with invalid option shows error" {
    run "$BADGETIZR_SCRIPT" --invalid-option 2> /dev/null
    [ "$status" -eq 1 ]
}

@test "badgetizr with invalid short option shows error" {
    run "$BADGETIZR_SCRIPT" -x 2> /dev/null
    [ "$status" -eq 1 ]
}

@test "detect_base_path function works in dev mode" {
    # Test that detect_base_path logic works correctly
    # Simulate the function with a real script path
    run bash -c "
        SCRIPT_DIR='${BATS_TEST_DIRNAME}/..'
        if [ -f \"\${SCRIPT_DIR}/utils.sh\" ]; then
            echo \"\${SCRIPT_DIR}\"
        else
            echo \"\${SCRIPT_DIR}/../libexec\"
        fi
    "
    [ "$status" -eq 0 ]
    # Validate that the output is set
    [ -n "$output" ]
    # Since utils.sh exists in project root, output should contain the path
    [[ "$output" =~ homebrew-badgetizr ]]
    # Verify utils.sh actually exists at the returned path
    [ -f "${output}/utils.sh" ]
}
