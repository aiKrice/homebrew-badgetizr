#!/bin/bash
# Custom assertions for badgetizr tests

# Assert that output contains a badge with specific text
assert_badge_contains() {
    local badge_text="$1"
    local output="${2:-${output}}"

    if ! echo "${output}" | grep -q "shields.io.*${badge_text}"; then
        echo "Expected badge with text: ${badge_text}"
        echo "Got output: ${output}"
        return 1
    fi
}

# Assert that output contains badgetizr delimiters
assert_has_badgetizr_delimiters() {
    local output="${1:-${output}}"

    if ! echo "${output}" | grep -q "<!--begin:badgetizr-->"; then
        echo "Missing begin delimiter"
        return 1
    fi

    if ! echo "${output}" | grep -q "<!--end:badgetizr-->"; then
        echo "Missing end delimiter"
        return 1
    fi
}

# Assert that a specific badge type is present
assert_badge_type_exists() {
    local badge_type="$1" # wip, hotfix, ci, ticket, branch
    local output="${2:-${output}}"

    case "${badge_type}" in
        wip)
            assert_badge_contains "WIP" "${output}" || return 1
            ;;
        hotfix)
            assert_badge_contains "HOTFIX" "${output}" || return 1
            ;;
        ci)
            assert_badge_contains "Build" "${output}" || return 1
            ;;
        ticket)
            # Ticket badge should have issue label
            if ! echo "${output}" | grep -q "shields.io.*Issue"; then
                echo "Expected ticket badge with Issue label"
                return 1
            fi
            ;;
        branch)
            # Branch badge should have Target branch or Base Branch label (URL-encoded or not)
            if ! echo "${output}" | grep -qE "shields.io.*(Target.branch|Base.Branch|Target%20branch|Base%20Branch)"; then
                echo "Expected branch badge"
                return 1
            fi
            ;;
        *)
            echo "Unknown badge type: ${badge_type}"
            return 1
            ;;
    esac
}

# Assert that a badge does NOT exist
assert_badge_type_not_exists() {
    local badge_type="$1"
    local output="${2:-${output}}"

    if assert_badge_type_exists "${badge_type}" "${output}" 2> /dev/null; then
        echo "Badge ${badge_type} should not exist but was found"
        return 1
    fi
}

# Assert badge color
assert_badge_has_color() {
    local color="$1"
    local output="${2:-${output}}"

    # Support two formats: -color or color=value
    if ! echo "${output}" | grep -qE "shields.io.*(-${color}|color=${color})"; then
        echo "Expected badge with color: ${color}"
        echo "Got output: ${output}"
        return 1
    fi
}

# Assert PR description was updated
assert_pr_description_updated() {
    local mock_dir="${1:-/tmp/mock_gh_responses}"

    if [[ ! -f "${mock_dir}/pr_body.txt" ]]; then
        echo "PR description was not updated (no pr_body.txt found)"
        return 1
    fi
}

# Assert label was added
assert_label_added() {
    local label_name="$1"
    local mock_dir="${2:-/tmp/mock_gh_responses}"

    if [[ ! -f "${mock_dir}/added_labels.txt" ]]; then
        echo "No labels were added (no added_labels.txt found)"
        return 1
    fi

    if ! grep -q "^${label_name}$" "${mock_dir}/added_labels.txt"; then
        echo "Label '${label_name}' was not added"
        echo "Added labels:"
        cat "${mock_dir}/added_labels.txt"
        return 1
    fi
}

# Assert label was removed
assert_label_removed() {
    local label_name="$1"
    local mock_dir="${2:-/tmp/mock_gh_responses}"

    if [[ ! -f "${mock_dir}/removed_labels.txt" ]]; then
        echo "No labels were removed (no removed_labels.txt found)"
        return 1
    fi

    if ! grep -q "^${label_name}$" "${mock_dir}/removed_labels.txt"; then
        echo "Label '${label_name}' was not removed"
        echo "Removed labels:"
        cat "${mock_dir}/removed_labels.txt"
        return 1
    fi
}

# Assert label was created
assert_label_created() {
    local label_name="$1"
    local mock_dir="${2:-/tmp/mock_gh_responses}"

    if [[ ! -f "${mock_dir}/created_labels.txt" ]]; then
        echo "No labels were created (no created_labels.txt found)"
        return 1
    fi

    if ! grep -q "^${label_name}$" "${mock_dir}/created_labels.txt"; then
        echo "Label '${label_name}' was not created"
        echo "Created labels:"
        cat "${mock_dir}/created_labels.txt"
        return 1
    fi
}

# Assert output matches regex
assert_output_matches() {
    local pattern="$1"
    local output="${2:-${output}}"

    if ! echo "${output}" | grep -qE "${pattern}"; then
        echo "Output does not match pattern: ${pattern}"
        echo "Got output: ${output}"
        return 1
    fi
}

# Assert file contains text
assert_file_contains() {
    local file="$1"
    local text="$2"

    if [[ ! -f "${file}" ]]; then
        echo "File not found: ${file}"
        return 1
    fi

    if ! grep -q "${text}" "${file}"; then
        echo "File ${file} does not contain: ${text}"
        echo "File contents:"
        cat "${file}"
        return 1
    fi
}

# Assert exit code
assert_success() {
    local status="${1:-${status}}"
    if [[ "${status}" -ne 0 ]]; then
        echo "Expected success (exit code 0), got: ${status}"
        return 1
    fi
}

assert_failure() {
    local status="${1:-${status}}"
    if [[ "${status}" -eq 0 ]]; then
        echo "Expected failure (non-zero exit code), got: 0"
        return 1
    fi
}

# Export all assertion functions
export -f assert_badge_contains
export -f assert_has_badgetizr_delimiters
export -f assert_badge_type_exists
export -f assert_badge_type_not_exists
export -f assert_badge_has_color
export -f assert_pr_description_updated
export -f assert_label_added
export -f assert_label_removed
export -f assert_label_created
export -f assert_output_matches
export -f assert_file_contains
export -f assert_success
export -f assert_failure
