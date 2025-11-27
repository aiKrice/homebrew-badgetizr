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
# url_encode_shields() function tests
# ============================================================================

@test "url_encode_shields function exists" {
    declare -f url_encode_shields > /dev/null
}

@test "url_encode_shields: spaces become %20" {
    result=$(url_encode_shields "hello world")
    [ "$result" = "hello%20world" ]
}

@test "url_encode_shields: underscores are doubled" {
    result=$(url_encode_shields "test_value")
    [ "$result" = "test__value" ]
}

@test "url_encode_shields: dashes are doubled" {
    result=$(url_encode_shields "test-value")
    [ "$result" = "test--value" ]
}

@test "url_encode_shields: multiple underscores are all doubled" {
    result=$(url_encode_shields "a_b_c")
    [ "$result" = "a__b__c" ]
}

@test "url_encode_shields: multiple dashes are all doubled" {
    result=$(url_encode_shields "a-b-c")
    [ "$result" = "a--b--c" ]
}

@test "url_encode_shields: ampersand becomes %26" {
    result=$(url_encode_shields "foo&bar")
    [ "$result" = "foo%26bar" ]
}

@test "url_encode_shields: equals becomes %3D" {
    result=$(url_encode_shields "key=value")
    [ "$result" = "key%3Dvalue" ]
}

@test "url_encode_shields: forward slash becomes %2F" {
    result=$(url_encode_shields "path/to/file")
    [ "$result" = "path%2Fto%2Ffile" ]
}

@test "url_encode_shields: mixed special characters" {
    result=$(url_encode_shields "test-label_with spaces & more")
    [ "$result" = "test--label__with%20spaces%20%26%20more" ]
}

@test "url_encode_shields: empty string" {
    result=$(url_encode_shields "")
    [ "$result" = "" ]
}

@test "url_encode_shields: no special characters" {
    result=$(url_encode_shields "simple")
    [ "$result" = "simple" ]
}

@test "url_encode_shields: alphanumeric preserved" {
    result=$(url_encode_shields "ABC123xyz")
    [ "$result" = "ABC123xyz" ]
}

@test "url_encode_shields: multiple consecutive dashes" {
    result=$(url_encode_shields "test---value")
    [ "$result" = "test------value" ]
}

@test "url_encode_shields: multiple consecutive underscores" {
    result=$(url_encode_shields "test___value")
    [ "$result" = "test______value" ]
}

@test "url_encode_shields: mixed multiple special chars" {
    result=$(url_encode_shields "foo-bar_baz-qux_end")
    [ "$result" = "foo--bar__baz--qux__end" ]
}
