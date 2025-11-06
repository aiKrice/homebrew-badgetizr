#!/bin/bash
# Mock GitHub CLI (gh) for testing
# Usage: Source this file to override gh commands

# Mock responses storage
export MOCK_GH_RESPONSES_DIR="${MOCK_GH_RESPONSES_DIR:-/tmp/mock_gh_responses}"
mkdir -p "$MOCK_GH_RESPONSES_DIR"

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
gh() {
    local subcommand="$1"
    shift

    case "$subcommand" in
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
            echo "mock_gh: Unknown command: $subcommand" >&2
            return 1
            ;;
    esac
}

gh_pr() {
    local action="$1"
    shift

    case "$action" in
        view)
            gh_pr_view "$@"
            ;;
        edit)
            gh_pr_edit "$@"
            ;;
        *)
            echo "mock_gh pr: Unknown action: $action" >&2
            return 1
            ;;
    esac
}

gh_pr_view() {
    # Parse arguments
    local pr_number=""
    local field=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                field="$2"
                shift 2
                ;;
            -q|--jq)
                # Just pass through for now
                shift 2
                ;;
            *)
                pr_number="$1"
                shift
                ;;
        esac
    done

    # Return mock data based on field
    # Note: When used with --jq, we return raw values without quotes
    # (jq would normally strip quotes from JSON strings)
    case "$field" in
        title)
            echo "$MOCK_PR_TITLE"
            ;;
        body)
            echo "$MOCK_PR_BODY"
            ;;
        baseRefName)
            echo "$MOCK_PR_BASE_BRANCH"
            ;;
        headRefName)
            echo "$MOCK_PR_HEAD_BRANCH"
            ;;
        state)
            echo "$MOCK_PR_STATE"
            ;;
        labels)
            if [ -n "$MOCK_PR_LABELS" ]; then
                echo "[{\"name\": \"$MOCK_PR_LABELS\"}]"
            else
                echo "[]"
            fi
            ;;
        *)
            # Default: return all fields
            cat <<JSON
{
  "title": "$MOCK_PR_TITLE",
  "body": "$MOCK_PR_BODY",
  "baseRefName": "$MOCK_PR_BASE_BRANCH",
  "headRefName": "$MOCK_PR_HEAD_BRANCH",
  "state": "$MOCK_PR_STATE",
  "labels": []
}
JSON
            ;;
    esac
}

gh_pr_edit() {
    local pr_number=""
    local new_body=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --body|-b)
                new_body="$2"
                shift 2
                ;;
            --add-label)
                # Track label additions
                echo "$2" >> "$MOCK_GH_RESPONSES_DIR/added_labels.txt"
                shift 2
                ;;
            --remove-label)
                # Track label removals
                echo "$2" >> "$MOCK_GH_RESPONSES_DIR/removed_labels.txt"
                shift 2
                ;;
            *)
                pr_number="$1"
                shift
                ;;
        esac
    done

    # Update mock PR body if provided
    if [ -n "$new_body" ]; then
        MOCK_PR_BODY="$new_body"
        echo "$new_body" > "$MOCK_GH_RESPONSES_DIR/pr_body.txt"
    fi

    return 0
}

gh_auth() {
    local action="$1"
    shift

    case "$action" in
        status)
            if [ "$MOCK_AUTH_SUCCESS" = "true" ]; then
                echo "Logged in to github.com as testuser"
                return 0
            else
                echo "Not logged in" >&2
                return 1
            fi
            ;;
        *)
            echo "mock_gh auth: Unknown action: $action" >&2
            return 1
            ;;
    esac
}

gh_label() {
    local action="$1"
    shift

    case "$action" in
        create)
            # Mock label creation
            local label_name=""
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --name|-n)
                        label_name="$2"
                        shift 2
                        ;;
                    *)
                        shift
                        ;;
                esac
            done
            echo "$label_name" >> "$MOCK_GH_RESPONSES_DIR/created_labels.txt"
            return 0
            ;;
        list)
            # Return empty list for now
            echo "[]"
            return 0
            ;;
        *)
            echo "mock_gh label: Unknown action: $action" >&2
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
    rm -rf "$MOCK_GH_RESPONSES_DIR"
}

export -f mock_gh_cleanup
