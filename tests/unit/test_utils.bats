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

# ============================================================================
# url_encode() function tests
# ============================================================================

@test "url_encode function exists" {
    declare -f url_encode > /dev/null
}

@test "url_encode: spaces become %20" {
    result=$(url_encode "hello world")
    [ "$result" = "hello%20world" ]
}

@test "url_encode: underscores are doubled" {
    result=$(url_encode "test_value")
    [ "$result" = "test__value" ]
}

@test "url_encode: dashes are doubled" {
    result=$(url_encode "test-value")
    [ "$result" = "test--value" ]
}

@test "url_encode: multiple underscores are all doubled" {
    result=$(url_encode "a_b_c")
    [ "$result" = "a__b__c" ]
}

@test "url_encode: multiple dashes are all doubled" {
    result=$(url_encode "a-b-c")
    [ "$result" = "a--b--c" ]
}

@test "url_encode: ampersand becomes %26" {
    result=$(url_encode "foo&bar")
    [ "$result" = "foo%26bar" ]
}

@test "url_encode: equals becomes %3D" {
    result=$(url_encode "key=value")
    [ "$result" = "key%3Dvalue" ]
}

@test "url_encode: forward slash becomes %2F" {
    result=$(url_encode "path/to/file")
    [ "$result" = "path%2Fto%2Ffile" ]
}

@test "url_encode: mixed special characters" {
    result=$(url_encode "test-label_with spaces & more")
    [ "$result" = "test--label__with%20spaces%20%26%20more" ]
}

@test "url_encode: empty string" {
    result=$(url_encode "")
    [ "$result" = "" ]
}

@test "url_encode: no special characters" {
    result=$(url_encode "simple")
    [ "$result" = "simple" ]
}

@test "url_encode: alphanumeric preserved" {
    result=$(url_encode "ABC123xyz")
    [ "$result" = "ABC123xyz" ]
}
