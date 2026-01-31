#!/bin/bash
# Mock GitHub CLI (gh) for testing
# Usage: Source this file to override gh commands

# Mock responses storage
export MOCK_GH_RESPONSES_DIR="${MOCK_GH_RESPONSES_DIR:-/tmp/mock_gh_responses}"
mkdir -p "${MOCK_GH_RESPONSES_DIR}"

# Mock PR info
MOCK_PR_TITLE="${MOCK_PR_TITLE:-Test PR Title}"
MOCK_PR_BODY="${MOCK_PR_BODY:-Test PR body content}"
MOCK_PR_BASE_BRANCH="${MOCK_PR_BASE_BRANCH:-main}"
MOCK_PR_HEAD_BRANCH="${MOCK_PR_HEAD_BRANCH:-feature/test}"
MOCK_PR_STATE="${MOCK_PR_STATE:-open}"

# Mock labels
MOCK_PR_LABELS="${MOCK_PR_LABELS:-}"

# Mock auth status
MOCK_AUTH_SUCCESS="${MOCK_AUTH_SUCCESS:-true}"

# Mock gh command
# NOTE: This intentionally overrides the system 'gh' command when sourced.
# This is the desired behavior for testing - it allows us to intercept all
# gh CLI calls made by the code under test without making real API requests.
gh() {
    local subcommand="$1"
    shift

    case "${subcommand}" in
        pr)
            gh_pr "$@"
            ;;
        auth)
            gh_auth "$@"
            ;;
        label)
            gh_label "$@"
            ;;
        *)
            echo "mock_gh: Unknown command: ${subcommand}" >&2
            return 1
            ;;
    esac
}

gh_pr() {
    local action="$1"
    shift

    case "${action}" in
        view)
            gh_pr_view "$@"
            ;;
        edit)
            gh_pr_edit "$@"
            ;;
        *)
            echo "mock_gh pr: Unknown action: ${action}" >&2
            return 1
            ;;
    esac
}

gh_pr_view() {
    # Parse arguments
    local _pr_number=""
    local field=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                field="$2"
                shift 2
                ;;
            -q | --jq)
                # Just pass through for now
                shift 2
                ;;
            *)
                _pr_number="$1"
                shift
                ;;
        esac
    done

    # Return mock data based on field
    # Note: When used with --jq, we return raw values without quotes
    # (jq would normally strip quotes from JSON strings)
    case "${field}" in
        title)
            echo "${MOCK_PR_TITLE}"
            ;;
        body)
            echo "${MOCK_PR_BODY}"
            ;;
        title,body)
            # Support combined title,body request (for optimization)
            cat << JSON
{
  "title": "${MOCK_PR_TITLE}",
  "body": "${MOCK_PR_BODY}"
}
JSON
            ;;
        baseRefName)
            echo "${MOCK_PR_BASE_BRANCH}"
            ;;
        headRefName)
            echo "${MOCK_PR_HEAD_BRANCH}"
            ;;
        state)
            echo "${MOCK_PR_STATE}"
            ;;
        labels)
            if [[ -n "${MOCK_PR_LABELS}" ]]; then
                echo "[{\"name\": \"${MOCK_PR_LABELS}\"}]"
            else
                echo "[]"
            fi
            ;;
        *)
            # Default: return all fields
            cat << JSON
{
  "title": "${MOCK_PR_TITLE}",
  "body": "${MOCK_PR_BODY}",
  "baseRefName": "${MOCK_PR_BASE_BRANCH}",
  "headRefName": "${MOCK_PR_HEAD_BRANCH}",
  "state": "${MOCK_PR_STATE}",
  "labels": []
}
JSON
            ;;
    esac
}

gh_pr_edit() {
    local _pr_number=""
    local new_body=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --body | -b)
                new_body="$2"
                shift 2
                ;;
            --add-label)
                # Check if label exists in labels_db before allowing add
                local label_to_add="$2"
                if [[ ! -f "${MOCK_GH_RESPONSES_DIR}/labels_db.txt" ]] ||
                    ! grep -q "^${label_to_add}|" "${MOCK_GH_RESPONSES_DIR}/labels_db.txt"; then
                    # Label doesn't exist or db doesn't exist, fail the add operation
                    return 1
                fi
                # Track label additions
                echo "$2" >> "${MOCK_GH_RESPONSES_DIR}/added_labels.txt"
                shift 2
                ;;
            --remove-label)
                # Track label removals (unless simulating failure)
                # shellcheck disable=SC2154  # MOCK_LABEL_REMOVAL_FAILS set by test environment
                if [[ "${MOCK_LABEL_REMOVAL_FAILS}" == "true" ]]; then
                    # Simulate label not present on PR
                    return 1
                fi
                echo "$2" >> "${MOCK_GH_RESPONSES_DIR}/removed_labels.txt"
                shift 2
                ;;
            *)
                _pr_number="$1"
                shift
                ;;
        esac
    done

    # Update mock PR body if provided
    if [[ -n "${new_body}" ]]; then
        MOCK_PR_BODY="${new_body}"
        echo "${new_body}" > "${MOCK_GH_RESPONSES_DIR}/pr_body.txt"
    fi

    return 0
}

gh_auth() {
    local action="$1"
    shift

    case "${action}" in
        status)
            if [[ "${MOCK_AUTH_SUCCESS}" = "true" ]]; then
                echo "Logged in to github.com as testuser"
                return 0
            else
                echo "Not logged in" >&2
                return 1
            fi
            ;;
        *)
            echo "mock_gh auth: Unknown action: ${action}" >&2
            return 1
            ;;
    esac
}

gh_label() {
    local action="$1"
    shift

    case "${action}" in
        create)
            # Mock label creation - first positional arg is the label name
            local label_name="$1"
            local color=""
            local description=""
            shift

            # Parse remaining options
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --name | -n)
                        label_name="$2"
                        shift 2
                        ;;
                    --color | -c)
                        color="$2"
                        shift 2
                        ;;
                    --description | -d)
                        description="$2"
                        shift 2
                        ;;
                    *)
                        shift
                        ;;
                esac
            done

            if [[ -n "${label_name}" ]]; then
                echo "${label_name}" >> "${MOCK_GH_RESPONSES_DIR}/created_labels.txt"
                # Store label with description for list command
                echo "${label_name}|${color:-fbca04}|${description}" >> "${MOCK_GH_RESPONSES_DIR}/labels_db.txt"
            fi
            return 0
            ;;
        list)
            # Parse arguments
            local _json_fields=""
            local jq_filter=""

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --json)
                        _json_fields="$2"
                        shift 2
                        ;;
                    --jq | -q)
                        jq_filter="$2"
                        shift 2
                        ;;
                    *)
                        shift
                        ;;
                esac
            done

            # Build JSON array from labels database
            local labels_json="["
            local first=true

            if [[ -f "${MOCK_GH_RESPONSES_DIR}/labels_db.txt" ]]; then
                while IFS='|' read -r name color description; do
                    if [[ "${first}" = true ]]; then
                        first=false
                    else
                        labels_json+=","
                    fi
                    # Escape quotes in description
                    description="${description//\"/\\\"}"
                    labels_json+="{\"name\":\"${name}\",\"color\":\"${color}\",\"description\":\"${description}\"}"
                done < "${MOCK_GH_RESPONSES_DIR}/labels_db.txt"
            fi

            labels_json+="]"

            # If --jq is used, we need to apply the filter (simulate gh CLI behavior)
            if [[ -n "${jq_filter}" ]]; then
                # For testing, we'll use yq to apply jq-style filters
                echo "${labels_json}" | yq -r "${jq_filter}" 2> /dev/null || echo ""
            else
                echo "${labels_json}"
            fi
            return 0
            ;;
        *)
            echo "mock_gh label: Unknown action: ${action}" >&2
            return 1
            ;;
    esac
}

# Export function so it's available in subshells
export -f gh
export -f gh_pr
export -f gh_pr_view
export -f gh_pr_edit
export -f gh_auth
export -f gh_label

# Cleanup function
mock_gh_cleanup() {
    rm -rf "${MOCK_GH_RESPONSES_DIR}"
}

export -f mock_gh_cleanup
